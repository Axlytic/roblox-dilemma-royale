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
