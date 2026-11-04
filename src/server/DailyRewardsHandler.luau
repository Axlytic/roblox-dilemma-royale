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

