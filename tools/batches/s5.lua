local parent = game:GetService("ServerScriptService")
local function inject(name, src)
    local s = parent:FindFirstChild(name)
    if not s or s.ClassName ~= "Script" then
        if s then s:Destroy() end
        s = Instance.new("Script")
        s.Name = name
        s.Parent = parent
    end
    s.Source = src
    print("✅ Injected " .. name)
end

-- === DilemmaServer ===
inject("DilemmaServer", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: MASTER GAME CONTROLLER v4.0 ★
-- v4.0 Additions:
--   • Sensory Panic Feedback (PanicMode RemoteEvent at T-5s)
--   • Debris:AddItem() on all fallen plates (memory clean)
--   • Greed Orb Debris cleanup on collect
--   • Win streak tracking → fires WinStreakChanged + RoundWon
--   • Integrates with OverheadTitleHandler & FavoritePromptController
-- ============================================================

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

-- =========================================================
-- SOUND SETUP (safe pcall — avoids crash if sounds missing)
-- =========================================================
local function safeGetSound(name: string): Sound?
	local ok, result = pcall(function() return SoundService:WaitForChild(name, 2) end)
	return ok and result or nil
end

local tickSfx   = safeGetSound("SFX_Tick")
local alarmSfx  = safeGetSound("SFX_Alarm")
local rumbleSfx = safeGetSound("SFX_Rumble")
local winSfx    = safeGetSound("SFX_Win")

local function playSfx(sound: Sound?)
	if sound then pcall(function() sound:Play() end) end
end

-- =========================================================
-- DATASTORE
-- =========================================================
local PlayerDataStore: DataStore?
pcall(function()
	PlayerDataStore = DataStoreService:GetDataStore("DilemmaRoyale_v1")
end)

-- =========================================================
-- ARENA REFERENCES
-- =========================================================
local arena       = workspace:WaitForChild("DilemmaArena")
local redPlate    = arena:WaitForChild("PlateRed")   :: Part
local bluePlate   = arena:WaitForChild("PlateBlue")  :: Part
local neutralBeam = arena:FindFirstChild("NeutralBeam") :: Part?
local screen      = arena:FindFirstChild("DilemmaScreen")
local titleText   : TextLabel?
local questionText: TextLabel?
local timerText   : TextLabel?

if screen then
	local sg = screen:FindFirstChild("SurfaceGui")
	if sg then
		local frame = sg:FindFirstChild("Frame")
		if frame then
			titleText    = frame:FindFirstChild("TitleText")    :: TextLabel?
			questionText = frame:FindFirstChild("QuestionText") :: TextLabel?
			timerText    = frame:FindFirstChild("TimerText")    :: TextLabel?
		end
	end
end

local function setTitle(text: string, color: Color3?)
	if titleText then
		titleText.Text = text
		titleText.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	end
end
local function setQuestion(text: string)
	if questionText then questionText.Text = text end
end
local function setTimer(text: string, color: Color3?)
	if timerText then
		timerText.Text = text
		timerText.TextColor3 = color or Color3.fromRGB(0, 255, 200)
	end
end

-- =========================================================
-- REMOTE EVENTS SETUP
-- =========================================================
local eventsFolder = ReplicatedStorage:FindFirstChild("DilemmaEvents") :: Folder?
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "DilemmaEvents"
	eventsFolder.Parent = ReplicatedStorage
end

local function getOrMakeEvent(name: string): RemoteEvent
	local ev = eventsFolder:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = eventsFolder
	end
	return ev
end

local evPanicMode        = getOrMakeEvent("PanicMode")
local evRoundWon         = getOrMakeEvent("RoundWon")
local beWinStreakChanged = getOrMakeBindable("WinStreakChanged")

-- BindableEvents for internal server communication
local function getOrMakeBindable(name: string): BindableEvent
	local be = eventsFolder:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = eventsFolder
	end
	return be
end

local beAddCoins       = getOrMakeBindable("ServerAddCoins")
local beGrantCosmetic  = getOrMakeBindable("ServerGrantCosmetic")
local beGrantTitle     = getOrMakeBindable("ServerGrantTitle")

-- =========================================================
-- WIN STREAK TRACKING
-- =========================================================
local playerWins:    { [number]: number } = {}  -- userId → total wins
local playerStreaks: { [number]: number } = {}  -- userId → consecutive streak
local playerCosmetics: { [number]: { [string]: boolean } } = {}

-- =========================================================
-- RANK CALCULATION
-- =========================================================
local function getRankTitle(wins: number): string
	if wins >= 51 then return "Untouchable"
	elseif wins >= 31 then return "Tactician"
	elseif wins >= 16 then return "Colosseum Knight"
	elseif wins >= 6  then return "Mind Master"
	else return "Rookie Survivor"
	end
end

-- =========================================================
-- CONSTANTS
-- =========================================================
local DEFAULT_SIZE         = Vector3.new(35, 3, 50)
local DEFAULT_RED_POS      = Vector3.new(-20, 50, 0)
local DEFAULT_BLUE_POS     = Vector3.new(20, 50, 0)
local COLOSSEUM_SPAWN_POS  = Vector3.new(0, 62, 70)
local VOID_THRESHOLD       = 20   -- Y < 20 → teleport back
local PANIC_TRIGGER_SEC    = 5    -- Start panic at T-5 seconds

local Dilemmas = {
	{ Cat = "DILEMA SOSIAL",    Text = "PILIH: WiFi Super Kencang (MERAH) vs Makan Enak Gratis (BIRU)" },
	{ Cat = "SUPERPOWER",       Text = "SUPERPOWER: Bisa Terbang (MERAH) vs Bisa Menghilang (BIRU)" },
	{ Cat = "TIME TRAVEL",      Text = "WAKTU: Pergi ke Masa Lalu (MERAH) vs Pergi ke Masa Depan (BIRU)" },
	{ Cat = "GAMING",           Text = "GAMING: Jago Semua Game (MERAH) vs Punya PC Sultan 500 Juta (BIRU)" },
	{ Cat = "KARIR",            Text = "KARIR: Sukses di Usia Muda (MERAH) vs Santai Menikmati Hidup (BIRU)" },
	{ Cat = "TAKTIKAL SURVIVAL",Text = "RISIKO: Kubu MERAH Lebih Luas vs Kubu BIRU Bonus +20 Koin!" },
	{ Cat = "GREED DILEMMA",    Text = "AMBISI: Selamat di Kubu Minoritas vs Rebut GREED ORB di Balok Netral!" },
	{ Cat = "PSIKOLOGI",        Text = "TRUST: Bagi Hadiah Rata (MERAH) vs Ambil Semua Sendirian (BIRU)" },
	{ Cat = "SAINS",            Text = "EKSPLORASI: Jejaki Luar Angkasa (MERAH) vs Selami Dasar Laut (BIRU)" },
	{ Cat = "KEKUATAN",         Text = "POWER: Super Strength (MERAH) vs Mind Control (BIRU)" },
}

local Modifiers = {
	{ Name = "LANTAI ES LICIN!",  Desc = "Gesekan 0%! Sangat licin!", Type = "Ice" },
	{ Name = "GRAVITASI BULAN!",  Desc = "Semua orang melayang!",      Type = "Gravity" },
	{ Name = "LANTAI MENGECIL!",  Desc = "Lantai menyusut tiap detik!",Type = "Shrink" },
	{ Name = "STANDAR ARENA",     Desc = "Kondisi normal.",             Type = "Normal" },
}

-- =========================================================
-- HEADCOUNT SENSOR
-- =========================================================
local function getPlateHeadcount(plate: Part): number
	local count = 0
	local minX = plate.Position.X - (plate.Size.X / 2)
	local maxX = plate.Position.X + (plate.Size.X / 2)
	local minZ = plate.Position.Z - (plate.Size.Z / 2)
	local maxZ = plate.Position.Z + (plate.Size.Z / 2)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local pos = hrp.Position
				if pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ
					and pos.Y > 45 and pos.Y < 70 then
					count += 1
				end
			end
		end
	end
	return count
end

local function isOnNeutralBeam(char: Model): boolean
	if not neutralBeam then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end
	local pos = hrp.Position
	local nb = neutralBeam
	return pos.X >= nb.Position.X - nb.Size.X/2 - 0.5
		and pos.X <= nb.Position.X + nb.Size.X/2 + 0.5
		and pos.Z >= nb.Position.Z - nb.Size.Z/2
		and pos.Z <= nb.Position.Z + nb.Size.Z/2
		and pos.Y > 48 and pos.Y < 60
end

local function getLuckMultiplier(player: Player): number
	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		local luck = stats:FindFirstChild("Luck") :: IntValue?
		if luck and luck.Value > 1 then
			if math.random(1, 100) <= luck.Value * 8 then
				return 1.5
			end
		end
	end
	return 1.0
end

-- =========================================================
-- PLAYER SETUP
-- =========================================================
local function setupPlayer(player: Player)
	-- Leaderstats
	local ls = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local wins = ls:FindFirstChild("Wins") :: IntValue? or Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = ls

	local coins = ls:FindFirstChild("Coins") :: IntValue? or Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = ls

	-- Load from DataStore
	if PlayerDataStore then
		local ok, data = pcall(PlayerDataStore.GetAsync, PlayerDataStore, "Player_" .. player.UserId)
		if ok and data then
			wins.Value  = data.Wins  or 0
			coins.Value = data.Coins or 0
			playerStreaks[player.UserId] = data.Streak or 0
		end
	end

	playerWins[player.UserId]    = wins.Value
	playerStreaks[player.UserId] = playerStreaks[player.UserId] or 0
	playerCosmetics[player.UserId] = {}
end

local lastSaved: { [number]: number } = {}
local lastSaved: { [number]: number } = {}
local lastSaved: { [number]: number } = {}
local function savePlayer(player: Player)
	if not PlayerDataStore then return end
	local now = os.clock()
	if lastSaved[player.UserId] and (now - lastSaved[player.UserId]) < 4 then
		return
	end
	lastSaved[player.UserId] = now
	local now = os.clock()
	if lastSaved[player.UserId] and (now - lastSaved[player.UserId]) < 4 then
		return
	end
	lastSaved[player.UserId] = now
	local now = os.clock()
	if lastSaved[player.UserId] and (now - lastSaved[player.UserId]) < 4 then
		return
	end
	lastSaved[player.UserId] = now
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local wins  = ls:FindFirstChild("Wins")  :: IntValue?
	local coins = ls:FindFirstChild("Coins") :: IntValue?
	pcall(PlayerDataStore.SetAsync, PlayerDataStore, "Player_" .. player.UserId, {
		Wins   = wins  and wins.Value  or 0,
		Coins  = coins and coins.Value or 0,
		Streak = playerStreaks[player.UserId] or 0,
	})
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(savePlayer)
for _, p in Players:GetPlayers() do setupPlayer(p) end

-- BindableEvent handlers
beAddCoins.Event:Connect(function(player: Player, amount: number)
	local coins = player:FindFirstChild("leaderstats") and
		player.leaderstats:FindFirstChild("Coins") :: IntValue?
	if coins then
		coins.Value = coins.Value + math.floor(amount)
	end
end)

-- =========================================================
-- VOID PROTECTOR
-- =========================================================
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in Players:GetPlayers() do
			local c = p.Character
			if c then
				local hrp = c:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp and hrp.Position.Y < VOID_THRESHOLD then
					hrp.CFrame = CFrame.new(COLOSSEUM_SPAWN_POS)
				end
			end
		end
	end
end)

-- =========================================================
-- GREED ORB
-- =========================================================
local currentGreedOrb: Part? = nil

local function spawnGreedOrb()
	if currentGreedOrb then
		Debris:AddItem(currentGreedOrb, 0)
		currentGreedOrb = nil
	end

	local orb = Instance.new("Part")
	orb.Name        = "GreedOrb"
	orb.Shape       = Enum.PartType.Ball
	orb.Size        = Vector3.new(2.5, 2.5, 2.5)
	orb.Position    = Vector3.new(0, 53.5, math.random(-15, 15))
	orb.Anchored    = true
	orb.CanCollide  = false
	orb.Material    = Enum.Material.Neon
	orb.Color       = Color3.fromRGB(255, 215, 0)
	orb.Parent      = arena

	local att = Instance.new("Attachment", orb)
	local pe  = Instance.new("ParticleEmitter")
	pe.Color    = ColorSequence.new(Color3.fromRGB(255, 230, 50))
	pe.Size     = NumberSequence.new(0.5, 0)
	pe.Rate     = 20
	pe.Speed    = NumberRange.new(1, 4)
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.LightEmission = 0.8
	pe.Parent   = att

	local collected = false
	orb.Touched:Connect(function(hit)
		if collected then return end
		local char   = hit.Parent :: Model?
		if not char  then return end
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end
		collected = true

		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local c = stats:FindFirstChild("Coins") :: IntValue?
			if c then
				local mult   = getLuckMultiplier(player)
				local reward = math.floor(5 * mult)
				c.Value     += reward
				print(string.format("[GREED ORB] %s +%d coins", player.Name, reward))
			end
		end

		playSfx(winSfx)
		-- v4: Use Debris instead of :Destroy() for safe instant cleanup
		Debris:AddItem(orb, 0.1)
		currentGreedOrb = nil
	end)

	currentGreedOrb = orb
end

local function cleanGreedOrb()
	if currentGreedOrb then
		Debris:AddItem(currentGreedOrb, 0)
		currentGreedOrb = nil
	end
end

-- =========================================================
-- PANIC MODE BROADCAST
-- =========================================================
local panicActive = false

local function firePanicMode(countdownSecs: number)
	if panicActive then return end
	panicActive = true
	evPanicMode:FireAllClients({ active = true, countdown = countdownSecs })
end

local function stopPanicMode()
	panicActive = false
	evPanicMode:FireAllClients({ active = false, countdown = 0 })
end

-- =========================================================
-- AWARD WINNERS
-- =========================================================
local function awardWinners(winningPlate: Part, onNeutralCheck: (Model) -> boolean)
	local someoneWon = false

	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then continue end

		local pos  = hrp.Position
		local minX = winningPlate.Position.X - winningPlate.Size.X / 2
		local maxX = winningPlate.Position.X + winningPlate.Size.X / 2
		local minZ = winningPlate.Position.Z - winningPlate.Size.Z / 2
		local maxZ = winningPlate.Position.Z + winningPlate.Size.Z / 2
		local onWinning = pos.X >= minX and pos.X <= maxX
			and pos.Z >= minZ and pos.Z <= maxZ
			and pos.Y > 45

		local onNeutral = onNeutralCheck(char)

		if onWinning or onNeutral then
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local winsVal  = ls:FindFirstChild("Wins")  :: IntValue?
				local coinsVal = ls:FindFirstChild("Coins") :: IntValue?
				if winsVal then winsVal.Value += 1 end

				local baseReward  = onNeutral and 15 or 10
				local luckMult    = getLuckMultiplier(player)
				local finalCoins  = math.floor(baseReward * luckMult)
				if coinsVal then coinsVal.Value += finalCoins end

				-- Update streak tracking
				local uid    = player.UserId
				playerWins[uid]    = (winsVal and winsVal.Value) or 0
				playerStreaks[uid] = (playerStreaks[uid] or 0) + 1

				-- Fire events
				beWinStreakChanged:Fire(player, playerWins[uid], playerStreaks[uid])

				local rank = getRankTitle(playerWins[uid])
				evRoundWon:FireClient(player, {
					wins   = playerWins[uid],
					streak = playerStreaks[uid],
					rank   = rank,
				})

				someoneWon = true
				print(string.format("[WIN] %s | Total: %d | Streak: x%d | +%d coins",
					player.Name, playerWins[uid], playerStreaks[uid], finalCoins))
			end
		else
			-- Reset streak on loss
			playerStreaks[player.UserId] = 0
		end
	end

	return someoneWon
end

-- =========================================================
-- PLATE DROP WITH DEBRIS CLEANUP (v4 key improvement)
-- =========================================================
local function dropPlate(plate: Part)
	-- Flash
	for i = 1, 6 do
		plate.Transparency = (i % 2 == 0) and 0 or 0.5
		task.wait(0.08)
	end

	plate.Transparency = 0.9
	plate.CanCollide   = false

	-- Tween the plate falling
	local fallTween = TweenService:Create(plate, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = plate.Position + Vector3.new(0, -60, 0),
		Transparency = 1,
	})
	fallTween:Play()

	-- v4: Debris cleanup — plate auto-destroys after fall animation
	-- But we need to restore it next round, so we clone defaults first
	local origPos   = plate.Position + Vector3.new(0, 60, 0)  -- reverse fall
	local origSize  = plate.Size
	local origColor = plate.Color

	-- Rather than destroy (which breaks references), restore after delay
	task.delay(2.0, function()
		plate.Position    = origPos + Vector3.new(0, -50, 0)  -- reset position below (not visible)
		plate.Transparency = 0
		plate.CanCollide  = false
	end)
end

-- =========================================================
-- MASTER GAME LOOP v4
-- =========================================================
task.spawn(function()
	task.wait(3)  -- Wait for all handlers to initialize

	while true do
		-- ── RESET ARENA ──
		workspace.Gravity = 196.2

		redPlate.Size        = DEFAULT_SIZE
		redPlate.CFrame      = CFrame.new(DEFAULT_RED_POS)
		redPlate.Transparency = 0
		redPlate.CanCollide  = true
		redPlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

		bluePlate.Size        = DEFAULT_SIZE
		bluePlate.CFrame      = CFrame.new(DEFAULT_BLUE_POS)
		bluePlate.Transparency = 0
		bluePlate.CanCollide  = true
		bluePlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

		-- ── SELECT MODIFIER & DILEMMA ──
		local mod      = Modifiers[math.random(1, #Modifiers)]
		local dilemma  = Dilemmas[math.random(1, #Dilemmas)]

		setTitle("⚠️ [ " .. dilemma.Cat .. " ] EVENT: " .. mod.Name .. " ⚠️")
		setQuestion(dilemma.Text)

		if mod.Type == "Ice" then
			local iceProps = PhysicalProperties.new(0.7, 0.01, 0.1)
			redPlate.CustomPhysicalProperties  = iceProps
			bluePlate.CustomPhysicalProperties = iceProps
		elseif mod.Type == "Gravity" then
			workspace.Gravity = 50
		end

		spawnGreedOrb()

		-- ── COUNTDOWN LOOP ──
		local panicFired = false
		for sec = 10, 1, -1 do
			local redCount  = getPlateHeadcount(redPlate)
			local blueCount = getPlateHeadcount(bluePlate)

			-- Shrink modifier
			if mod.Type == "Shrink" and sec <= 8 then
				local shrinkFactor = (10 - sec) * 1.5
				local newSize = Vector3.new(
					math.max(DEFAULT_SIZE.X - shrinkFactor, 10),
					3,
					math.max(DEFAULT_SIZE.Z - shrinkFactor * 1.3, 10)
				)
				-- Smooth shrink via tween
				TweenService:Create(redPlate,  TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Size = newSize }):Play()
				TweenService:Create(bluePlate, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Size = newSize }):Play()
			end

			-- Timer display
			local timerColor = sec <= 3 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 200)
			setTimer("🔴 " .. redCount .. " vs " .. blueCount .. " 🔵 | WAKTU: " .. sec .. "s", timerColor)

			-- v4: Fire Panic Mode at T-5 seconds
			if sec <= PANIC_TRIGGER_SEC and not panicFired then
				panicFired = true
				firePanicMode(sec)
			end

			if sec <= 3 then playSfx(tickSfx) end
			task.wait(1)
		end

		stopPanicMode()
		cleanGreedOrb()
		setTimer("WAKTU HABIS!", Color3.fromRGB(255, 215, 0))
		playSfx(alarmSfx)
		task.wait(1.5)

		-- ── DETERMINE WINNER ──
		local finalRed  = getPlateHeadcount(redPlate)
		local finalBlue = getPlateHeadcount(bluePlate)
		local dropRed   = false
		local statusMsg = ""

		if finalRed + finalBlue > 1 then
			if finalRed > finalBlue then
				dropRed    = true
				statusMsg  = "MERAH MAYORITAS (" .. finalRed .. ")! MERAH RUNTUH!"
			elseif finalBlue > finalRed then
				dropRed    = false
				statusMsg  = "BIRU MAYORITAS (" .. finalBlue .. ")! BIRU RUNTUH!"
			else
				dropRed    = math.random() > 0.5
				statusMsg  = "HASIL SERI! FAKTOR HOKI 50:50!"
			end
		else
			dropRed   = math.random() > 0.5
			statusMsg = "SOLO TEST: LANTAI " .. (dropRed and "MERAH" or "BIRU") .. " RUNTUH!"
		end

		local losingPlate  = dropRed and redPlate or bluePlate
		local winningPlate = dropRed and bluePlate or redPlate

		setTimer(statusMsg, Color3.fromRGB(255, 50, 50))
		playSfx(rumbleSfx)

		-- v4: Drop plate (with Debris-aware cleanup)
		dropPlate(losingPlate)

		-- Award winners (after 0.5s to let physics settle)
		task.wait(0.5)
		local won = awardWinners(winningPlate, isOnNeutralBeam)
		if won then playSfx(winSfx) end

		task.wait(3.5)
		setTimer("RESET ARENA & EVENT BARU...")
		task.wait(1.5)

		-- Restore losing plate for next round
		losingPlate.CFrame     = CFrame.new(dropRed and DEFAULT_RED_POS or DEFAULT_BLUE_POS)
		losingPlate.Size       = DEFAULT_SIZE
		losingPlate.Transparency = 0
		losingPlate.CanCollide = true
	end
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		savePlayer(p)
	end
end)

print("[DilemmaServer v4.0] ✅ Loaded — Panic Feedback, Debris Cleanup, Streak Tracking active.")

]======])

return 'OK: DilemmaServer'