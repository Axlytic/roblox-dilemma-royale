--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: MASTER GAME CONTROLLER v3.0 ★
-- Termasuk: Event Modifiers, Headcount Sensor, Neutral Beam,
-- Greed Orb Spawner, Colosseum Respawn, Integrasi Stat Luck, & DataStore
-- ============================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local tickSfx = SoundService:WaitForChild("SFX_Tick")
local alarmSfx = SoundService:WaitForChild("SFX_Alarm")
local rumbleSfx = SoundService:WaitForChild("SFX_Rumble")
local winSfx = SoundService:WaitForChild("SFX_Win")

-- DataStore Setup dengan Safe Pcall
local PlayerDataStore
local successStore, errStore = pcall(function()
    return DataStoreService:GetDataStore("DilemmaRoyale_v1")
end)
if successStore then PlayerDataStore = errStore end

local arena = workspace:WaitForChild("DilemmaArena")
local redPlate = arena:WaitForChild("PlateRed")
local bluePlate = arena:WaitForChild("PlateBlue")
local neutralBeam = arena:WaitForChild("NeutralBeam")
local screen = arena:WaitForChild("DilemmaScreen")
local frame = screen:WaitForChild("SurfaceGui"):WaitForChild("Frame")
local titleText = frame:WaitForChild("TitleText")
local questionText = frame:WaitForChild("QuestionText")
local timerText = frame:WaitForChild("TimerText")

local DEFAULT_SIZE = Vector3.new(35, 3, 50)
local DEFAULT_RED_POS = Vector3.new(-20, 50, 0)
local DEFAULT_BLUE_POS = Vector3.new(20, 50, 0)
local COLOSSEUM_SPAWN_POS = Vector3.new(0, 62, 70)

local Dilemmas = {
    {Cat = "DILEMA SOSIAL", Text = "PILIH: WiFi Super Kencang (MERAH) vs Makan Enak Gratis (BIRU)"},
    {Cat = "SUPERPOWER", Text = "SUPERPOWER: Bisa Terbang (MERAH) vs Bisa Menghilang (BIRU)"},
    {Cat = "TIME TRAVEL", Text = "WAKTU: Pergi ke Masa Lalu (MERAH) vs Pergi ke Masa Depan (BIRU)"},
    {Cat = "GAMING", Text = "GAMING: Jago Semua Game (MERAH) vs Punya PC Sultan 500 Juta (BIRU)"},
    {Cat = "KARIR", Text = "KARIR: Sukses di Usia Muda (MERAH) vs Santai Menikmati Hidup (BIRU)"},
    {Cat = "TAKTIKAL SURVIVAL", Text = "RISIKO: Kubu MERAH Lebih Luas vs Kubu BIRU Bonus +20 Koin!"},
    {Cat = "GREED DILEMMA", Text = "AMBISI: Selamat di Kubu Minoritas vs Rebut GREED ORB di Balok Netral!"}
}

local Modifiers = {
    {Name = "LANTAI ES LICIN!", Desc = "Gesekan 0%! Sangat licin dan sulit mengerem!", Type = "Ice"},
    {Name = "GRAVITASI BULAN!", Desc = "Semua orang melompat tinggi dan melayang pelan!", Type = "Gravity"},
    {Name = "LANTAI MENGECIL!", Desc = "Lantai menyusut setiap detik! Hati-hati terdesak!", Type = "Shrink"},
    {Name = "STANDAR ARENA", Desc = "Kondisi normal tanpa gangguan fisik.", Type = "Normal"}
}

-- 1. SENSOR HITUNG KEPALA (HEADCOUNT)
local function getPlateHeadcount(plate: Part): number
    local count = 0
    local minX = plate.Position.X - (plate.Size.X / 2)
    local maxX = plate.Position.X + (plate.Size.X / 2)
    local minZ = plate.Position.Z - (plate.Size.Z / 2)
    local maxZ = plate.Position.Z + (plate.Size.Z / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = (char:FindFirstChild("HumanoidRootPart") :: BasePart).Position
            if pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ and pos.Y > 45 and pos.Y < 70 then
                count = count + 1
            end
        end
    end
    return count
end

-- Deteksi apakah pemain berada di atas Neutral Beam
local function isPlayerOnNeutralBeam(char: Model): boolean
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp or not neutralBeam then return false end
    local pos = hrp.Position
    local minX = neutralBeam.Position.X - (neutralBeam.Size.X / 2) - 0.5
    local maxX = neutralBeam.Position.X + (neutralBeam.Size.X / 2) + 0.5
    local minZ = neutralBeam.Position.Z - (neutralBeam.Size.Z / 2)
    local maxZ = neutralBeam.Position.Z + (neutralBeam.Size.Z / 2)
    return pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ and pos.Y > 48 and pos.Y < 60
end

local function getPlayerLuckMultiplier(player: Player): number
    local stats = player:FindFirstChild("PlayerStats")
    if stats then
        local luckObj = stats:FindFirstChild("Luck") :: IntValue?
        if luckObj and luckObj.Value > 1 then
            -- Setiap level luck memberi 5% peluang bonus koin
            local roll = math.random(1, 100)
            if roll <= (luckObj.Value * 8) then
                return 1.5 -- 50% Bonus koin keberuntungan!
            end
        end
    end
    return 1.0
end

-- 2. SETUP OVERHEAD TITLE STATUS SOSIAL
local function attachOverhead(char: Model, player: Player, winsVal: number)
    local head = char:WaitForChild("Head", 5) :: BasePart?
    if not head or head:FindFirstChild("Overhead") then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "Overhead"
    bb.Size = UDim2.new(0, 180, 0, 45)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0.5, 0)
    t.BackgroundTransparency = 1
    t.Text = player.DisplayName
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.TextScaled = true
    t.Font = Enum.Font.GothamBold
    t.Parent = bb

    local r = Instance.new("TextLabel")
    r.Name = "RankTitle"
    r.Size = UDim2.new(1, 0, 0.45, 0)
    r.Position = UDim2.new(0, 0, 0.5, 0)
    r.BackgroundTransparency = 1
    r.Text = (player.Name == "Axlytic0" or winsVal >= 5) and "[ SULTAN DILEMA ★ ]" or (winsVal >= 2 and "[ SURVIVOR ]" or "[ ROOKIE ]")
    r.TextColor3 = (player.Name == "Axlytic0" or winsVal >= 5) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 255, 200)
    r.TextScaled = true
    r.Font = Enum.Font.GothamBlack
    r.Parent = bb
end

-- 3. SETUP DATA PEMAIN DENGAN DATASTORE PERSISTENCE
local function setupPlayer(player: Player)
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player

    local wins = Instance.new("IntValue")
    wins.Name = "Wins"
    wins.Value = 0
    wins.Parent = stats

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = stats

    local dataKey = "Player_" .. player.UserId
    if PlayerDataStore then
        local s, d = pcall(function() return PlayerDataStore:GetAsync(dataKey) end)
        if s and d then
            wins.Value = d.Wins or 0
            coins.Value = d.Coins or 0
        end
    end

    local onChar = function(c: Model) attachOverhead(c, player, wins.Value) end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

-- 4. VOID TELEPORT PROTECTOR (RESPAWN KE COLOSSEUM DECK)
task.spawn(function()
    while true do
        task.wait(0.5)
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local hrp = c:FindFirstChild("HumanoidRootPart") :: BasePart
                if hrp.Position.Y < 20 then
                    hrp.CFrame = CFrame.new(COLOSSEUM_SPAWN_POS)
                end
            end
        end
    end
end)

-- 5. GREED ORB SPAWNER
local currentGreedOrb: Part? = nil
local function spawnGreedOrb()
    if currentGreedOrb then
        currentGreedOrb:Destroy()
        currentGreedOrb = nil
    end

    local orb = Instance.new("Part")
    orb.Name = "GreedOrb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(2.5, 2.5, 2.5)
    orb.Position = Vector3.new(0, 53.5, math.random(-15, 15))
    orb.Anchored = true
    orb.CanCollide = false
    orb.Material = Enum.Material.Neon
    orb.Color = Color3.fromRGB(255, 215, 0)
    orb.Parent = arena

    -- Particle effect
    local attachment = Instance.new("Attachment", orb)
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 230, 50))
    pe.Size = NumberSequence.new(0.5, 0)
    pe.Rate = 15
    pe.Speed = NumberRange.new(1, 3)
    pe.Lifetime = NumberRange.new(0.5, 1)
    pe.Parent = attachment

    local collected = false
    orb.Touched:Connect(function(hit)
        if collected then return end
        local char = hit.Parent
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end

        collected = true
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            local coins = stats:FindFirstChild("Coins") :: IntValue?
            if coins then
                local mult = getPlayerLuckMultiplier(player)
                local reward = math.floor(5 * mult)
                coins.Value += reward
                print(string.format(">> [GREED ORB] %s mengambil Greed Orb (+%d Koin)! <<", player.Name, reward))
            end
        end

        winSfx:Play()
        orb:Destroy()
        currentGreedOrb = nil
    end)

    currentGreedOrb = orb
end

local function cleanGreedOrb()
    if currentGreedOrb then
        currentGreedOrb:Destroy()
        currentGreedOrb = nil
    end
end

-- 6. MASTER GAME LOOP (DENGAN EVENT MODIFIERS, HEADCOUNT, & NEUTRAL BEAM)
task.spawn(function()
    task.wait(2)
    while true do
        workspace.Gravity = 196.2
        redPlate.Size = DEFAULT_SIZE
        redPlate.Position = DEFAULT_RED_POS
        redPlate.Transparency = 0
        redPlate.CanCollide = true
        redPlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

        bluePlate.Size = DEFAULT_SIZE
        bluePlate.Position = DEFAULT_BLUE_POS
        bluePlate.Transparency = 0
        bluePlate.CanCollide = true
        bluePlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

        local currentMod = Modifiers[math.random(1, #Modifiers)]
        local dilemmaItem = Dilemmas[math.random(1, #Dilemmas)]

        titleText.Text = "⚠️ [ " .. dilemmaItem.Cat .. " ] EVENT: " .. currentMod.Name .. " ⚠️"
        titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
        questionText.Text = dilemmaItem.Text

        if currentMod.Type == "Ice" then
            redPlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.01, 0.1)
            bluePlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.01, 0.1)
        elseif currentMod.Type == "Gravity" then
            workspace.Gravity = 50
        end

        spawnGreedOrb()

        for sec = 10, 1, -1 do
            local currentRed = getPlateHeadcount(redPlate)
            local currentBlue = getPlateHeadcount(bluePlate)

            if currentMod.Type == "Shrink" and sec <= 8 then
                local newSize = Vector3.new(DEFAULT_SIZE.X - (10 - sec) * 1.5, 3, DEFAULT_SIZE.Z - (10 - sec) * 2)
                redPlate.Size = newSize
                bluePlate.Size = newSize
            end

            timerText.Text = "🔴 " .. currentRed .. " vs " .. currentBlue .. " 🔵 | WAKTU: " .. sec .. "s (MINORITAS MENANG!)"

            if sec <= 3 then
                timerText.TextColor3 = Color3.fromRGB(255, 50, 50)
                tickSfx:Play()
            else
                timerText.TextColor3 = Color3.fromRGB(0, 255, 200)
            end
            task.wait(1)
        end

        cleanGreedOrb()

        timerText.Text = "WAKTU HABIS!"
        timerText.TextColor3 = Color3.fromRGB(255, 215, 0)
        alarmSfx:Play()
        task.wait(1.5)

        local finalRed = getPlateHeadcount(redPlate)
        local finalBlue = getPlateHeadcount(bluePlate)
        local totalActive = finalRed + finalBlue
        local dropRed = false
        local statusMsg = ""

        if totalActive > 1 then
            if finalRed > finalBlue then
                dropRed = true
                statusMsg = "MERAH MAYORITAS (" .. finalRed .. " org)! MERAH RUNTUH!"
            elseif finalBlue > finalRed then
                dropRed = false
                statusMsg = "BIRU MAYORITAS (" .. finalBlue .. " org)! BIRU RUNTUH!"
            else
                dropRed = math.random() > 0.5
                statusMsg = "HASIL SERI! FAKTOR HOKI 50:50!"
            end
        else
            dropRed = math.random() > 0.5
            local loseColor = dropRed and "MERAH" or "BIRU"
            statusMsg = "SOLO TEST: LANTAI " .. loseColor .. " RUNTUH!"
        end

        local losingPlate = dropRed and redPlate or bluePlate
        local winningPlate = dropRed and bluePlate or redPlate

        timerText.Text = statusMsg
        timerText.TextColor3 = Color3.fromRGB(255, 50, 50)

        for i = 1, 6 do
            losingPlate.Transparency = (i % 2 == 0) and 0 or 0.5
            task.wait(0.08)
        end

        rumbleSfx:Play()
        losingPlate.Transparency = 0.9
        losingPlate.CanCollide = false

        local someoneWon = false
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local onNeutral = isPlayerOnNeutralBeam(char)
                local pos = (char:FindFirstChild("HumanoidRootPart") :: BasePart).Position
                local minX = winningPlate.Position.X - (winningPlate.Size.X / 2)
                local maxX = winningPlate.Position.X + (winningPlate.Size.X / 2)
                local minZ = winningPlate.Position.Z - (winningPlate.Size.Z / 2)
                local maxZ = winningPlate.Position.Z + (winningPlate.Size.Z / 2)
                local onWinning = (pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ and pos.Y > 45)

                if onWinning or onNeutral then
                    local stats = player:FindFirstChild("leaderstats")
                    if stats then
                        stats.Wins.Value = stats.Wins.Value + 1
                        local baseReward = onNeutral and 15 or 10
                        local luckMult = getPlayerLuckMultiplier(player)
                        local finalCoins = math.floor(baseReward * luckMult)
                        stats.Coins.Value = stats.Coins.Value + finalCoins
                        someoneWon = true
                        if onNeutral then
                            print(string.format(">> [NEUTRAL SURVIVOR] %s selamat di Neutral Beam (+%d Koin)! <<", player.Name, finalCoins))
                        end
                    end
                end
            end
        end

        if someoneWon then winSfx:Play() end

        task.wait(3.5)
        timerText.Text = "RESET ARENA & EVENT BARU..."
        task.wait(1.5)
    end
end)
