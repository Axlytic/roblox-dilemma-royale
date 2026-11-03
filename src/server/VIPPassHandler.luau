--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: VIP SULTAN PASS & PORTAL HANDLER ★
-- Server Script: Game Pass Verification (ID: 2064678688) & Teleporter
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local VIP_GAMEPASS_ID = 2064678688
local DEVELOPER_NAMES = {["Axlytic0"] = true}

local arena = workspace:WaitForChild("DilemmaArena")
local vipPad = arena:WaitForChild("VIPPortalPad")
local vipLounge = arena:WaitForChild("VIPLounge")

local VIP_LOUNGE_DESTINATION = Vector3.new(0, 95, 0)

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

local function onVIPPADTouched(hit: BasePart)
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

    if isVIP then
        local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if root then
            root.CFrame = CFrame.new(VIP_LOUNGE_DESTINATION)
            print(string.format(">> [VIP] Pemain VIP %s (%s) diteleportasi ke Sky Lounge! <<", player.Name, DEVELOPER_NAMES[player.Name] and "DEVELOPER" or "SULTAN"))
        end
    else
        -- Tampilkan Prompt Beli Game Pass
        print(string.format(">> [VIP] Pemain %s bukan VIP, memunculkan prompt beli pass %d <<", player.Name, VIP_GAMEPASS_ID))
        pcall(function()
            MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID)
        end)
    end
end

vipPad.Touched:Connect(onVIPPADTouched)

print(">> [SUKSES] VIPPassHandler Resmi Berjalan dengan ID: 2064678688! <<")

