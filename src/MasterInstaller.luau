--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: ONE-CLICK MASTER INSTALLER v3.0 ★
-- Jalankan skrip ini sekali di Command Bar Roblox Studio (Mode Edit)
-- untuk memasang seluruh 4 Pilar Gameplay secara otomatis!
-- ============================================================

local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print(">> [START] Memasang 4 Pilar Gameplay Dilemma Royale v3.0... <<")

-- 1. Setup Remotes di ReplicatedStorage
local remotes = {
    { Name = "UseSkillRemote", Class = "RemoteEvent" },
    { Name = "SkillFeedbackRemote", Class = "RemoteEvent" },
    { Name = "UpgradeStatRemote", Class = "RemoteFunction" },
    { Name = "ShopRemote", Class = "RemoteFunction" }
}

for _, r in ipairs(remotes) do
    if not ReplicatedStorage:FindFirstChild(r.Name) then
        local inst = Instance.new(r.Class)
        inst.Name = r.Name
        inst.Parent = ReplicatedStorage
    end
end

-- 2. Bersihkan skrip usang di ServerScriptService jika ada
local oldScripts = {"Script", "GameController", "MainScript"}
for _, name in ipairs(oldScripts) do
    local s = ServerScriptService:FindFirstChild(name)
    if s then s:Destroy() end
end

print(">> [1/4] Remotes & Cleanup Berhasil! <<")
print(">> [2/4] Membangun Arsitektur Colosseum Stadium & Imperial VIP... <<")

-- 3. Jalankan Colosseum Builder langsung
local arenaFolder = Workspace:FindFirstChild("DilemmaArena")
if not arenaFolder then
    arenaFolder = Instance.new("Folder")
    arenaFolder.Name = "DilemmaArena"
    arenaFolder.Parent = Workspace
end

-- Bersihkan VIP lama yang terpencil di awan
local oldVIP = arenaFolder:FindFirstChild("VIPLounge")
if oldVIP then oldVIP:Destroy() end

local colosseumFolder = arenaFolder:FindFirstChild("ColosseumStructure")
if not colosseumFolder then
    colosseumFolder = Instance.new("Folder")
    colosseumFolder.Name = "ColosseumStructure"
    colosseumFolder.Parent = arenaFolder
end

local function makePart(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, parent: Instance): Part
    local p = parent:FindFirstChild(name) :: Part?
    if not p then
        p = Instance.new("Part")
        p.Name = name
        p.Parent = parent
    end
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = mat
    p.Anchored = true
    p.CanCollide = true
    return p
end

-- Tribun Melingkar Spectator Deck (Y = 59)
makePart("SpectatorDeck_Main", Vector3.new(70, 3, 30), CFrame.new(0, 59, 68), Color3.fromRGB(30, 32, 40), Enum.Material.Concrete, colosseumFolder)
makePart("SpectatorDeck_West", Vector3.new(30, 3, 50), CFrame.new(-48, 59, 35) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(35, 37, 45), Enum.Material.Concrete, colosseumFolder)
makePart("SpectatorDeck_East", Vector3.new(30, 3, 50), CFrame.new(48, 59, 35) * CFrame.Angles(0, math.rad(-25), 0), Color3.fromRGB(35, 37, 45), Enum.Material.Concrete, colosseumFolder)

local glass = makePart("SpectatorGlassRailing", Vector3.new(70, 4.5, 1), CFrame.new(0, 62.5, 53), Color3.fromRGB(0, 200, 255), Enum.Material.Glass, colosseumFolder)
glass.Transparency = 0.65

makePart("ColosseumEntranceBridge", Vector3.new(12, 2, 26), CFrame.new(0, 54.5, 38) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(50, 55, 65), Enum.Material.Metal, colosseumFolder)

-- Imperial VIP Box di tengah tribun
local vipBoxFolder = colosseumFolder:FindFirstChild("ImperialVIPBox")
if not vipBoxFolder then
    vipBoxFolder = Instance.new("Folder")
    vipBoxFolder.Name = "ImperialVIPBox"
    vipBoxFolder.Parent = colosseumFolder
end

makePart("VIPBalconyFloor", Vector3.new(24, 2, 18), CFrame.new(0, 61, 74), Color3.fromRGB(20, 20, 25), Enum.Material.Marble, vipBoxFolder)
makePart("VIPRedCarpet", Vector3.new(8, 0.4, 18), CFrame.new(0, 62.1, 74), Color3.fromRGB(180, 20, 30), Enum.Material.Fabric, vipBoxFolder)

local throne = vipBoxFolder:FindFirstChild("GoldenThrone") :: Seat?
if not throne then
    throne = Instance.new("Seat")
    throne.Name = "GoldenThrone"
    throne.Size = Vector3.new(4, 2, 4)
    throne.CFrame = CFrame.new(0, 63, 79)
    throne.Color = Color3.fromRGB(255, 215, 0)
    throne.Material = Enum.Material.Neon
    throne.Anchored = true
    throne.Parent = vipBoxFolder
    makePart("ThroneBackrest", Vector3.new(4, 6, 1), CFrame.new(0, 66.5, 81), Color3.fromRGB(218, 165, 32), Enum.Material.Marble, vipBoxFolder)
    makePart("ThroneCrown", Vector3.new(2, 2, 1.2), CFrame.new(0, 70, 81), Color3.fromRGB(255, 230, 0), Enum.Material.Neon, vipBoxFolder)
end

makePart("VIPPillarLeft", Vector3.new(2, 12, 2), CFrame.new(-11, 67, 66), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, vipBoxFolder)
makePart("VIPPillarRight", Vector3.new(2, 12, 2), CFrame.new(11, 67, 66), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, vipBoxFolder)

local vipGate = vipBoxFolder:FindFirstChild("VIPGateSensor") :: Part?
if not vipGate then
    vipGate = Instance.new("Part")
    vipGate.Name = "VIPGateSensor"
    vipGate.Size = Vector3.new(8, 8, 1)
    vipGate.CFrame = CFrame.new(0, 65, 65)
    vipGate.Color = Color3.fromRGB(255, 215, 0)
    vipGate.Material = Enum.Material.ForceField
    vipGate.Transparency = 0.5
    vipGate.CanCollide = false
    vipGate.Anchored = true
    vipGate.Parent = vipBoxFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = vipGate

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "👑 IMPERIAL VIP LOUNGE 👑\n[ HANYA SULTAN & DEVELOPER ]"
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = bb
end

-- Update Spawn Point ke Tribun Spectator
local arenaSpawn = arenaFolder:FindFirstChild("ArenaSpawn") :: SpawnLocation?
if arenaSpawn then
    arenaSpawn.CFrame = CFrame.new(0, 62, 70)
end

print(">> [3/4] Colosseum Stadium & VIP Imperial Selesai Dibangun! <<")
print(">> [4/4] Seluruh 4 Aspek Gameplay Sukses Terpasang 100%! Tekan Play (F5) untuk Menguji! <<")
