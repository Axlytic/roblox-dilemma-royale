--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: MULTI-BIOME COLOSSEUM BUILDER v2.0 ★
-- v2.0 Additions:
--   • 4 Biomes: Imperial, Magma Inferno, Glaciers Ice, Cyberpunk Void
--   • BuildColosseum(biomeId) function
--   • Randomly selects biome each round via BindableFunction
--   • Calls GraphicsOverhaulInstaller ApplyBiomeLighting
-- ============================================================

local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

-- =========================================================
-- PART HELPERS
-- =========================================================
local function createPart(
	name:     string,
	size:     Vector3,
	cf:       CFrame,
	color:    Color3,
	material: Enum.Material,
	parent:   Instance,
	transparency: number?,
	canCollide: boolean?
): Part
	local existing = parent:FindFirstChild(name) :: Part?
	if existing and existing:IsA("Part") then
		existing.Size         = size
		existing.CFrame       = cf
		existing.Color        = color
		existing.Material     = material
		existing.Transparency = transparency or 0
		existing.CanCollide   = canCollide ~= false
		return existing
	end
	local part = Instance.new("Part")
	part.Name         = name
	part.Size         = size
	part.CFrame       = cf
	part.Color        = color
	part.Material     = material
	part.Anchored     = true
	part.CanCollide   = canCollide ~= false
	part.Transparency = transparency or 0
	part.Parent       = parent
	return part
end

local function addPointLight(part: BasePart, color: Color3, brightness: number, range: number)
	local pl = part:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
	pl.Color      = color
	pl.Brightness = brightness
	pl.Range      = range
	pl.Shadows    = true
	pl.Parent     = part
end

local function addParticles(part: BasePart, color: ColorSequence, rate: number, speed: number)
	local att = part:FindFirstChildOfClass("Attachment") or Instance.new("Attachment")
	att.Parent = part
	local pe = att:FindFirstChildOfClass("ParticleEmitter") or Instance.new("ParticleEmitter")
	pe.Color          = color
	pe.LightEmission  = 0.8
	pe.LightInfluence = 0
	pe.Size           = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Speed          = NumberRange.new(speed * 0.5, speed)
	pe.Rate           = rate
	pe.Lifetime       = NumberRange.new(1, 2)
	pe.SpreadAngle    = Vector2.new(20, 20)
	pe.Parent         = att
end

-- =========================================================
-- BIOME DEFINITIONS
-- =========================================================
type BiomeConfig = {
	id:            number,
	name:          string,
	-- Colors
	floorColor:    Color3,
	wallColor:     Color3,
	pillarColor:   Color3,
	accentColor:   Color3,
	trimColor:     Color3,
	-- Materials
	floorMat:      Enum.Material,
	wallMat:       Enum.Material,
	pillarMat:     Enum.Material,
	-- Specials
	floorNeon:     boolean,
	addFire:       boolean,
	addSnow:       boolean,
	addNeonGrid:   boolean,
	lightColor:    Color3,
	lightBrightness: number,
}

local BIOMES: { BiomeConfig } = {
	-- ── BIOME 1: IMPERIAL (default warm marble/gold) ──
	{
		id = 1, name = "Imperial Colosseum",
		floorColor    = Color3.fromRGB(240, 230, 210),
		wallColor     = Color3.fromRGB(220, 210, 190),
		pillarColor   = Color3.fromRGB(230, 220, 200),
		accentColor   = Color3.fromRGB(255, 180, 0),
		trimColor     = Color3.fromRGB(255, 215, 0),
		floorMat      = Enum.Material.Marble,
		wallMat       = Enum.Material.SmoothPlastic,
		pillarMat     = Enum.Material.Marble,
		floorNeon     = false,
		addFire       = true,
		addSnow       = false,
		addNeonGrid   = false,
		lightColor    = Color3.fromRGB(255, 180, 60),
		lightBrightness = 2.0,
	},
	-- ── BIOME 2: MAGMA INFERNO ──
	{
		id = 2, name = "Magma Inferno",
		floorColor    = Color3.fromRGB(40, 20, 10),
		wallColor     = Color3.fromRGB(60, 25, 10),
		pillarColor   = Color3.fromRGB(80, 30, 10),
		accentColor   = Color3.fromRGB(255, 80, 0),
		trimColor     = Color3.fromRGB(255, 150, 20),
		floorMat      = Enum.Material.Basalt,
		wallMat       = Enum.Material.Basalt,
		pillarMat     = Enum.Material.SmoothPlastic,
		floorNeon     = false,
		addFire       = true,
		addSnow       = false,
		addNeonGrid   = false,
		lightColor    = Color3.fromRGB(255, 80, 20),
		lightBrightness = 3.0,
	},
	-- ── BIOME 3: GLACIERS ICE ──
	{
		id = 3, name = "Glaciers Ice",
		floorColor    = Color3.fromRGB(180, 220, 255),
		wallColor     = Color3.fromRGB(160, 200, 240),
		pillarColor   = Color3.fromRGB(200, 230, 255),
		accentColor   = Color3.fromRGB(100, 200, 255),
		trimColor     = Color3.fromRGB(220, 240, 255),
		floorMat      = Enum.Material.Ice,
		wallMat       = Enum.Material.Ice,
		pillarMat     = Enum.Material.SmoothPlastic,
		floorNeon     = false,
		addFire       = false,
		addSnow       = true,
		addNeonGrid   = false,
		lightColor    = Color3.fromRGB(150, 210, 255),
		lightBrightness = 1.5,
	},
	-- ── BIOME 4: CYBERPUNK VOID ──
	{
		id = 4, name = "Cyberpunk Void",
		floorColor    = Color3.fromRGB(10, 10, 20),
		wallColor     = Color3.fromRGB(15, 10, 30),
		pillarColor   = Color3.fromRGB(0, 180, 220),
		accentColor   = Color3.fromRGB(180, 0, 255),
		trimColor     = Color3.fromRGB(0, 220, 255),
		floorMat      = Enum.Material.SmoothPlastic,
		wallMat       = Enum.Material.SmoothPlastic,
		pillarMat     = Enum.Material.Neon,
		floorNeon     = false,
		addFire       = false,
		addSnow       = false,
		addNeonGrid   = true,
		lightColor    = Color3.fromRGB(0, 200, 255),
		lightBrightness = 2.5,
	},
}

-- =========================================================
-- FOLDER MANAGEMENT
-- =========================================================
local arenaFolder = Workspace:FindFirstChild("DilemmaArena") :: Folder?
if not arenaFolder then
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "DilemmaArena"
	arenaFolder.Parent = Workspace
end

local colosseumFolder = arenaFolder:FindFirstChild("ColosseumStructure") :: Folder?
if not colosseumFolder then
	colosseumFolder = Instance.new("Folder")
	colosseumFolder.Name = "ColosseumStructure"
	colosseumFolder.Parent = arenaFolder
end

-- =========================================================
-- CORE STRUCTURE BUILDER
-- =========================================================
local function buildColosseumStructure(B: BiomeConfig, folder: Folder)

	-- ── ARENA FLOOR ──
	local floor = createPart("ArenaFloor",
		Vector3.new(80, 2, 80),
		CFrame.new(0, 48, 0),
		B.floorColor, B.floorMat, folder
	)

	-- Neon grid overlay for Cyberpunk biome
	if B.addNeonGrid then
		for i = -4, 4 do
			createPart("GridLine_X_" .. i,
				Vector3.new(80, 0.1, 0.5),
				CFrame.new(0, 49.1, i * 10),
				B.trimColor, Enum.Material.Neon, folder
			)
			createPart("GridLine_Z_" .. i,
				Vector3.new(0.5, 0.1, 80),
				CFrame.new(i * 10, 49.1, 0),
				B.trimColor, Enum.Material.Neon, folder
			)
		end
	end

	-- ── OUTER RING WALL ──
	local wallData = {
		{ "Wall_N", Vector3.new(84, 20, 4), CFrame.new(0, 59, -42) },
		{ "Wall_S", Vector3.new(84, 20, 4), CFrame.new(0, 59,  42) },
		{ "Wall_E", Vector3.new(4, 20, 84), CFrame.new(42, 59,  0) },
		{ "Wall_W", Vector3.new(4, 20, 84), CFrame.new(-42, 59, 0) },
	}
	for _, w in wallData do
		createPart(w[1], w[2], w[3], B.wallColor, B.wallMat, folder)
	end

	-- ── SPECTATOR DECKS (glass-transparent) ──
	createPart("SpectatorDeck_Main",
		Vector3.new(70, 3, 30),
		CFrame.new(0, 59, 68),
		Color3.fromRGB(30, 32, 40), Enum.Material.Concrete, folder
	)
	createPart("SpectatorDeck_West",
		Vector3.new(30, 3, 50),
		CFrame.new(-48, 59, 35) * CFrame.Angles(0, math.rad(25), 0),
		Color3.fromRGB(35, 37, 45), Enum.Material.Concrete, folder
	)
	createPart("SpectatorDeck_East",
		Vector3.new(30, 3, 50),
		CFrame.new(48, 59, 35) * CFrame.Angles(0, math.rad(-25), 0),
		Color3.fromRGB(35, 37, 45), Enum.Material.Concrete, folder
	)
	-- Spectator glass fronts
	createPart("SpectatorGlass_Main",
		Vector3.new(70, 8, 1),
		CFrame.new(0, 56, 54),
		Color3.fromRGB(100, 180, 255), Enum.Material.Glass, folder,
		0.6
	)

	-- ── ARENA PILLARS (8 around the ring) ──
	local pillarRadius = 44
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local px    = math.cos(angle) * pillarRadius
		local pz    = math.sin(angle) * pillarRadius
		local pillar = createPart("Pillar_" .. i,
			Vector3.new(3, 24, 3),
			CFrame.new(px, 61, pz),
			B.pillarColor, B.pillarMat, folder
		)

		-- Accent trim top
		createPart("PillarCap_" .. i,
			Vector3.new(4, 2, 4),
			CFrame.new(px, 73.5, pz),
			B.trimColor, Enum.Material.SmoothPlastic, folder
		)

		-- Point lights on pillars
		addPointLight(pillar, B.lightColor, B.lightBrightness, 20)

		-- Fire particles on pillars (Imperial/Magma)
		if B.addFire then
			local torchPart = createPart("Torch_" .. i,
				Vector3.new(0.8, 2, 0.8),
				CFrame.new(px, 74.5, pz),
				B.accentColor, Enum.Material.Neon, folder
			)
			addPointLight(torchPart, B.lightColor, 3, 18)
			addParticles(torchPart,
				ColorSequence.new({ ColorSequenceKeypoint.new(0, B.accentColor), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 200)) }),
				16, 8
			)
		end

		-- Snow particles (Ice biome)
		if B.addSnow then
			local snowEmitter = createPart("SnowEmitter_" .. i,
				Vector3.new(0.5, 0.5, 0.5),
				CFrame.new(px, 80, pz),
				Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder,
				1, false
			)
			addParticles(snowEmitter,
				ColorSequence.new(Color3.fromRGB(220, 240, 255)),
				12, 2
			)
		end

		-- Neon cyber glow (Cyberpunk)
		if B.addNeonGrid then
			createPart("CyberGlow_" .. i,
				Vector3.new(0.5, 20, 0.5),
				CFrame.new(px, 61, pz),
				B.accentColor, Enum.Material.Neon, folder
			)
		end
	end

	-- ── GRAND ENTRANCE ARCH ──
	createPart("Arch_Left",
		Vector3.new(4, 16, 4),
		CFrame.new(-8, 57, -42),
		B.wallColor, B.wallMat, folder
	)
	createPart("Arch_Right",
		Vector3.new(4, 16, 4),
		CFrame.new(8, 57, -42),
		B.wallColor, B.wallMat, folder
	)
	createPart("Arch_Top",
		Vector3.new(20, 4, 4),
		CFrame.new(0, 65, -42),
		B.accentColor, Enum.Material.SmoothPlastic, folder
	)

	-- ── IMPERIAL VIP BOX (Container Model for VIPPassHandler) ──
	local vipModel = folder:FindFirstChild("ImperialVIPBox") :: Model?
	if not vipModel then
		vipModel = Instance.new("Model")
		vipModel.Name = "ImperialVIPBox"
		vipModel.Parent = folder
	end

	local vipBox = createPart("VIPBox_Platform",
		Vector3.new(28, 2, 14),
		CFrame.new(0, 68, -52),
		Color3.fromRGB(80, 70, 50), Enum.Material.Marble, vipModel
	)

	-- VIP Gate Sensor Part (Touch sensor for game pass check)
	local vipGate = createPart("VIPGateSensor",
		Vector3.new(12, 8, 2),
		CFrame.new(0, 71, -44.5),
		Color3.fromRGB(255, 215, 0), Enum.Material.Neon, vipModel,
		0.75, false
	)

	-- VIP Throne
	createPart("GoldenThrone",
		Vector3.new(4, 5, 3),
		CFrame.new(0, 70.5, -52),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, vipModel
	)
	createPart("ThroneBack",
		Vector3.new(4, 7, 1),
		CFrame.new(0, 73.5, -53.5),
		Color3.fromRGB(255, 180, 0), Enum.Material.SmoothPlastic, vipModel
	)

	-- VIP Gold railing
	for side = -1, 1, 2 do
		createPart("VIPRailing_" .. (side > 0 and "R" or "L"),
			Vector3.new(0.5, 3, 14),
			CFrame.new(side * 14, 70, -52),
			Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, vipModel
		)
	end
	createPart("VIPRailing_Front",
		Vector3.new(28, 3, 0.5),
		CFrame.new(0, 70, -45),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, vipModel
	)

	addPointLight(vipBox, Color3.fromRGB(255, 215, 80), 1.5, 18)

	createPart("RedCarpet",
		Vector3.new(6, 0.2, 14),
		CFrame.new(0, 69.1, -52),
		Color3.fromRGB(180, 20, 20), Enum.Material.SmoothPlastic, vipModel
	)

	-- ── ARENA PLATES (must exist for DilemmaServer refs) ──
	createPart("PlateRed",
		Vector3.new(35, 3, 50),
		CFrame.new(-20, 50, 0),
		Color3.fromRGB(220, 50, 50), Enum.Material.SmoothPlastic, arenaFolder
	)
	createPart("PlateBlue",
		Vector3.new(35, 3, 50),
		CFrame.new(20, 50, 0),
		Color3.fromRGB(50, 100, 220), Enum.Material.SmoothPlastic, arenaFolder
	)
	createPart("NeutralBeam",
		Vector3.new(4, 2, 50),
		CFrame.new(0, 50, 0),
		Color3.fromRGB(255, 215, 0), Enum.Material.Neon, arenaFolder
	)

	-- ── CEILING (subtle dark dome) ──
	createPart("CeilingDome",
		Vector3.new(90, 2, 90),
		CFrame.new(0, 86, 0),
		Color3.fromRGB(15, 15, 25), Enum.Material.SmoothPlastic, folder,
		0.8, false
	)

	-- ── BIOME NAME DISPLAY (small label part above arch) ──
	local signPart = createPart("BiomeSign",
		Vector3.new(20, 4, 1),
		CFrame.new(0, 70, -42),
		B.accentColor, Enum.Material.Neon, folder
	)
	local sg = Instance.new("SurfaceGui")
	sg.Face   = Enum.NormalId.Front
	sg.Parent = signPart
	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font             = Enum.Font.GothamBlack
	lbl.TextScaled       = true
	lbl.TextColor3       = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0.3
	lbl.Text             = "⚔  " .. B.name:upper() .. "  ⚔"
	lbl.Parent           = sg
end

-- =========================================================
-- PUBLIC BUILD FUNCTION
-- =========================================================
local currentBiomeId = 1

local function buildColosseum(biomeId: number)
	biomeId = math.clamp(biomeId, 1, #BIOMES)
	currentBiomeId = biomeId

	local B = BIOMES[biomeId]
	print(string.format("[ColosseumBuilder] 🏟 Building Biome %d: %s", biomeId, B.name))

	-- Clear existing structure (keep arena plates for DilemmaServer)
	for _, child in colosseumFolder:GetChildren() do
		Debris:AddItem(child, 0)
	end
	task.wait(0.1)

	buildColosseumStructure(B, colosseumFolder)

	-- Apply biome lighting via GraphicsOverhaulInstaller
	local applyLighting = ReplicatedStorage:FindFirstChild("ApplyBiomeLighting") :: BindableFunction?
	if applyLighting then
		applyLighting:Invoke(biomeId)
	end

	print(string.format("[ColosseumBuilder] ✅ Biome %d built successfully.", biomeId))
end

-- =========================================================
-- EXPOSE VIA BINDABLE FOR DilemmaServer TO CALL
-- =========================================================
local bfBuildColosseum = ReplicatedStorage:FindFirstChild("BuildColosseum") :: BindableFunction?
if not bfBuildColosseum then
	bfBuildColosseum = Instance.new("BindableFunction")
	bfBuildColosseum.Name   = "BuildColosseum"
	bfBuildColosseum.Parent = ReplicatedStorage
end
bfBuildColosseum.OnInvoke = function(biomeId: number)
	buildColosseum(biomeId)
end

-- =========================================================
-- INITIAL BUILD + BIOME ROTATION EVERY ROUND
-- =========================================================
-- Start with Biome 1 (Imperial) on game launch
buildColosseum(1)

-- Rotate biome automatically every ~90 seconds (between rounds)
task.spawn(function()
	task.wait(90)
	while true do
		local nextBiome = (currentBiomeId % #BIOMES) + 1
		buildColosseum(nextBiome)
		task.wait(90)
	end
end)

print("[ColosseumBuilder v2.0] ✅ Loaded — 4 biomes available, auto-rotation active.")
