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
    print("✅ Injected Script: " .. name)
end

-- === OverheadTitleHandler ===
inject("OverheadTitleHandler", [======[
--!strict
-- OverheadTitleHandler.luau
-- SERVER-SIDE: Creates and updates BillboardGui overhead title for every player.
-- Displays: Rank Title | Win Streak | VIP Badge
-- Dependencies: StatsServerHandler (DataStore), VIPPassHandler, DilemmaServer (WinStreak events)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- =========================================================
-- CONFIGURATION
-- =========================================================
local VIP_PASS_ID: number = 2064678688
local DEVELOPER_BYPASS: { [string]: boolean } = { Axlytic0 = true }

-- Rank titles based on total wins
local RANK_THRESHOLDS: { { wins: number, title: string, color: Color3 } } = {
	{ wins = 0,  title = "Rookie Survivor",   color = Color3.fromRGB(180, 180, 180) },
	{ wins = 6,  title = "Mind Master",        color = Color3.fromRGB(80,  200, 120) },
	{ wins = 16, title = "Colosseum Knight",   color = Color3.fromRGB(100, 160, 240) },
	{ wins = 31, title = "Tactician",          color = Color3.fromRGB(220, 180,  60) },
	{ wins = 51, title = "Untouchable",        color = Color3.fromRGB(255,  80,  80) },
}

-- Streak visual thresholds
local STREAK_COLORS: { [number]: Color3 } = {
	[3]  = Color3.fromRGB(255, 160,  40),  -- orange fire
	[5]  = Color3.fromRGB(255,  60,  60),  -- red flame
	[10] = Color3.fromRGB(180,   0, 255),  -- purple legendary
}

-- =========================================================
-- INTERNAL STATE
-- =========================================================
local playerWins:    { [number]: number } = {}  -- userId → total wins
local playerStreaks: { [number]: number } = {}  -- userId → current streak
local playerBoards:  { [number]: BillboardGui } = {}  -- userId → BillboardGui

-- =========================================================
-- HELPERS
-- =========================================================
local function getRankInfo(wins: number): { title: string, color: Color3 }
	local best = RANK_THRESHOLDS[1]
	for _, tier in RANK_THRESHOLDS do
		if wins >= tier.wins then
			best = tier
		end
	end
	return best
end

local function getStreakColor(streak: number): Color3
	local best = Color3.fromRGB(255, 255, 255)
	for threshold, col in STREAK_COLORS do
		if streak >= threshold then
			best = col
		end
	end
	return best
end

local function isVIP(player: Player): boolean
	if DEVELOPER_BYPASS[player.Name] then return true end
	local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, VIP_PASS_ID)
	return ok and result
end

-- =========================================================
-- BUILD BILLBOARD GUI
-- =========================================================
local function buildBillboard(character: Model, player: Player): BillboardGui
	-- Remove old if exists
	local head = character:WaitForChild("Head", 10) :: Part
	local old = head:FindFirstChild("OverheadBoard")
	if old then old:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadBoard"
	billboard.Size = UDim2.new(0, 220, 0, 72)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = false
	billboard.ResetOnSpawn = false
	billboard.MaxDistance = 60
	billboard.Parent = head

	-- Background frame (glassmorphism dark)
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = bg

	-- Rank title label
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.Size = UDim2.new(1, -8, 0.48, 0)
	rankLabel.Position = UDim2.new(0, 4, 0, 2)
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	rankLabel.Text = "Rookie Survivor"
	rankLabel.Parent = bg

	-- Player name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -8, 0.36, 0)
	nameLabel.Position = UDim2.new(0, 4, 0.46, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.Text = player.Name
	nameLabel.Parent = bg

	-- Streak label (bottom right)
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	streakLabel.Position = UDim2.new(0.5, 0, 0.68, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.TextScaled = true
	streakLabel.Font = Enum.Font.GothamBlack
	streakLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	streakLabel.Text = ""
	streakLabel.Parent = bg

	-- VIP label (bottom left)
	local vipLabel = Instance.new("TextLabel")
	vipLabel.Name = "VIPLabel"
	vipLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	vipLabel.Position = UDim2.new(0, 4, 0.68, 0)
	vipLabel.BackgroundTransparency = 1
	vipLabel.TextScaled = true
	vipLabel.Font = Enum.Font.GothamBold
	vipLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	vipLabel.Text = isVIP(player) and "👑 IMPERIAL VIP" or ""
	vipLabel.Parent = bg

	playerBoards[player.UserId] = billboard
	return billboard
end

-- =========================================================
-- UPDATE BILLBOARD DATA
-- =========================================================
local function refreshBoard(player: Player)
	local billboard = playerBoards[player.UserId]
	if not billboard or not billboard.Parent then return end

	local bg = billboard:FindFirstChild("Background") :: Frame
	if not bg then return end

	local wins   = playerWins[player.UserId]   or 0
	local streak = playerStreaks[player.UserId] or 0
	local rank   = getRankInfo(wins)

	local rankLabel   = bg:FindFirstChild("RankLabel")   :: TextLabel
	local streakLabel = bg:FindFirstChild("StreakLabel") :: TextLabel

	if rankLabel then
		rankLabel.Text        = rank.title
		rankLabel.TextColor3  = rank.color
	end

	if streakLabel then
		if streak >= 3 then
			streakLabel.Text       = "🔥 STREAK x" .. streak
			streakLabel.TextColor3 = getStreakColor(streak)
		else
			streakLabel.Text = ""
		end
	end

	-- Gold stroke pulse for VIP
	local stroke = bg:FindFirstChildOfClass("UIStroke") :: UIStroke
	if stroke and isVIP(player) then
		stroke.Transparency = 0
		stroke.Thickness = 2.5
	end
end

-- =========================================================
-- AURA PARTICLE EFFECT (VIP + High Streak)
-- =========================================================
local function attachAura(character: Model, player: Player)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	-- Remove old aura
	local oldAura = hrp:FindFirstChild("OverheadAura")
	if oldAura then oldAura:Destroy() end

	local streak = playerStreaks[player.UserId] or 0
	local vip    = isVIP(player)
	if not vip and streak < 3 then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "OverheadAura"
	attachment.Position = Vector3.new(0, 0, 0)
	attachment.Parent = hrp

	-- Base aura: rising sparks
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxassetid://6880497226"  -- spark texture (Roblox default approved)
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, vip and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	sparks.LightEmission = 0.8
	sparks.LightInfluence = 0.1
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Speed = NumberRange.new(3, 6)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = streak >= 5 and 24 or (vip and 14 or 8)
	sparks.Lifetime = NumberRange.new(1.2, 2)
	sparks.RotSpeed = NumberRange.new(-45, 45)
	sparks.Rotation = NumberRange.new(0, 360)
	sparks.Parent = attachment

	-- VIP angel ring (extra glow emission)
	if vip then
		local ring = Instance.new("ParticleEmitter")
		ring.Texture = "rbxassetid://6880479568"  -- ring/circle glow texture
		ring.Color = ColorSequence.new(Color3.fromRGB(255, 230, 100))
		ring.LightEmission = 1
		ring.LightInfluence = 0
		ring.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
		ring.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
		ring.Speed = NumberRange.new(0, 0.5)
		ring.Rate = 6
		ring.Lifetime = NumberRange.new(0.8, 1.2)
		ring.Parent = attachment
	end
end

-- =========================================================
-- REMOTE EVENTS
-- =========================================================
local RS = game:GetService("ReplicatedStorage")
local Events = RS:WaitForChild("DilemmaEvents", 15) :: Folder
local function getOrMakeEvent(name: string): RemoteEvent
	local ev = Events:FindFirstChild(name) :: RemoteEvent
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = Events
	end
	return ev
end

local evUpdateTitle  = getOrMakeEvent("UpdateOverheadTitle")  -- server→client not needed; server owns billboard
local evWinStreakChanged = getOrMakeEvent("WinStreakChanged") -- DilemmaServer fires this

-- DilemmaServer fires WinStreakChanged(player, totalWins, currentStreak)
evWinStreakChanged.OnServerEvent:Connect(function(_sender: Player, targetPlayer: Player, totalWins: number, streak: number)
	-- Only allow server-side scripts to fire this (validate sender == server ... RemoteEvent from server script)
	playerWins[targetPlayer.UserId]    = totalWins
	playerStreaks[targetPlayer.UserId] = streak
	refreshBoard(targetPlayer)
	if targetPlayer.Character then
		attachAura(targetPlayer.Character, targetPlayer)
	end
end)

-- =========================================================
-- PLAYER LIFECYCLE
-- =========================================================
local function onCharacterAdded(character: Model, player: Player)
	-- Wait for head
	character:WaitForChild("Head", 10)
	task.wait(0.3)  -- small settle delay
	buildBillboard(character, player)
	refreshBoard(player)
	attachAura(character, player)
end

local function onPlayerAdded(player: Player)
	playerWins[player.UserId]    = 0
	playerStreaks[player.UserId] = 0

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)

	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

local function onPlayerRemoving(player: Player)
	playerWins[player.UserId]    = nil
	playerStreaks[player.UserId] = nil
	playerBoards[player.UserId]  = nil
end

for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[OverheadTitleHandler] ✅ Loaded — Rank titles, auras, and streak tags active.")


]======])

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

-- === StatsServerHandler ===
inject("StatsServerHandler", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: RPG STATS & ATTRIBUTES CONTROLLER ★
-- Server Script: Aspek 2 - Upgrade Agility, Weight (Anti-Push), & Luck
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore
local successStore, store = pcall(function()
    return DataStoreService:GetDataStore("DilemmaRoyale_v1")
end)
if successStore then PlayerDataStore = store end

local upgradeRemote = ReplicatedStorage:FindFirstChild("UpgradeStatRemote") :: RemoteFunction?
if not upgradeRemote then
    upgradeRemote = Instance.new("RemoteFunction")
    upgradeRemote.Name = "UpgradeStatRemote"
    upgradeRemote.Parent = ReplicatedStorage
end

local MAX_STAT_LEVEL = 10

local function getUpgradeCost(currentLevel: number): number
    return currentLevel * 15
end

local function applyPlayerStats(player: Player)
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local statsFolder = player:FindFirstChild("PlayerStats")
    if not humanoid or not root or not statsFolder then return end

    local agilityVal = (statsFolder:FindFirstChild("Agility") :: IntValue).Value
    local weightVal = (statsFolder:FindFirstChild("Weight") :: IntValue).Value

    -- 1. Agility: WalkSpeed & JumpPower
    humanoid.WalkSpeed = 16 + (agilityVal * 1.5)
    humanoid.UseJumpPower = true
    humanoid.JumpPower = 50 + (agilityVal * 3)

    -- 2. Weight: Anti-Push Physical Resistance
    -- Semakin tinggi weight, semakin berat massanya (CustomPhysicalProperties Density 0.7 -> 3.5)
    local density = 0.7 + (weightVal * 0.28)
    root.CustomPhysicalProperties = PhysicalProperties.new(density, 0.5, 0.5)
end

local function setupPlayerStats(player: Player)
    local statsFolder = Instance.new("Folder")
    statsFolder.Name = "PlayerStats"
    statsFolder.Parent = player

    local agility = Instance.new("IntValue")
    agility.Name = "Agility"
    agility.Value = 1
    agility.Parent = statsFolder

    local weight = Instance.new("Weight") -- IntValue
    local weightVal = Instance.new("IntValue")
    weightVal.Name = "Weight"
    weightVal.Value = 1
    weightVal.Parent = statsFolder

    local luck = Instance.new("IntValue")
    luck.Name = "Luck"
    luck.Value = 1
    luck.Parent = statsFolder

    -- Load from DataStore
    local key = "Stats_" .. player.UserId
    if PlayerDataStore then
        local s, d = pcall(function() return PlayerDataStore:GetAsync(key) end)
        if s and d and typeof(d) == "table" then
            agility.Value = math.clamp(d.Agility or 1, 1, MAX_STAT_LEVEL)
            weightVal.Value = math.clamp(d.Weight or 1, 1, MAX_STAT_LEVEL)
            luck.Value = math.clamp(d.Luck or 1, 1, MAX_STAT_LEVEL)
        end
    end

    if player.Character then
        applyPlayerStats(player)
    end
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        applyPlayerStats(player)
    end)
end

local function savePlayerStats(player: Player)
    if not PlayerDataStore then return end
    local statsFolder = player:FindFirstChild("PlayerStats")
    if not statsFolder then return end

    local data = {
        Agility = (statsFolder:FindFirstChild("Agility") :: IntValue).Value,
        Weight = (statsFolder:FindFirstChild("Weight") :: IntValue).Value,
        Luck = (statsFolder:FindFirstChild("Luck") :: IntValue).Value
    }
    pcall(function()
        PlayerDataStore:SetAsync("Stats_" .. player.UserId, data)
    end)
end

Players.PlayerAdded:Connect(setupPlayerStats)
Players.PlayerRemoving:Connect(savePlayerStats)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerStats(player)
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayerStats(p)
end

-- Server-Side Remote Function Handler (Anti-Exploit Validated)
upgradeRemote.OnServerInvoke = function(player: Player, statName: string)
    local statsFolder = player:FindFirstChild("PlayerStats")
    local leaderstats = player:FindFirstChild("leaderstats")
    if not statsFolder or not leaderstats then
        return {Success = false, Message = "Data karakter belum siap!"}
    end

    local statObj = statsFolder:FindFirstChild(statName) :: IntValue?
    local coinsObj = leaderstats:FindFirstChild("Coins") :: IntValue?
    if not statObj or not coinsObj then
        return {Success = false, Message = "Stat tidak valid!"}
    end

    if statObj.Value >= MAX_STAT_LEVEL then
        return {Success = false, Message = "Stat " .. statName .. " sudah mencapai Level Maksimal (Lv 10)!"}
    end

    local cost = getUpgradeCost(statObj.Value)
    if coinsObj.Value < cost then
        return {
            Success = false,
            Message = string.format("Koin tidak cukup! Butuh %d koin, kamu punya %d koin.", cost, coinsObj.Value)
        }
    end

    -- Transaksi Sukses
    coinsObj.Value -= cost
    statObj.Value += 1
    applyPlayerStats(player)
    savePlayerStats(player)

    return {
        Success = true,
        Message = string.format("Sukses upgrade %s ke Level %d! Sisa koin: %d", statName, statObj.Value, coinsObj.Value),
        NewLevel = statObj.Value,
        NewCost = getUpgradeCost(statObj.Value)
    }
end

print(">> [SUKSES] StatsServerHandler (Aspek 2: RPG Attributes) Berjalan! <<")


]======])

-- === SkillServerHandler ===
inject("SkillServerHandler", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: TACTICAL SKILLS SERVER HANDLER ★
-- Server Script: Aspek 3 - Validasi Server Cooldown & Fisika Skill
-- Anti-Exploit: Semua aksi diverifikasi di Server
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local useSkillRemote = ReplicatedStorage:FindFirstChild("UseSkillRemote") :: RemoteEvent?
if not useSkillRemote then
    useSkillRemote = Instance.new("RemoteEvent")
    useSkillRemote.Name = "UseSkillRemote"
    useSkillRemote.Parent = ReplicatedStorage
end

local skillFeedbackRemote = ReplicatedStorage:FindFirstChild("SkillFeedbackRemote") :: RemoteEvent?
if not skillFeedbackRemote then
    skillFeedbackRemote = Instance.new("RemoteEvent")
    skillFeedbackRemote.Name = "SkillFeedbackRemote"
    skillFeedbackRemote.Parent = ReplicatedStorage
end

local SKILL_CONFIG = {
    ["ForcePush"] = { Cooldown = 10, Range = 18, BaseForce = 75 },
    ["SpeedDash"] = { Cooldown = 8, Duration = 2.5, SpeedBoost = 42 },
    ["GravityFeather"] = { Cooldown = 12, Duration = 4.0, Buoyancy = 0.55 }
}

-- Cooldown Tracker di Server (Anti-Spam / Anti-Cheat)
local playerCooldowns: {[number]: {[string]: number}} = {}

local function getTargetWeightLevel(targetPlayer: Player): number
    local stats = targetPlayer:FindFirstChild("PlayerStats")
    if stats then
        local w = stats:FindFirstChild("Weight") :: IntValue?
        if w then return w.Value end
    end
    return 1
end

local function executeForcePush(player: Player, config: typeof(SKILL_CONFIG.ForcePush))
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return end

    -- Visual Shockwave Ring
    local shockwave = Instance.new("Part")
    shockwave.Shape = Enum.PartType.Cylinder
    shockwave.Size = Vector3.new(0.5, 4, 4)
    shockwave.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Material = Enum.Material.Neon
    shockwave.Color = Color3.fromRGB(0, 255, 255)
    shockwave.Parent = workspace

    task.spawn(function()
        for i = 1, 12 do
            task.wait(0.02)
            shockwave.Size += Vector3.new(0, config.Range / 6, config.Range / 6)
            shockwave.Transparency = i / 12
        end
        shockwave:Destroy()
    end)

    -- Berikan impulse pada pemain sekitar yang berada dalam jangkauan
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherRoot = otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
            local otherHum = otherChar:FindFirstChildOfClass("Humanoid")
            if otherRoot and otherHum and otherHum.Health > 0 then
                local dist = (otherRoot.Position - root.Position).Magnitude
                if dist <= config.Range then
                    -- Hitung resistensi berat (Stat Weight)
                    local weightLv = getTargetWeightLevel(otherPlayer)
                    local resistanceMultiplier = 1 / (1 + (weightLv * 0.12)) -- Lv 10 -> -55% dorongan!

                    local pushDir = (otherRoot.Position - root.Position).Unit
                    pushDir = Vector3.new(pushDir.X, 0.35, pushDir.Z).Unit

                    local finalImpulse = pushDir * config.BaseForce * resistanceMultiplier * otherRoot.AssemblyMass
                    otherRoot:ApplyImpulse(finalImpulse)
                end
            end
        end
    end
end

local function executeSpeedDash(player: Player, config: typeof(SKILL_CONFIG.SpeedDash))
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not root then return end

    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = config.SpeedBoost

    -- Trail Particle
    local attachment0 = Instance.new("Attachment", root)
    local attachment1 = Instance.new("Attachment", root)
    attachment0.Position = Vector3.new(0, 1, 0)
    attachment1.Position = Vector3.new(0, -1, 0)

    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 180), Color3.fromRGB(255, 255, 0))
    trail.Lifetime = 0.35
    trail.Parent = root

    task.delay(config.Duration, function()
        if humanoid and humanoid.Parent then
            humanoid.WalkSpeed = originalSpeed
        end
        trail:Destroy()
        attachment0:Destroy()
        attachment1:Destroy()
    end)
end

local function executeGravityFeather(player: Player, config: typeof(SKILL_CONFIG.GravityFeather))
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return end

    local vf = Instance.new("VectorForce")
    local att = Instance.new("Attachment", root)
    vf.Attachment0 = att
    -- Memberikan gaya angkat ke atas (meringankan gravitasi 55%)
    vf.Force = Vector3.new(0, workspace.Gravity * root.AssemblyMass * config.Buoyancy, 0)
    vf.RelativeTo = Enum.ActuatorRelativeTo.World
    vf.Parent = root

    -- Visual Glowing Sparkles
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255))
    pe.Size = NumberSequence.new(0.4, 0)
    pe.Rate = 20
    pe.Lifetime = NumberRange.new(0.6, 1.2)
    pe.Parent = att

    task.delay(config.Duration, function()
        vf:Destroy()
        att:Destroy()
    end)
end

useSkillRemote.OnServerEvent:Connect(function(player: Player, skillId: string)
    local config = SKILL_CONFIG[skillId]
    if not config then return end

    local userId = player.UserId
    if not playerCooldowns[userId] then
        playerCooldowns[userId] = {}
    end

    local now = os.clock()
    local lastUsed = playerCooldowns[userId][skillId] or 0

    if now - lastUsed < config.Cooldown then
        -- Masih cooldown!
        local remaining = math.ceil(config.Cooldown - (now - lastUsed))
        skillFeedbackRemote:FireClient(player, skillId, false, remaining)
        return
    end

    -- Set Cooldown
    playerCooldowns[userId][skillId] = now
    skillFeedbackRemote:FireClient(player, skillId, true, config.Cooldown)

    if skillId == "ForcePush" then
        executeForcePush(player, config)
    elseif skillId == "SpeedDash" then
        executeSpeedDash(player, config)
    elseif skillId == "GravityFeather" then
        executeGravityFeather(player, config)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player.UserId] = nil
end)

print(">> [SUKSES] SkillServerHandler (Aspek 3: Tactical Skills) Berjalan! <<")


]======])

-- === ShopServerHandler ===
inject("ShopServerHandler", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: SHOP SERVER HANDLER ★
-- Server Script: Validasi Transaksi Koin & Pembelian Perk / Skill
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
if not shopRemote then
    shopRemote = Instance.new("RemoteFunction")
    shopRemote.Name = "ShopRemote"
    shopRemote.Parent = ReplicatedStorage
end

local PERK_CATALOG = {
    ["ForcePush"] = {
        Name = "Force Push (Dorong Lawan)",
        Price = 5,
        Description = "Mendorong pemain di sekitar sejauh 15 studs!"
    },
    ["SpeedDash"] = {
        Name = "Speed Dash (Lari Kilat)",
        Price = 3,
        Description = "Meningkatkan kecepatan lari 2x lipat selama 5 detik!"
    },
    ["GravityFeather"] = {
        Name = "Gravity Feather (Bulu Gravitasi)",
        Price = 4,
        Description = "Lompat lebih tinggi dan melayang pelan saat jatuh!"
    }
}

local function grantPerk(player: Player, perkId: string): (boolean, string)
    local char = player.Character
    if not char then
        return false, "Karakter belum spawn!"
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "Humanoid tidak ditemukan!"
    end

    if perkId == "ForcePush" then
        -- Berikan Tool Force Push ke Backpack
        local backpack = player:FindFirstChild("Backpack")
        if backpack and not backpack:FindFirstChild("Force Push") and not char:FindFirstChild("Force Push") then
            local tool = Instance.new("Tool")
            tool.Name = "Force Push"
            tool.RequiresHandle = false
            tool.CanBeDropped = false

            tool.Activated:Connect(function()
                local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if not root then return end

                local PUSH_RADIUS = 15
                local PUSH_FORCE = 60

                for _, otherPlayer in ipairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                        if otherRoot then
                            local dist = (otherRoot.Position - root.Position).Magnitude
                            if dist <= PUSH_RADIUS then
                                local pushDir = (otherRoot.Position - root.Position).Unit
                                pushDir = Vector3.new(pushDir.X, 0.4, pushDir.Z).Unit
                                otherRoot:ApplyImpulse(pushDir * PUSH_FORCE * otherRoot.AssemblyMass)
                            end
                        end
                    end
                end
            end)

            tool.Parent = backpack
            return true, "Tool Force Push berhasil didapatkan!"
        else
            return false, "Kamu sudah memiliki Force Push!"
        end

    elseif perkId == "SpeedDash" then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 32
        task.delay(5, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
        end)
        return true, "Speed Dash aktif selama 5 detik!"

    elseif perkId == "GravityFeather" then
        local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if root then
            local bodyForce = Instance.new("VectorForce")
            local attachment = Instance.new("Attachment", root)
            bodyForce.Attachment0 = attachment
            bodyForce.Force = Vector3.new(0, workspace.Gravity * root.AssemblyMass * 0.4, 0)
            bodyForce.RelativeTo = Enum.ActuatorRelativeTo.World
            bodyForce.Parent = root

            task.delay(10, function()
                bodyForce:Destroy()
                attachment:Destroy()
            end)
            return true, "Gravity Feather aktif selama 10 detik!"
        end
    end

    return false, "Perk tidak dikenal"
end

shopRemote.OnServerInvoke = function(player: Player, perkId: string)
    local perk = PERK_CATALOG[perkId]
    if not perk then
        return {Success = false, Message = "Perk tidak ditemukan di katalog!", NewBalance = 0}
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return {Success = false, Message = "Leaderstats belum dimuat!", NewBalance = 0}
    end

    local coinsStat = leaderstats:FindFirstChild("Coins") :: IntValue?
    if not coinsStat then
        return {Success = false, Message = "Data koin tidak ditemukan!", NewBalance = 0}
    end

    if coinsStat.Value < perk.Price then
        return {
            Success = false,
            Message = string.format("Koin tidak cukup! Butuh %d koin, kamu punya %d.", perk.Price, coinsStat.Value),
            NewBalance = coinsStat.Value
        }
    end

    local granted, grantMsg = grantPerk(player, perkId)
    if granted then
        coinsStat.Value -= perk.Price
        return {
            Success = true,
            Message = string.format("Sukses membeli %s! Sisa koin: %d", perk.Name, coinsStat.Value),
            NewBalance = coinsStat.Value
        }
    else
        return {
            Success = false,
            Message = grantMsg,
            NewBalance = coinsStat.Value
        }
    end
end

print(">> [SUKSES] ShopServerHandler Resmi Berjalan! <<")


]======])

-- === VIPPassHandler ===
inject("VIPPassHandler", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: IMPERIAL VIP GATE & PASS HANDLER ★
-- Server Script: Aspek 4 - Verifikasi Akses Game Pass VIP (2064678688)
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local VIP_GAMEPASS_ID = 2064678688
local DEVELOPER_NAMES = {["Axlytic0"] = true}

local arena = workspace:WaitForChild("DilemmaArena")
local colosseum = arena:WaitForChild("ColosseumStructure")
local vipBox = colosseum:WaitForChild("ImperialVIPBox")
local vipGate = vipBox:WaitForChild("VIPGateSensor") :: Part

local debounceList: {[number]: boolean} = {}

local function checkVIPAccess(player: Player): boolean
    -- 1. Developer Bypass
    if DEVELOPER_NAMES[player.Name] then
        return true
    end

    -- 2. Game Pass Check via MarketplaceService
    local success, ownsPass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
    end)

    if success and ownsPass then
        return true
    end

    return false
end

local function onGateTouched(hit: BasePart)
    local char = hit.Parent
    if not char then return end

    local player = Players:GetPlayerFromCharacter(char)
    if not player then return end

    local userId = player.UserId
    if debounceList[userId] then return end
    debounceList[userId] = true

    task.delay(2, function()
        debounceList[userId] = nil
    end)

    local isVIP = checkVIPAccess(player)
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?

    if isVIP then
        print(string.format(">> [VIP] Akses Diterima untuk %s! Selamat datang di Imperial VIP Lounge! <<", player.Name))
        -- Efek Visual Pintu Terbuka Hijau
        vipGate.Color = Color3.fromRGB(0, 255, 127)
        task.delay(1.5, function()
            vipGate.Color = Color3.fromRGB(255, 215, 0)
        end)
    else
        -- Dorong Mundur Sedikit Keluar Gerbang
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, 5, -25)
        end

        print(string.format(">> [VIP] Pemain %s bukan VIP, memunculkan prompt beli pass %d <<", player.Name, VIP_GAMEPASS_ID))
        pcall(function()
            MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID)
        end)
    end
end

vipGate.Touched:Connect(onGateTouched)

print(">> [SUKSES] VIPPassHandler Imperial Gate Resmi Aktif! <<")

]======])

return 'Batch Injected Successfully'