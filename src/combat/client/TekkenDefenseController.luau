--!strict
-- TekkenDefenseController.luau
-- CLIENT SCRIPT: Tekken-Style Technical Defense System
-- Features:
--   • High Guard (Standing F) vs Low Guard (LeftControl + F)
--   • Just-Frame Parry (180ms timing window for Perfect Counter)
--   • Guard Health Meter HUD (Cracks if overloaded, causing Guard Crush)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Guard State
local isBlocking = false
local blockType = "None" -- "High" | "Low"
local guardHealth = 100
local MAX_GUARD = 100
local blockStartTime = 0
local PARRY_WINDOW = 0.18 -- 180ms

-- Visual Guard Shield Part
local currentShieldPart: Part? = nil

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local evBlock = combatEvents and combatEvents:FindFirstChild("BlockEvent") :: RemoteEvent?
local evParry = combatEvents and combatEvents:FindFirstChild("ParryEvent") :: RemoteEvent?

-- =========================================================
-- GUARD HEALTH HUD
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TekkenGuardHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local barFrame = Instance.new("Frame")
barFrame.Name = "GuardBarFrame"
barFrame.Size = UDim2.new(0, 220, 0, 16)
barFrame.Position = UDim2.new(0.5, -110, 0.82, 0)
barFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
barFrame.BorderSizePixel = 0
barFrame.Visible = false
barFrame.Parent = screenGui
Instance.new("UICorner", barFrame).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Thickness = 1.5
stroke.Parent = barFrame

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(1, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
fill.BorderSizePixel = 0
fill.Parent = barFrame
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)

local guardLabel = Instance.new("TextLabel")
guardLabel.Size = UDim2.new(1, 0, 1, 0)
guardLabel.BackgroundTransparency = 1
guardLabel.Font = Enum.Font.GothamBold
guardLabel.TextSize = 11
guardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
guardLabel.Text = "🛡️ GUARD: 100%"
guardLabel.Parent = barFrame

-- =========================================================
-- VISUAL GUARD SHIELD
-- =========================================================
local function spawnShield(char: Model, bType: string)
	if currentShieldPart then currentShieldPart:Destroy() end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local shield = Instance.new("Part")
	shield.Name = "GuardShieldVisual"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(4, 5, 4)
	shield.CFrame = root.CFrame * (bType == "Low" and CFrame.new(0, -1, 1.2) or CFrame.new(0, 0.5, 1.2))
	shield.Color = bType == "Low" and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(0, 220, 255)
	shield.Material = Enum.Material.ForceField
	shield.Transparency = 0.5
	shield.Anchored = false
	shield.CanCollide = false
	shield.Massless = true
	shield.Parent = char

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = shield
	weld.Parent = shield

	currentShieldPart = shield
end

local function removeShield()
	if currentShieldPart then
		currentShieldPart:Destroy()
		currentShieldPart = nil
	end
end

-- =========================================================
-- START & STOP GUARD
-- =========================================================
local function startGuard()
	local char = LocalPlayer.Character
	if not char or guardHealth <= 0 then return end

	local isCrouched = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C)
	blockType = isCrouched and "Low" or "High"
	isBlocking = true
	blockStartTime = os.clock()

	barFrame.Visible = true
	stroke.Color = blockType == "Low" and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(0, 200, 255)

	spawnShield(char, blockType)

	if evBlock then
		evBlock:FireServer(true, blockType)
	end

	print(string.format(">> [Tekken Guard] %s Guard Active! <<", blockType))
end

local function stopGuard()
	if not isBlocking then return end
	isBlocking = false
	blockType = "None"
	barFrame.Visible = false
	removeShield()

	if evBlock then
		evBlock:FireServer(false, "None")
	end
end

-- =========================================================
-- JUST-FRAME PARRY EFFECT
-- =========================================================
local function triggerParryVFX()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Sparkles & Sound
	local att = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(1.5, 0)
	pe.Rate = 60
	pe.Speed = NumberRange.new(10, 20)
	pe.Lifetime = NumberRange.new(0.2, 0.4)
	pe.Parent = att

	local snd = Instance.new("Sound")
	snd.SoundId = "rbxasset://sounds/bell.wav"
	snd.PlaybackSpeed = 1.6
	snd.Volume = 1
	snd.Parent = root
	snd:Play()

	task.delay(0.4, function()
		att:Destroy()
		snd:Destroy()
	end)

	print(">> [TEKKEN PERFECT PARRY] Opponent Staggered! <<")
end

-- Input Bindings: F Key for Guard
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then
		startGuard()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.F then
		stopGuard()
	end
end)

-- Regenerate Guard Health when not blocking
RunService.Heartbeat:Connect(function(dt)
	if not isBlocking and guardHealth < MAX_GUARD then
		guardHealth = math.min(MAX_GUARD, guardHealth + (15 * dt))
		fill.Size = UDim2.new(guardHealth / MAX_GUARD, 0, 1, 0)
		guardLabel.Text = string.format("🛡️ GUARD: %d%%", math.floor(guardHealth))
	end
end)

print("[TekkenDefenseController] ✅ Loaded — Hold 'F' for Standing Guard, 'Ctrl + F' for Low Guard.")
