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

local arena = workspace:WaitForChild("DilemmaArena", 15) :: Folder?
local colosseum = arena and arena:WaitForChild("ColosseumStructure", 15) :: Folder?

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

if colosseum then
	local function wireGate(vipBox: Instance)
		local vipGate = vipBox:WaitForChild("VIPGateSensor", 10) :: Part?
		if vipGate then
			vipGate.Touched:Connect(onGateTouched)
			print(">> [VIP] Gate Sensor terhubung! <<")
		end
	end

	local cur = colosseum:FindFirstChild("ImperialVIPBox")
	if cur then wireGate(cur) end
	colosseum.ChildAdded:Connect(function(c)
		if c.Name == "ImperialVIPBox" then wireGate(c) end
	end)
end

print(">> [SUKSES] VIPPassHandler Imperial Gate Resmi Aktif! <<")

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

local lastSavedStats: { [number]: number } = {}
local function savePlayerStats(player: Player)
    if not PlayerDataStore then return end
    local now = os.clock()
    if lastSavedStats[player.UserId] and (now - lastSavedStats[player.UserId]) < 4 then
        return
    end
    lastSavedStats[player.UserId] = now
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

return 'OK: VIPPassHandler, ShopServerHandler, StatsServerHandler'