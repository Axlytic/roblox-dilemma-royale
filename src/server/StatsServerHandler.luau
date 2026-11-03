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
