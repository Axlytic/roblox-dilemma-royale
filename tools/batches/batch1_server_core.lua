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
Lighting.Technology         = Enum.Technology.Future   -- Highest quality renderer
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

-- === ColosseumBuilder ===
inject("ColosseumBuilder", [======[
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

	-- ── IMPERIAL VIP BOX (ALWAYS GOLD — biome accent color) ──
	local vipBox = createPart("VIPBox_Platform",
		Vector3.new(28, 2, 14),
		CFrame.new(0, 68, -52),
		Color3.fromRGB(80, 70, 50), Enum.Material.Marble, folder
	)

	-- VIP Throne
	createPart("GoldenThrone",
		Vector3.new(4, 5, 3),
		CFrame.new(0, 70.5, -52),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, folder
	)
	createPart("ThroneBack",
		Vector3.new(4, 7, 1),
		CFrame.new(0, 73.5, -53.5),
		Color3.fromRGB(255, 180, 0), Enum.Material.SmoothPlastic, folder
	)

	-- VIP Gold railing
	for side = -1, 1, 2 do
		createPart("VIPRailing_" .. (side > 0 and "R" or "L"),
			Vector3.new(0.5, 3, 14),
			CFrame.new(side * 14, 70, -52),
			Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, folder
		)
	end
	createPart("VIPRailing_Front",
		Vector3.new(28, 3, 0.5),
		CFrame.new(0, 70, -45),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, folder
	)

	-- VIP gold lighting
	addPointLight(vipBox, Color3.fromRGB(255, 215, 80), 1.5, 18)

	-- VIP red carpet
	createPart("RedCarpet",
		Vector3.new(6, 0.2, 14),
		CFrame.new(0, 69.1, -52),
		Color3.fromRGB(180, 20, 20), Enum.Material.SmoothPlastic, folder
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

]======])

-- === DilemmaServer ===
inject("DilemmaServer", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: MASTER GAME CONTROLLER v4.0 ★
-- v4.0 Additions:
--   • Sensory Panic Feedback (PanicMode RemoteEvent at T-5s)
--   • Debris:AddItem() on all fallen plates (memory clean)
--   • Greed Orb Debris cleanup on collect
--   • Win streak tracking → fires WinStreakChanged + RoundWon
--   • Integrates with OverheadTitleHandler & FavoritePromptController
-- ============================================================

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

-- =========================================================
-- SOUND SETUP (safe pcall — avoids crash if sounds missing)
-- =========================================================
local function safeGetSound(name: string): Sound?
	local ok, result = pcall(function() return SoundService:WaitForChild(name, 2) end)
	return ok and result or nil
end

local tickSfx   = safeGetSound("SFX_Tick")
local alarmSfx  = safeGetSound("SFX_Alarm")
local rumbleSfx = safeGetSound("SFX_Rumble")
local winSfx    = safeGetSound("SFX_Win")

local function playSfx(sound: Sound?)
	if sound then pcall(function() sound:Play() end) end
end

-- =========================================================
-- DATASTORE
-- =========================================================
local PlayerDataStore: DataStore?
pcall(function()
	PlayerDataStore = DataStoreService:GetDataStore("DilemmaRoyale_v1")
end)

-- =========================================================
-- ARENA REFERENCES
-- =========================================================
local arena       = workspace:WaitForChild("DilemmaArena")
local redPlate    = arena:WaitForChild("PlateRed")   :: Part
local bluePlate   = arena:WaitForChild("PlateBlue")  :: Part
local neutralBeam = arena:FindFirstChild("NeutralBeam") :: Part?
local screen      = arena:FindFirstChild("DilemmaScreen")
local titleText   : TextLabel?
local questionText: TextLabel?
local timerText   : TextLabel?

if screen then
	local sg = screen:FindFirstChild("SurfaceGui")
	if sg then
		local frame = sg:FindFirstChild("Frame")
		if frame then
			titleText    = frame:FindFirstChild("TitleText")    :: TextLabel?
			questionText = frame:FindFirstChild("QuestionText") :: TextLabel?
			timerText    = frame:FindFirstChild("TimerText")    :: TextLabel?
		end
	end
end

local function setTitle(text: string, color: Color3?)
	if titleText then
		titleText.Text = text
		titleText.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	end
end
local function setQuestion(text: string)
	if questionText then questionText.Text = text end
end
local function setTimer(text: string, color: Color3?)
	if timerText then
		timerText.Text = text
		timerText.TextColor3 = color or Color3.fromRGB(0, 255, 200)
	end
end

-- =========================================================
-- REMOTE EVENTS SETUP
-- =========================================================
local eventsFolder = ReplicatedStorage:FindFirstChild("DilemmaEvents") :: Folder?
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "DilemmaEvents"
	eventsFolder.Parent = ReplicatedStorage
end

local function getOrMakeEvent(name: string): RemoteEvent
	local ev = eventsFolder:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = eventsFolder
	end
	return ev
end

local evPanicMode        = getOrMakeEvent("PanicMode")
local evRoundWon         = getOrMakeEvent("RoundWon")
local evWinStreakChanged  = getOrMakeEvent("WinStreakChanged")

-- BindableEvents for internal server communication
local function getOrMakeBindable(name: string): BindableEvent
	local be = eventsFolder:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = eventsFolder
	end
	return be
end

local beAddCoins       = getOrMakeBindable("ServerAddCoins")
local beGrantCosmetic  = getOrMakeBindable("ServerGrantCosmetic")
local beGrantTitle     = getOrMakeBindable("ServerGrantTitle")

-- =========================================================
-- WIN STREAK TRACKING
-- =========================================================
local playerWins:    { [number]: number } = {}  -- userId → total wins
local playerStreaks: { [number]: number } = {}  -- userId → consecutive streak
local playerCosmetics: { [number]: { [string]: boolean } } = {}

-- =========================================================
-- RANK CALCULATION
-- =========================================================
local function getRankTitle(wins: number): string
	if wins >= 51 then return "Untouchable"
	elseif wins >= 31 then return "Tactician"
	elseif wins >= 16 then return "Colosseum Knight"
	elseif wins >= 6  then return "Mind Master"
	else return "Rookie Survivor"
	end
end

-- =========================================================
-- CONSTANTS
-- =========================================================
local DEFAULT_SIZE         = Vector3.new(35, 3, 50)
local DEFAULT_RED_POS      = Vector3.new(-20, 50, 0)
local DEFAULT_BLUE_POS     = Vector3.new(20, 50, 0)
local COLOSSEUM_SPAWN_POS  = Vector3.new(0, 62, 70)
local VOID_THRESHOLD       = 20   -- Y < 20 → teleport back
local PANIC_TRIGGER_SEC    = 5    -- Start panic at T-5 seconds

local Dilemmas = {
	{ Cat = "DILEMA SOSIAL",    Text = "PILIH: WiFi Super Kencang (MERAH) vs Makan Enak Gratis (BIRU)" },
	{ Cat = "SUPERPOWER",       Text = "SUPERPOWER: Bisa Terbang (MERAH) vs Bisa Menghilang (BIRU)" },
	{ Cat = "TIME TRAVEL",      Text = "WAKTU: Pergi ke Masa Lalu (MERAH) vs Pergi ke Masa Depan (BIRU)" },
	{ Cat = "GAMING",           Text = "GAMING: Jago Semua Game (MERAH) vs Punya PC Sultan 500 Juta (BIRU)" },
	{ Cat = "KARIR",            Text = "KARIR: Sukses di Usia Muda (MERAH) vs Santai Menikmati Hidup (BIRU)" },
	{ Cat = "TAKTIKAL SURVIVAL",Text = "RISIKO: Kubu MERAH Lebih Luas vs Kubu BIRU Bonus +20 Koin!" },
	{ Cat = "GREED DILEMMA",    Text = "AMBISI: Selamat di Kubu Minoritas vs Rebut GREED ORB di Balok Netral!" },
	{ Cat = "PSIKOLOGI",        Text = "TRUST: Bagi Hadiah Rata (MERAH) vs Ambil Semua Sendirian (BIRU)" },
	{ Cat = "SAINS",            Text = "EKSPLORASI: Jejaki Luar Angkasa (MERAH) vs Selami Dasar Laut (BIRU)" },
	{ Cat = "KEKUATAN",         Text = "POWER: Super Strength (MERAH) vs Mind Control (BIRU)" },
}

local Modifiers = {
	{ Name = "LANTAI ES LICIN!",  Desc = "Gesekan 0%! Sangat licin!", Type = "Ice" },
	{ Name = "GRAVITASI BULAN!",  Desc = "Semua orang melayang!",      Type = "Gravity" },
	{ Name = "LANTAI MENGECIL!",  Desc = "Lantai menyusut tiap detik!",Type = "Shrink" },
	{ Name = "STANDAR ARENA",     Desc = "Kondisi normal.",             Type = "Normal" },
}

-- =========================================================
-- HEADCOUNT SENSOR
-- =========================================================
local function getPlateHeadcount(plate: Part): number
	local count = 0
	local minX = plate.Position.X - (plate.Size.X / 2)
	local maxX = plate.Position.X + (plate.Size.X / 2)
	local minZ = plate.Position.Z - (plate.Size.Z / 2)
	local maxZ = plate.Position.Z + (plate.Size.Z / 2)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local pos = hrp.Position
				if pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ
					and pos.Y > 45 and pos.Y < 70 then
					count += 1
				end
			end
		end
	end
	return count
end

local function isOnNeutralBeam(char: Model): boolean
	if not neutralBeam then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end
	local pos = hrp.Position
	local nb = neutralBeam
	return pos.X >= nb.Position.X - nb.Size.X/2 - 0.5
		and pos.X <= nb.Position.X + nb.Size.X/2 + 0.5
		and pos.Z >= nb.Position.Z - nb.Size.Z/2
		and pos.Z <= nb.Position.Z + nb.Size.Z/2
		and pos.Y > 48 and pos.Y < 60
end

local function getLuckMultiplier(player: Player): number
	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		local luck = stats:FindFirstChild("Luck") :: IntValue?
		if luck and luck.Value > 1 then
			if math.random(1, 100) <= luck.Value * 8 then
				return 1.5
			end
		end
	end
	return 1.0
end

-- =========================================================
-- PLAYER SETUP
-- =========================================================
local function setupPlayer(player: Player)
	-- Leaderstats
	local ls = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local wins = ls:FindFirstChild("Wins") :: IntValue? or Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = ls

	local coins = ls:FindFirstChild("Coins") :: IntValue? or Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = ls

	-- Load from DataStore
	if PlayerDataStore then
		local ok, data = pcall(PlayerDataStore.GetAsync, PlayerDataStore, "Player_" .. player.UserId)
		if ok and data then
			wins.Value  = data.Wins  or 0
			coins.Value = data.Coins or 0
			playerStreaks[player.UserId] = data.Streak or 0
		end
	end

	playerWins[player.UserId]    = wins.Value
	playerStreaks[player.UserId] = playerStreaks[player.UserId] or 0
	playerCosmetics[player.UserId] = {}
end

local function savePlayer(player: Player)
	if not PlayerDataStore then return end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local wins  = ls:FindFirstChild("Wins")  :: IntValue?
	local coins = ls:FindFirstChild("Coins") :: IntValue?
	pcall(PlayerDataStore.SetAsync, PlayerDataStore, "Player_" .. player.UserId, {
		Wins   = wins  and wins.Value  or 0,
		Coins  = coins and coins.Value or 0,
		Streak = playerStreaks[player.UserId] or 0,
	})
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(savePlayer)
for _, p in Players:GetPlayers() do setupPlayer(p) end

-- BindableEvent handlers
beAddCoins.Event:Connect(function(player: Player, amount: number)
	local coins = player:FindFirstChild("leaderstats") and
		player.leaderstats:FindFirstChild("Coins") :: IntValue?
	if coins then
		coins.Value = coins.Value + math.floor(amount)
	end
end)

-- =========================================================
-- VOID PROTECTOR
-- =========================================================
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in Players:GetPlayers() do
			local c = p.Character
			if c then
				local hrp = c:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp and hrp.Position.Y < VOID_THRESHOLD then
					hrp.CFrame = CFrame.new(COLOSSEUM_SPAWN_POS)
				end
			end
		end
	end
end)

-- =========================================================
-- GREED ORB
-- =========================================================
local currentGreedOrb: Part? = nil

local function spawnGreedOrb()
	if currentGreedOrb then
		Debris:AddItem(currentGreedOrb, 0)
		currentGreedOrb = nil
	end

	local orb = Instance.new("Part")
	orb.Name        = "GreedOrb"
	orb.Shape       = Enum.PartType.Ball
	orb.Size        = Vector3.new(2.5, 2.5, 2.5)
	orb.Position    = Vector3.new(0, 53.5, math.random(-15, 15))
	orb.Anchored    = true
	orb.CanCollide  = false
	orb.Material    = Enum.Material.Neon
	orb.Color       = Color3.fromRGB(255, 215, 0)
	orb.Parent      = arena

	local att = Instance.new("Attachment", orb)
	local pe  = Instance.new("ParticleEmitter")
	pe.Color    = ColorSequence.new(Color3.fromRGB(255, 230, 50))
	pe.Size     = NumberSequence.new(0.5, 0)
	pe.Rate     = 20
	pe.Speed    = NumberRange.new(1, 4)
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.LightEmission = 0.8
	pe.Parent   = att

	local collected = false
	orb.Touched:Connect(function(hit)
		if collected then return end
		local char   = hit.Parent :: Model?
		if not char  then return end
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end
		collected = true

		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local c = stats:FindFirstChild("Coins") :: IntValue?
			if c then
				local mult   = getLuckMultiplier(player)
				local reward = math.floor(5 * mult)
				c.Value     += reward
				print(string.format("[GREED ORB] %s +%d coins", player.Name, reward))
			end
		end

		playSfx(winSfx)
		-- v4: Use Debris instead of :Destroy() for safe instant cleanup
		Debris:AddItem(orb, 0.1)
		currentGreedOrb = nil
	end)

	currentGreedOrb = orb
end

local function cleanGreedOrb()
	if currentGreedOrb then
		Debris:AddItem(currentGreedOrb, 0)
		currentGreedOrb = nil
	end
end

-- =========================================================
-- PANIC MODE BROADCAST
-- =========================================================
local panicActive = false

local function firePanicMode(countdownSecs: number)
	if panicActive then return end
	panicActive = true
	evPanicMode:FireAllClients({ active = true, countdown = countdownSecs })
end

local function stopPanicMode()
	panicActive = false
	evPanicMode:FireAllClients({ active = false, countdown = 0 })
end

-- =========================================================
-- AWARD WINNERS
-- =========================================================
local function awardWinners(winningPlate: Part, onNeutralCheck: (Model) -> boolean)
	local someoneWon = false

	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then continue end

		local pos  = hrp.Position
		local minX = winningPlate.Position.X - winningPlate.Size.X / 2
		local maxX = winningPlate.Position.X + winningPlate.Size.X / 2
		local minZ = winningPlate.Position.Z - winningPlate.Size.Z / 2
		local maxZ = winningPlate.Position.Z + winningPlate.Size.Z / 2
		local onWinning = pos.X >= minX and pos.X <= maxX
			and pos.Z >= minZ and pos.Z <= maxZ
			and pos.Y > 45

		local onNeutral = onNeutralCheck(char)

		if onWinning or onNeutral then
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local winsVal  = ls:FindFirstChild("Wins")  :: IntValue?
				local coinsVal = ls:FindFirstChild("Coins") :: IntValue?
				if winsVal then winsVal.Value += 1 end

				local baseReward  = onNeutral and 15 or 10
				local luckMult    = getLuckMultiplier(player)
				local finalCoins  = math.floor(baseReward * luckMult)
				if coinsVal then coinsVal.Value += finalCoins end

				-- Update streak tracking
				local uid    = player.UserId
				playerWins[uid]    = (winsVal and winsVal.Value) or 0
				playerStreaks[uid] = (playerStreaks[uid] or 0) + 1

				-- Fire events
				evWinStreakChanged:FireServer(player, playerWins[uid], playerStreaks[uid])

				local rank = getRankTitle(playerWins[uid])
				evRoundWon:FireClient(player, {
					wins   = playerWins[uid],
					streak = playerStreaks[uid],
					rank   = rank,
				})

				someoneWon = true
				print(string.format("[WIN] %s | Total: %d | Streak: x%d | +%d coins",
					player.Name, playerWins[uid], playerStreaks[uid], finalCoins))
			end
		else
			-- Reset streak on loss
			playerStreaks[player.UserId] = 0
		end
	end

	return someoneWon
end

-- =========================================================
-- PLATE DROP WITH DEBRIS CLEANUP (v4 key improvement)
-- =========================================================
local function dropPlate(plate: Part)
	-- Flash
	for i = 1, 6 do
		plate.Transparency = (i % 2 == 0) and 0 or 0.5
		task.wait(0.08)
	end

	plate.Transparency = 0.9
	plate.CanCollide   = false

	-- Tween the plate falling
	local fallTween = TweenService:Create(plate, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = plate.Position + Vector3.new(0, -60, 0),
		Transparency = 1,
	})
	fallTween:Play()

	-- v4: Debris cleanup — plate auto-destroys after fall animation
	-- But we need to restore it next round, so we clone defaults first
	local origPos   = plate.Position + Vector3.new(0, 60, 0)  -- reverse fall
	local origSize  = plate.Size
	local origColor = plate.Color

	-- Rather than destroy (which breaks references), restore after delay
	task.delay(2.0, function()
		plate.Position    = origPos + Vector3.new(0, -50, 0)  -- reset position below (not visible)
		plate.Transparency = 0
		plate.CanCollide  = false
	end)
end

-- =========================================================
-- MASTER GAME LOOP v4
-- =========================================================
task.spawn(function()
	task.wait(3)  -- Wait for all handlers to initialize

	while true do
		-- ── RESET ARENA ──
		workspace.Gravity = 196.2

		redPlate.Size        = DEFAULT_SIZE
		redPlate.CFrame      = CFrame.new(DEFAULT_RED_POS)
		redPlate.Transparency = 0
		redPlate.CanCollide  = true
		redPlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

		bluePlate.Size        = DEFAULT_SIZE
		bluePlate.CFrame      = CFrame.new(DEFAULT_BLUE_POS)
		bluePlate.Transparency = 0
		bluePlate.CanCollide  = true
		bluePlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)

		-- ── SELECT MODIFIER & DILEMMA ──
		local mod      = Modifiers[math.random(1, #Modifiers)]
		local dilemma  = Dilemmas[math.random(1, #Dilemmas)]

		setTitle("⚠️ [ " .. dilemma.Cat .. " ] EVENT: " .. mod.Name .. " ⚠️")
		setQuestion(dilemma.Text)

		if mod.Type == "Ice" then
			local iceProps = PhysicalProperties.new(0.7, 0.01, 0.1)
			redPlate.CustomPhysicalProperties  = iceProps
			bluePlate.CustomPhysicalProperties = iceProps
		elseif mod.Type == "Gravity" then
			workspace.Gravity = 50
		end

		spawnGreedOrb()

		-- ── COUNTDOWN LOOP ──
		local panicFired = false
		for sec = 10, 1, -1 do
			local redCount  = getPlateHeadcount(redPlate)
			local blueCount = getPlateHeadcount(bluePlate)

			-- Shrink modifier
			if mod.Type == "Shrink" and sec <= 8 then
				local shrinkFactor = (10 - sec) * 1.5
				local newSize = Vector3.new(
					math.max(DEFAULT_SIZE.X - shrinkFactor, 10),
					3,
					math.max(DEFAULT_SIZE.Z - shrinkFactor * 1.3, 10)
				)
				-- Smooth shrink via tween
				TweenService:Create(redPlate,  TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Size = newSize }):Play()
				TweenService:Create(bluePlate, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Size = newSize }):Play()
			end

			-- Timer display
			local timerColor = sec <= 3 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 200)
			setTimer("🔴 " .. redCount .. " vs " .. blueCount .. " 🔵 | WAKTU: " .. sec .. "s", timerColor)

			-- v4: Fire Panic Mode at T-5 seconds
			if sec <= PANIC_TRIGGER_SEC and not panicFired then
				panicFired = true
				firePanicMode(sec)
			end

			if sec <= 3 then playSfx(tickSfx) end
			task.wait(1)
		end

		stopPanicMode()
		cleanGreedOrb()
		setTimer("WAKTU HABIS!", Color3.fromRGB(255, 215, 0))
		playSfx(alarmSfx)
		task.wait(1.5)

		-- ── DETERMINE WINNER ──
		local finalRed  = getPlateHeadcount(redPlate)
		local finalBlue = getPlateHeadcount(bluePlate)
		local dropRed   = false
		local statusMsg = ""

		if finalRed + finalBlue > 1 then
			if finalRed > finalBlue then
				dropRed    = true
				statusMsg  = "MERAH MAYORITAS (" .. finalRed .. ")! MERAH RUNTUH!"
			elseif finalBlue > finalRed then
				dropRed    = false
				statusMsg  = "BIRU MAYORITAS (" .. finalBlue .. ")! BIRU RUNTUH!"
			else
				dropRed    = math.random() > 0.5
				statusMsg  = "HASIL SERI! FAKTOR HOKI 50:50!"
			end
		else
			dropRed   = math.random() > 0.5
			statusMsg = "SOLO TEST: LANTAI " .. (dropRed and "MERAH" or "BIRU") .. " RUNTUH!"
		end

		local losingPlate  = dropRed and redPlate or bluePlate
		local winningPlate = dropRed and bluePlate or redPlate

		setTimer(statusMsg, Color3.fromRGB(255, 50, 50))
		playSfx(rumbleSfx)

		-- v4: Drop plate (with Debris-aware cleanup)
		dropPlate(losingPlate)

		-- Award winners (after 0.5s to let physics settle)
		task.wait(0.5)
		local won = awardWinners(winningPlate, isOnNeutralBeam)
		if won then playSfx(winSfx) end

		task.wait(3.5)
		setTimer("RESET ARENA & EVENT BARU...")
		task.wait(1.5)

		-- Restore losing plate for next round
		losingPlate.CFrame     = CFrame.new(dropRed and DEFAULT_RED_POS or DEFAULT_BLUE_POS)
		losingPlate.Size       = DEFAULT_SIZE
		losingPlate.Transparency = 0
		losingPlate.CanCollide = true
	end
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		savePlayer(p)
	end
end)

print("[DilemmaServer v4.0] ✅ Loaded — Panic Feedback, Debris Cleanup, Streak Tracking active.")

]======])

return 'Batch Injected Successfully'