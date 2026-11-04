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

-- === DailyRewardsHandler ===
inject("DailyRewardsHandler", [======[
--!strict
-- DailyRewardsHandler.luau
-- SERVER-SIDE: 7-day rolling daily login reward system.
-- DataStore key: "DailyReward_v1_{UserId}"
-- Reward progression resets if player misses >48h (streak reset)

local Players        = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- =========================================================
-- CONFIGURATION
-- =========================================================
local DS_KEY_PREFIX = "DailyReward_v1_"
local CLAIM_COOLDOWN_SECONDS = 20 * 60 * 60  -- 20 hours (lenient daily window)
local STREAK_EXPIRE_SECONDS  = 48 * 60 * 60  -- 48h → streak resets to Day 1

type RewardType = "coins" | "title" | "cosmetic" | "consumable"
type Reward = {
	day: number,
	label: string,
	rewardType: RewardType,
	value: number | string,
	icon: string,  -- emoji or asset id string
}

local REWARDS: { Reward } = {
	{ day = 1, label = "50 Coins",            rewardType = "coins",      value = 50,              icon = "🪙" },
	{ day = 2, label = "100 Coins",           rewardType = "coins",      value = 100,             icon = "🪙" },
	{ day = 3, label = "150 Coins",           rewardType = "coins",      value = 150,             icon = "🪙" },
	{ day = 4, label = "Speed Potion",        rewardType = "consumable", value = "SpeedPotion",   icon = "⚡" },
	{ day = 5, label = "300 Coins",           rewardType = "coins",      value = 300,             icon = "💰" },
	{ day = 6, label = "Title: Loyal Player", rewardType = "title",      value = "Loyal Player",  icon = "🏅" },
	{ day = 7, label = "Angel Aura",          rewardType = "cosmetic",   value = "AngelAura",     icon = "👼" },
}

-- =========================================================
-- DATA STORE
-- =========================================================
local DailyDS: DataStore = DataStoreService:GetDataStore("DailyRewards_v1")

type DailyData = {
	lastClaimTime: number,  -- os.time() of last successful claim
	currentDay: number,     -- 1-7 (which reward was last claimed)
	totalDaysClaimed: number,
}

local DEFAULT_DATA: DailyData = {
	lastClaimTime = 0,
	currentDay = 0,
	totalDaysClaimed = 0,
}

local playerCache: { [number]: DailyData } = {}

local function loadData(player: Player): DailyData
	local key = DS_KEY_PREFIX .. player.UserId
	local ok, result = pcall(DailyDS.GetAsync, DailyDS, key)
	if ok and result then
		-- Merge with defaults for forward compatibility
		local merged: DailyData = {
			lastClaimTime    = result.lastClaimTime    or 0,
			currentDay       = result.currentDay       or 0,
			totalDaysClaimed = result.totalDaysClaimed or 0,
		}
		return merged
	end
	return {
		lastClaimTime    = DEFAULT_DATA.lastClaimTime,
		currentDay       = DEFAULT_DATA.currentDay,
		totalDaysClaimed = DEFAULT_DATA.totalDaysClaimed,
	}
end

local function saveData(player: Player, data: DailyData)
	local key = DS_KEY_PREFIX .. player.UserId
	local ok, err = pcall(DailyDS.SetAsync, DailyDS, key, data)
	if not ok then
		warn("[DailyRewardsHandler] Save failed for", player.Name, ":", err)
	end
end

-- =========================================================
-- CLAIM LOGIC
-- =========================================================
local function getClaimStatus(data: DailyData): { canClaim: boolean, nextDay: number, secondsUntilNext: number }
	local now = os.time()
	local elapsed = now - data.lastClaimTime

	-- Determine which day would be next
	local nextDay: number
	if data.currentDay == 0 then
		-- Never claimed
		nextDay = 1
	elseif elapsed >= STREAK_EXPIRE_SECONDS then
		-- Streak expired → restart from day 1
		nextDay = 1
	elseif data.currentDay >= 7 then
		-- Completed full 7-day cycle → restart
		nextDay = 1
	else
		nextDay = data.currentDay + 1
	end

	local canClaim    = elapsed >= CLAIM_COOLDOWN_SECONDS or data.currentDay == 0
	local secondsLeft = math.max(0, CLAIM_COOLDOWN_SECONDS - elapsed)

	return { canClaim = canClaim, nextDay = nextDay, secondsUntilNext = secondsLeft }
end

-- Called when player fires ClaimDailyReward RemoteFunction
local function handleClaim(player: Player): { success: boolean, day: number?, reward: Reward?, message: string }
	local data = playerCache[player.UserId]
	if not data then
		return { success = false, day = nil, reward = nil, message = "Data not loaded yet. Try again." }
	end

	local status = getClaimStatus(data)
	if not status.canClaim then
		local hrs  = math.floor(status.secondsUntilNext / 3600)
		local mins = math.floor((status.secondsUntilNext % 3600) / 60)
		return { success = false, day = nil, reward = nil, message = string.format("Come back in %dh %dm!", hrs, mins) }
	end

	-- Apply reward
	local day    = status.nextDay
	local reward = REWARDS[day]
	if not reward then
		return { success = false, day = nil, reward = nil, message = "Invalid reward day." }
	end

	-- Apply effect based on rewardType
	if reward.rewardType == "coins" then
		-- Fire event to ShopServerHandler / StatsServerHandler to add coins
		local Events = game:GetService("ReplicatedStorage"):FindFirstChild("DilemmaEvents") :: Folder
		if Events then
			local addCoins = Events:FindFirstChild("ServerAddCoins") :: BindableEvent
			if addCoins then
				addCoins:Fire(player, reward.value)
			end
		end
	elseif reward.rewardType == "consumable" then
		-- For now: grant speed boost stored in leaderstats or DataStore via bindable
		local Events = game:GetService("ReplicatedStorage"):FindFirstChild("DilemmaEvents") :: Folder
		if Events then
			local grantConsumable = Events:FindFirstChild("ServerGrantConsumable") :: BindableEvent
			if grantConsumable then
				grantConsumable:Fire(player, reward.value)
			end
		end
	elseif reward.rewardType == "title" then
		-- Grant cosmetic title via OverheadTitleHandler
		local Events = game:GetService("ReplicatedStorage"):FindFirstChild("DilemmaEvents") :: Folder
		if Events then
			local grantTitle = Events:FindFirstChild("ServerGrantTitle") :: BindableEvent
			if grantTitle then
				grantTitle:Fire(player, reward.value)
			end
		end
	elseif reward.rewardType == "cosmetic" then
		-- Cosmetic (Angel Aura) — stored in player cosmetic flags DataStore
		local Events = game:GetService("ReplicatedStorage"):FindFirstChild("DilemmaEvents") :: Folder
		if Events then
			local grantCosmetic = Events:FindFirstChild("ServerGrantCosmetic") :: BindableEvent
			if grantCosmetic then
				grantCosmetic:Fire(player, reward.value)
			end
		end
	end

	-- Update data
	data.lastClaimTime    = os.time()
	data.currentDay       = day
	data.totalDaysClaimed = data.totalDaysClaimed + 1
	saveData(player, data)

	print(string.format("[DailyRewards] %s claimed Day %d reward: %s", player.Name, day, reward.label))
	return { success = true, day = day, reward = reward, message = "" }
end

-- =========================================================
-- STATUS QUERY (RemoteFunction)
-- Called by client to get the current calendar state
-- =========================================================
local function handleStatusQuery(player: Player): { days: { { day: number, state: string, reward: Reward } } }
	local data   = playerCache[player.UserId]
	local status = data and getClaimStatus(data) or { canClaim = true, nextDay = 1, secondsUntilNext = 0 }

	local dayStates: { { day: number, state: string, reward: Reward } } = {}
	for _, reward in REWARDS do
		local state: string
		if data and reward.day < (data.currentDay or 0) + 1 then
			-- Already claimed (past days in current cycle)
			if data.currentDay == 0 or (os.time() - data.lastClaimTime) >= STREAK_EXPIRE_SECONDS then
				state = "locked"
			else
				state = "claimed"
			end
		elseif reward.day == status.nextDay and status.canClaim then
			state = "claimable"
		elseif reward.day == status.nextDay and not status.canClaim then
			state = "pending"
		else
			state = "locked"
		end
		table.insert(dayStates, { day = reward.day, state = state, reward = reward })
	end

	return { days = dayStates }
end

-- =========================================================
-- REMOTE SETUP
-- =========================================================
local RS = game:GetService("ReplicatedStorage")
local Events = RS:WaitForChild("DilemmaEvents", 15) :: Folder

local function getOrMakeFunction(name: string): RemoteFunction
	local rf = Events:FindFirstChild(name) :: RemoteFunction
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = Events
	end
	return rf
end

local rfClaim  = getOrMakeFunction("ClaimDailyReward")
local rfStatus = getOrMakeFunction("GetDailyStatus")

rfClaim.OnServerInvoke = function(player: Player)
	return handleClaim(player)
end

rfStatus.OnServerInvoke = function(player: Player)
	return handleStatusQuery(player)
end

-- =========================================================
-- PLAYER LIFECYCLE
-- =========================================================
local function onPlayerAdded(player: Player)
	local data = loadData(player)
	playerCache[player.UserId] = data

	-- Auto-notify client that daily is available
	local evNotify = Events:FindFirstChild("DailyRewardAvailable") :: RemoteEvent
	if not evNotify then
		evNotify = Instance.new("RemoteEvent")
		evNotify.Name = "DailyRewardAvailable"
		evNotify.Parent = Events
	end

	local status = getClaimStatus(data)
	if status.canClaim then
		task.wait(3)  -- Wait for client to load UI
		evNotify:FireClient(player, { nextDay = status.nextDay })
	end
end

local function onPlayerRemoving(player: Player)
	local data = playerCache[player.UserId]
	if data then
		saveData(player, data)
		playerCache[player.UserId] = nil
	end
end

for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for userId, data in playerCache do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			saveData(player, data)
		end
	end
end)

print("[DailyRewardsHandler] ✅ Loaded — 7-day login reward system active.")


]======])

-- === GraphicsOverhaulInstaller ===
inject("GraphicsOverhaulInstaller", [======[
--!strict
-- GraphicsOverhaulInstaller.luau
-- SERVER-SIDE: Run once on server start to configure high-quality lighting,
-- atmosphere, post-processing effects, and dynamic prop lights.
-- Benchmarked against: Doors, Blox Fruits, Fisch visual quality standards.
-- Technology: Future Lighting + Atmosphere + BloomEffect + ColorCorrectionEffect + SunRaysEffect

local Lighting  = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- =========================================================
-- STEP 1: LIGHTING SERVICE SETTINGS
-- =========================================================
pcall(function() Lighting.Technology = Enum.Technology.Future end)   -- Highest quality renderer
Lighting.GlobalShadows      = true
Lighting.Ambient            = Color3.fromRGB(40, 35, 55)       -- Deep purple-dark ambient
Lighting.OutdoorAmbient     = Color3.fromRGB(55, 50, 70)
Lighting.Brightness         = 1.8
Lighting.ColorShift_Top     = Color3.fromRGB(255, 230, 180)   -- Warm golden top light
Lighting.ColorShift_Bottom  = Color3.fromRGB(80, 70, 120)     -- Cool purple bounce
Lighting.EnvironmentDiffuseScale  = 0.6
Lighting.EnvironmentSpecularScale = 0.8
Lighting.ShadowSoftness     = 0.25
Lighting.ClockTime          = 14  -- 2 PM sun angle (dramatic shadows)
Lighting.GeographicLatitude = 23  -- Tropical latitude for high sun

-- =========================================================
-- STEP 2: ATMOSPHERE
-- =========================================================
local function ensureInstance<T>(parent: Instance, className: string, name: string): T
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing :: T
	end
	if existing then existing:Destroy() end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst :: T
end

local atmosphere = ensureInstance(Lighting, "Atmosphere", "GameAtmosphere") :: Atmosphere
atmosphere.Density      = 0.28       -- Slight haze for depth
atmosphere.Offset       = 0.20       -- Horizon glow
atmosphere.Color        = Color3.fromRGB(220, 185, 140)   -- Warm golden desert/colosseum sky
atmosphere.Decay        = Color3.fromRGB(80, 65, 100)     -- Purple horizon decay
atmosphere.Glare        = 0.12
atmosphere.Haze         = 2.5

-- =========================================================
-- STEP 3: BLOOM EFFECT
-- High bloom = glowing neon, golden highlights, VFX pop
-- =========================================================
local bloom = ensureInstance(Lighting, "BloomEffect", "GameBloom") :: BloomEffect
bloom.Enabled   = true
bloom.Intensity = 0.65
bloom.Size      = 28
bloom.Threshold = 0.90   -- Only brightest pixels bloom (neon, gold, fire)

-- =========================================================
-- STEP 4: COLOR CORRECTION
-- Cinematic grading: slightly warmer, more contrast, slightly desaturated
-- gives professional Roblox top-tier game look
-- =========================================================
local cc = ensureInstance(Lighting, "ColorCorrectionEffect", "GameColorGrade") :: ColorCorrectionEffect
cc.Enabled     = true
cc.Brightness  = -0.03
cc.Contrast    = 0.12
cc.Saturation  = 0.10
cc.TintColor   = Color3.fromRGB(255, 245, 230)   -- Very warm tint

-- =========================================================
-- STEP 5: SUN RAYS
-- =========================================================
local sunrays = ensureInstance(Lighting, "SunRaysEffect", "GameSunRays") :: SunRaysEffect
sunrays.Enabled    = true
sunrays.Intensity  = 0.18
sunrays.Spread     = 0.60

-- =========================================================
-- STEP 6: DEPTH OF FIELD (subtle — not obstructive)
-- Only very slight blur at extreme distances
-- =========================================================
local dof = ensureInstance(Lighting, "DepthOfFieldEffect", "GameDOF") :: DepthOfFieldEffect
dof.Enabled      = true
dof.FarIntensity = 0.08    -- Very gentle far blur
dof.NearIntensity = 0
dof.FocusDistance = 60
dof.InFocusRadius = 40

-- =========================================================
-- STEP 7: SKY
-- Custom dramatic sky (Roblox built-in SkyBox)
-- =========================================================
local sky = ensureInstance(Lighting, "Sky", "GameSky") :: Sky
-- Using built-in Roblox sky mesh IDs (always approved/unmoderated)
sky.SkyboxBk = "rbxassetid://159454286"
sky.SkyboxDn = "rbxassetid://159454296"
sky.SkyboxFt = "rbxassetid://159454293"
sky.SkyboxLf = "rbxassetid://159454289"
sky.SkyboxRt = "rbxassetid://159454293"
sky.SkyboxUp = "rbxassetid://159454296"
sky.StarCount = 3000
sky.SunAngularSize = 11
sky.MoonAngularSize = 11
sky.CelestialBodiesShown = true

-- =========================================================
-- STEP 8: DYNAMIC TORCH/POINT LIGHTS
-- Scan Workspace for parts named "*Torch*" or "*Pillar*" and attach PointLights
-- =========================================================
local function addPointLight(part: BasePart, color: Color3, brightness: number, range: number)
	local existing = part:FindFirstChildOfClass("PointLight")
	if existing then existing:Destroy() end
	local pl = Instance.new("PointLight")
	pl.Color      = color
	pl.Brightness = brightness
	pl.Range      = range
	pl.Shadows    = true
	pl.Parent     = part
end

local TORCH_COLOR   = Color3.fromRGB(255, 160, 60)
local VIP_GOLD_COLOR = Color3.fromRGB(255, 215, 80)
local NEON_CYAN     = Color3.fromRGB(0, 220, 255)

local function scanAndLightWorkspace()
	local function processDescendant(obj: Instance)
		if not obj:IsA("BasePart") then return end
		local name = obj.Name:lower()
		if string.find(name, "torch") or string.find(name, "fire") then
			addPointLight(obj, TORCH_COLOR, 2.5, 20)
		elseif string.find(name, "throne") or string.find(name, "vipbox") or string.find(name, "imperial") then
			addPointLight(obj, VIP_GOLD_COLOR, 1.8, 16)
		elseif string.find(name, "neon") or string.find(name, "cyber") or string.find(name, "grid") then
			addPointLight(obj, NEON_CYAN, 2.0, 18)
		elseif string.find(name, "orb") or string.find(name, "gem") then
			addPointLight(obj, Color3.fromRGB(100, 255, 100), 3.0, 12)
		end
	end

	for _, obj in Workspace:GetDescendants() do
		pcall(processDescendant, obj)
	end
	print("[GraphicsOverhaul] 💡 Dynamic lights applied to Workspace props.")
end

-- Run after a small delay to ensure ColosseumBuilder has placed all parts
task.delay(5, scanAndLightWorkspace)

-- Also run whenever a new descendant is added (new biome built, etc.)
Workspace.DescendantAdded:Connect(function(obj)
	task.wait(0.1)
	pcall(function()
		if obj:IsA("BasePart") then
			local name = obj.Name:lower()
			if string.find(name, "torch") or string.find(name, "fire") or
				string.find(name, "throne") or string.find(name, "neon") or
				string.find(name, "orb") then
				processDescendant(obj)
			end
		end
	end)
end)

-- =========================================================
-- STEP 9: AMBIENT CORNER FIRE PARTICLES
-- Add fire glow particles to arena corner anchors
-- Named: "ArenaCornerFire_1" through "ArenaCornerFire_4"
-- =========================================================
local function spawnCornerFire(position: Vector3, name: string)
	-- Create a small invisible anchor part
	local anchor = Instance.new("Part")
	anchor.Name         = name
	anchor.Size         = Vector3.new(1, 1, 1)
	anchor.Position     = position
	anchor.Anchored     = true
	anchor.CanCollide   = false
	anchor.Transparency = 1
	anchor.Parent       = Workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = anchor

	-- Fire particles (rising embers)
	local fire = Instance.new("ParticleEmitter")
	fire.Texture     = "rbxassetid://6880497226"
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 200)),
	})
	fire.LightEmission    = 1
	fire.LightInfluence   = 0
	fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	fire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	fire.Speed        = NumberRange.new(6, 12)
	fire.SpreadAngle  = Vector2.new(15, 15)
	fire.Rate         = 20
	fire.Lifetime     = NumberRange.new(1.5, 2.5)
	fire.RotSpeed     = NumberRange.new(-30, 30)
	fire.Parent       = attachment

	-- PointLight for fire glow
	local pl = Instance.new("PointLight")
	pl.Color      = Color3.fromRGB(255, 130, 20)
	pl.Brightness = 3
	pl.Range      = 22
	pl.Shadows    = false
	pl.Parent     = anchor

	-- Flicker animation
	task.spawn(function()
		while anchor.Parent do
			local targetBrightness = math.random(20, 35) / 10
			local tween = TweenService:Create(pl, TweenInfo.new(math.random(4, 10) / 10, Enum.EasingStyle.Sine), { Brightness = targetBrightness })
			tween:Play()
			task.wait(math.random(4, 10) / 10)
		end
	end)
end

-- Spawn 4 corner fires around arena (adjust Y=60 to match ColosseumBuilder arena Y)
task.delay(6, function()
	-- Only spawn if anchors don't already exist (idempotent)
	if not Workspace:FindFirstChild("ArenaCornerFire_1") then
		spawnCornerFire(Vector3.new( 40, 62, 0),   "ArenaCornerFire_1")
		spawnCornerFire(Vector3.new(-40, 62, 0),   "ArenaCornerFire_2")
		spawnCornerFire(Vector3.new(0,  62,  40),  "ArenaCornerFire_3")
		spawnCornerFire(Vector3.new(0,  62, -40),  "ArenaCornerFire_4")
		print("[GraphicsOverhaul] 🔥 Arena corner fire particles spawned.")
	end
end)

-- =========================================================
-- STEP 10: BIOME LIGHTING PRESETS (called by ColosseumBuilder)
-- =========================================================
type BiomeLightingConfig = {
	ambient: Color3,
	outdoorAmbient: Color3,
	colorTop: Color3,
	colorBottom: Color3,
	atmosphereColor: Color3,
	atmosphereDensity: number,
	bloomThreshold: number,
	tintColor: Color3,
}

local BIOME_CONFIGS: { [number]: BiomeLightingConfig } = {
	-- Biome 1: Imperial (default warm gold)
	[1] = {
		ambient         = Color3.fromRGB(40, 35, 55),
		outdoorAmbient  = Color3.fromRGB(55, 50, 70),
		colorTop        = Color3.fromRGB(255, 230, 180),
		colorBottom     = Color3.fromRGB(80, 70, 120),
		atmosphereColor = Color3.fromRGB(220, 185, 140),
		atmosphereDensity = 0.28,
		bloomThreshold  = 0.90,
		tintColor       = Color3.fromRGB(255, 245, 230),
	},
	-- Biome 2: Magma Inferno (deep red-orange)
	[2] = {
		ambient         = Color3.fromRGB(80, 20, 10),
		outdoorAmbient  = Color3.fromRGB(100, 30, 15),
		colorTop        = Color3.fromRGB(255, 100, 30),
		colorBottom     = Color3.fromRGB(120, 20, 0),
		atmosphereColor = Color3.fromRGB(200, 80, 20),
		atmosphereDensity = 0.40,
		bloomThreshold  = 0.75,
		tintColor       = Color3.fromRGB(255, 220, 200),
	},
	-- Biome 3: Glaciers Ice (cool cyan-blue)
	[3] = {
		ambient         = Color3.fromRGB(100, 130, 180),
		outdoorAmbient  = Color3.fromRGB(120, 150, 200),
		colorTop        = Color3.fromRGB(180, 220, 255),
		colorBottom     = Color3.fromRGB(50, 80, 150),
		atmosphereColor = Color3.fromRGB(160, 200, 240),
		atmosphereDensity = 0.20,
		bloomThreshold  = 0.85,
		tintColor       = Color3.fromRGB(220, 235, 255),
	},
	-- Biome 4: Cyberpunk Void (neon purple-cyan)
	[4] = {
		ambient         = Color3.fromRGB(10, 10, 30),
		outdoorAmbient  = Color3.fromRGB(20, 10, 40),
		colorTop        = Color3.fromRGB(80, 0, 180),
		colorBottom     = Color3.fromRGB(0, 180, 200),
		atmosphereColor = Color3.fromRGB(40, 20, 80),
		atmosphereDensity = 0.50,
		bloomThreshold  = 0.65,  -- Strong bloom for neon glow
		tintColor       = Color3.fromRGB(220, 200, 255),
	},
}

-- Expose via BindableFunction for ColosseumBuilder to call
local bfApplyBiomeLighting = RS:FindFirstChild("ApplyBiomeLighting") :: BindableFunction
if not bfApplyBiomeLighting then
	bfApplyBiomeLighting = Instance.new("BindableFunction")
	bfApplyBiomeLighting.Name = "ApplyBiomeLighting"
	bfApplyBiomeLighting.Parent = RS
end

local RS = game:GetService("ReplicatedStorage")

bfApplyBiomeLighting.OnInvoke = function(biomeId: number)
	local cfg = BIOME_CONFIGS[biomeId]
	if not cfg then
		warn("[GraphicsOverhaul] Unknown biomeId:", biomeId)
		return
	end

	local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	-- Tween Lighting properties
	TweenService:Create(Lighting, tweenInfo, {
		Ambient        = cfg.ambient,
		OutdoorAmbient = cfg.outdoorAmbient,
		ColorShift_Top = cfg.colorTop,
		ColorShift_Bottom = cfg.colorBottom,
	}):Play()

	-- Tween Atmosphere
	if atmosphere and atmosphere.Parent then
		TweenService:Create(atmosphere, tweenInfo, {
			Color   = cfg.atmosphereColor,
			Density = cfg.atmosphereDensity,
		}):Play()
	end

	-- Tween Bloom threshold
	if bloom and bloom.Parent then
		TweenService:Create(bloom, tweenInfo, {
			Threshold = cfg.bloomThreshold,
		}):Play()
	end

	-- Tween Color Correction tint
	if cc and cc.Parent then
		TweenService:Create(cc, tweenInfo, {
			TintColor = cfg.tintColor,
		}):Play()
	end

	print(string.format("[GraphicsOverhaul] 🎨 Biome %d lighting applied.", biomeId))
end

print("[GraphicsOverhaulInstaller] ✅ Loaded — Future Lighting, Bloom, Atmosphere, DOF, SunRays, Corner Fires active.")


]======])

return 'OK: DailyRewardsHandler, GraphicsOverhaulInstaller'