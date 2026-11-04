--!strict
-- StormMovementController.luau
-- CLIENT SCRIPT: Naruto Storm 4 3D Arena Movement + Tekken Sidestep Evasion
-- Features:
--   • Circular strafing around opponent (A/D)
--   • Tekken Sidestep: Double-tap A or D triggers swift lateral evasion step
--   • Ninja / Chakra Dash: Double-tap Space triggers high-speed homing dash toward opponent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Double Tap Tracking for Sidestep
local lastKeyTime: { [Enum.KeyCode]: number } = {}
local DOUBLE_TAP_WINDOW = 0.28
local isSidestepping = false
local isNinjaDashing = false

local function getTarget(): Model?
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") and dummy:FindFirstChild("HumanoidRootPart") then
		return dummy
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			return p.Character
		end
	end
	return nil
end

-- =========================================================
-- TEKKEN SIDESTEP (Double-Tap A or D)
-- =========================================================
local function executeTekkenSidestep(direction: "Left" | "Right")
	local char = LocalPlayer.Character
	if not char or isSidestepping or isNinjaDashing then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local target = getTarget()
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	isSidestepping = true

	-- Calculate lateral vector perpendicular to target vector
	local toTarget = (targetRoot.Position - root.Position).Unit
	local flatToTarget = Vector3.new(toTarget.X, 0, toTarget.Z).Unit
	local lateral = Vector3.new(-flatToTarget.Z, 0, flatToTarget.X) -- Right direction
	if direction == "Left" then
		lateral = -lateral
	end

	-- Visual Trail / Blur Effect
	local trailAtt0 = Instance.new("Attachment", root)
	local trailAtt1 = Instance.new("Attachment", root)
	trailAtt0.Position = Vector3.new(0, 1.2, 0)
	trailAtt1.Position = Vector3.new(0, -1.2, 0)

	local trail = Instance.new("Trail")
	trail.Attachment0 = trailAtt0
	trail.Attachment1 = trailAtt1
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.25
	trail.Parent = root

	-- Fast snappy lateral impulse (Tekken feel)
	local sidestepVelocity = lateral * 55
	root.AssemblyLinearVelocity = Vector3.new(sidestepVelocity.X, root.AssemblyLinearVelocity.Y, sidestepVelocity.Z)

	print(string.format(">> [Tekken Sidestep] Evasion %s executed! <<", direction))

	task.delay(0.25, function()
		trail:Destroy()
		trailAtt0:Destroy()
		trailAtt1:Destroy()
		isSidestepping = false
	end)
end

-- =========================================================
-- NINJA / CHAKRA DASH (Double-Tap Space)
-- =========================================================
local function executeNinjaDash()
	local char = LocalPlayer.Character
	if not char or isNinjaDashing or isSidestepping then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	local target = getTarget()
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	isNinjaDashing = true

	-- Sonic Boom Sparkle Particles
	local burstAtt = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(1.2, 0)
	pe.Rate = 50
	pe.Speed = NumberRange.new(5, 15)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Parent = burstAtt

	-- Sound
	local dashSound = Instance.new("Sound")
	dashSound.SoundId = "rbxasset://sounds/action_jump.mp3"
	dashSound.PlaybackSpeed = 1.6
	dashSound.Volume = 0.8
	dashSound.Parent = root
	dashSound:Play()

	local startTime = os.clock()
	local maxDuration = 0.75

	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local currentDist = (targetRoot.Position - root.Position).Magnitude

		-- Stop dash when close enough (melee range) or timed out
		if currentDist <= 6.5 or elapsed >= maxDuration or not isNinjaDashing then
			if conn then conn:Disconnect() end
			isNinjaDashing = false
			burstAtt:Destroy()
			dashSound:Destroy()
			return
		end

		-- Homing direction toward target
		local dir = (targetRoot.Position - root.Position).Unit
		root.AssemblyLinearVelocity = dir * 85
	end)

	print(">> [Ninja Dash] Homing towards target! <<")
end

-- =========================================================
-- INPUT HANDLING
-- =========================================================
local lastJumpTime = 0

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local now = os.clock()

	-- 1. Sidestep detection (Double tap A or D)
	if input.KeyCode == Enum.KeyCode.A then
		local prev = lastKeyTime[Enum.KeyCode.A] or 0
		if now - prev <= DOUBLE_TAP_WINDOW then
			executeTekkenSidestep("Left")
			lastKeyTime[Enum.KeyCode.A] = 0
		else
			lastKeyTime[Enum.KeyCode.A] = now
		end
	elseif input.KeyCode == Enum.KeyCode.D then
		local prev = lastKeyTime[Enum.KeyCode.D] or 0
		if now - prev <= DOUBLE_TAP_WINDOW then
			executeTekkenSidestep("Right")
			lastKeyTime[Enum.KeyCode.D] = 0
		else
			lastKeyTime[Enum.KeyCode.D] = now
		end

	-- 2. Ninja Dash detection (Double tap Space or Shift + Space)
	elseif input.KeyCode == Enum.KeyCode.Space then
		local isShiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		if isShiftHeld or (now - lastJumpTime <= DOUBLE_TAP_WINDOW) then
			executeNinjaDash()
			lastJumpTime = 0
		else
			lastJumpTime = now
		end
	end
end)

-- Always face the target while moving in 3D Arena
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local target = getTarget()
	if target and target:FindFirstChild("HumanoidRootPart") then
		local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart
		local look = Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z)
		-- Orient player smoothly toward target
		root.CFrame = root.CFrame:Lerp(CFrame.new(root.Position, look), 0.2)
	end
end)

print("[StormMovementController] ✅ Loaded — Double-tap A/D (Sidestep) & Double-tap Space (Ninja Dash) active.")
