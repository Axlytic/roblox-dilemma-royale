--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: COLOSSEUM STADIUM & VIP BUILDER ★
-- Server Script: Aspek 4 - Redesain Arsitektur Colosseum & VIP Relocation
-- ============================================================

local Workspace = game:GetService("Workspace")

local arenaFolder = Workspace:FindFirstChild("DilemmaArena")
if not arenaFolder then
    arenaFolder = Instance.new("Folder")
    arenaFolder.Name = "DilemmaArena"
    arenaFolder.Parent = Workspace
end

-- 1. Bersihkan VIP lama yang terpencil di awan jika ada
local oldVIP = arenaFolder:FindFirstChild("VIPLounge")
if oldVIP then
    oldVIP:Destroy()
end

local colosseumFolder = arenaFolder:FindFirstChild("ColosseumStructure")
if not colosseumFolder then
    colosseumFolder = Instance.new("Folder")
    colosseumFolder.Name = "ColosseumStructure"
    colosseumFolder.Parent = arenaFolder
end

local function createPart(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, parent: Instance): Part
    local existing = parent:FindFirstChild(name) :: Part?
    if existing and existing:IsA("Part") then
        existing.Size = size
        existing.CFrame = cf
        existing.Color = color
        existing.Material = material
        return existing
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cf
    part.Color = color
    part.Material = material
    part.Anchored = true
    part.CanCollide = true
    part.Parent = parent
    return part
end

-- A. TRIBUN OBSERVASI MELINGKAR (SPECTATOR BALCONY - Y = 60)
-- 1. Tribun Utama (Lobby Spectator Deck)
local mainDeck = createPart(
    "SpectatorDeck_Main",
    Vector3.new(70, 3, 30),
    CFrame.new(0, 59, 68),
    Color3.fromRGB(30, 32, 40),
    Enum.Material.Concrete,
    colosseumFolder
)

-- 2. Sayap Kiri Tribun (West Wing)
local westWing = createPart(
    "SpectatorDeck_West",
    Vector3.new(30, 3, 50),
    CFrame.new(-48, 59, 35) * CFrame.Angles(0, math.rad(25), 0),
    Color3.fromRGB(35, 37, 45),
    Enum.Material.Concrete,
    colosseumFolder
)

-- 3. Sayap Kanan Tribun (East Wing)
local eastWing = createPart(
    "SpectatorDeck_East",
    Vector3.new(30, 3, 50),
    CFrame.new(48, 59, 35) * CFrame.Angles(0, math.rad(-25), 0),
    Color3.fromRGB(35, 37, 45),
    Enum.Material.Concrete,
    colosseumFolder
)

-- B. PAGAR KACA TRANSPARAN SPECTATOR (Menghadap langsung ke panggung arena!)
local frontGlassRailing = createPart(
    "SpectatorGlassRailing",
    Vector3.new(70, 4.5, 1),
    CFrame.new(0, 62.5, 53),
    Color3.fromRGB(0, 200, 255),
    Enum.Material.Glass,
    colosseumFolder
)
frontGlassRailing.Transparency = 0.65

-- C. JEMBATAN AKSES ARENA (Menghubungkan Lobi ke Panggung Utama)
local entranceBridge = createPart(
    "ColosseumEntranceBridge",
    Vector3.new(12, 2, 26),
    CFrame.new(0, 54.5, 38) * CFrame.Angles(math.rad(-18), 0, 0),
    Color3.fromRGB(50, 55, 65),
    Enum.Material.Metal,
    colosseumFolder
)

-- D. THE IMPERIAL VIP BOX (Tahta Kaisar Menatap ke Tengah Panggung)
local vipBoxFolder = colosseumFolder:FindFirstChild("ImperialVIPBox")
if not vipBoxFolder then
    vipBoxFolder = Instance.new("Folder")
    vipBoxFolder.Name = "ImperialVIPBox"
    vipBoxFolder.Parent = colosseumFolder
end

-- Lantai Panggung VVIP (Sedikit lebih tinggi di tengah tribun, Y = 61.5)
local vipBase = createPart(
    "VIPBalconyFloor",
    Vector3.new(24, 2, 18),
    CFrame.new(0, 61, 74),
    Color3.fromRGB(20, 20, 25),
    Enum.Material.Marble,
    vipBoxFolder
)

-- Karpet Merah Megah di VIP Box
local vipCarpet = createPart(
    "VIPRedCarpet",
    Vector3.new(8, 0.4, 18),
    CFrame.new(0, 62.1, 74),
    Color3.fromRGB(180, 20, 30),
    Enum.Material.Fabric,
    vipBoxFolder
)

-- Tahta Emas Kaisar (Throne Seat)
local throneSeat = vipBoxFolder:FindFirstChild("GoldenThrone") :: Seat?
if not throneSeat then
    throneSeat = Instance.new("Seat")
    throneSeat.Name = "GoldenThrone"
    throneSeat.Size = Vector3.new(4, 2, 4)
    throneSeat.CFrame = CFrame.new(0, 63, 79)
    throneSeat.Color = Color3.fromRGB(255, 215, 0)
    throneSeat.Material = Enum.Material.Neon
    throneSeat.Anchored = true
    throneSeat.Parent = vipBoxFolder

    -- Sandaran Tahta
    local backrest = createPart(
        "ThroneBackrest",
        Vector3.new(4, 6, 1),
        CFrame.new(0, 66.5, 81),
        Color3.fromRGB(218, 165, 32),
        Enum.Material.Marble,
        vipBoxFolder
    )

    -- Mahkota Neon Tahta
    local crown = createPart(
        "ThroneCrown",
        Vector3.new(2, 2, 1.2),
        CFrame.new(0, 70, 81),
        Color3.fromRGB(255, 230, 0),
        Enum.Material.Neon,
        vipBoxFolder
    )
end

-- Pilar Emas Pembatas VVIP
local leftPillar = createPart("VIPPillarLeft", Vector3.new(2, 12, 2), CFrame.new(-11, 67, 66), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, vipBoxFolder)
local rightPillar = createPart("VIPPillarRight", Vector3.new(2, 12, 2), CFrame.new(11, 67, 66), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, vipBoxFolder)

-- Pintu Laser / Portal Sensor Masuk VVIP
local vipGateSensor = vipBoxFolder:FindFirstChild("VIPGateSensor") :: Part?
if not vipGateSensor then
    vipGateSensor = Instance.new("Part")
    vipGateSensor.Name = "VIPGateSensor"
    vipGateSensor.Size = Vector3.new(8, 8, 1)
    vipGateSensor.CFrame = CFrame.new(0, 65, 65)
    vipGateSensor.Color = Color3.fromRGB(255, 215, 0)
    vipGateSensor.Material = Enum.Material.ForceField
    vipGateSensor.Transparency = 0.5
    vipGateSensor.CanCollide = false
    vipGateSensor.Anchored = true
    vipGateSensor.Parent = vipBoxFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = vipGateSensor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "👑 IMPERIAL VIP LOUNGE 👑\n[ HANYA SULTAN & DEVELOPER ]"
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = bb
end

-- Pindahkan ArenaSpawn ke Tribun Spectator Lobi (Y = 62)
local arenaSpawn = arenaFolder:FindFirstChild("ArenaSpawn") :: SpawnLocation?
if arenaSpawn then
    arenaSpawn.CFrame = CFrame.new(0, 62, 70)
end

print(">> [SUKSES] ColosseumBuilder (Aspek 4: Colosseum & Imperial VIP) Selesai! <<")
