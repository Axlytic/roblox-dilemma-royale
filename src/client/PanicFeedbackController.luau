--!strict
-- PanicFeedbackController.luau
-- CLIENT-SIDE: Sensory panic loop visual & audio feedback.
-- Triggers on PanicMode RemoteEvent from DilemmaServer.
-- Effects: Camera shake, screen red vignette, screen edge pulse, heartbeat audio.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local SoundService     = game:GetService("SoundService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-- =========================================================
-- WAIT FOR EVENTS
-- =========================================================
local Events = ReplicatedStorage:WaitForChild("DilemmaEvents", 30) :: Folder

local function waitEvent(name: string): RemoteEvent
	local ev = Events:FindFirstChild(name) :: RemoteEvent
	if ev then return ev end
	local start = os.clock()
	while os.clock() - start < 20 do
		ev = Events:FindFirstChild(name) :: RemoteEvent
		if ev then return ev end
		task.wait(0.1)
	end
	error("[PanicFeedbackController] RemoteEvent '" .. name .. "' not found after 20s")
end

local evPanicMode = waitEvent("PanicMode")

-- =========================================================
-- BUILD VIGNETTE GUI (always present, invisible by default)
-- =========================================================
local vignetteGui = Instance.new("ScreenGui")
vignetteGui.Name = "PanicVignetteGUI"
vignetteGui.ResetOnSpawn = false
vignetteGui.IgnoreGuiInset = true
vignetteGui.DisplayOrder = 50
vignetteGui.Parent = PlayerGui

-- Vignette: 4 edge gradient frames (top, bottom, left, right)
local function makeEdgeGradient(name: string, size: UDim2, pos: UDim2, rotation: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = pos
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = vignetteGui

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 20, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 20, 20)),
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(0.6, 0.6),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	grad.Rotation = rotation
	grad.Parent = frame
	return frame
end

local vignetteTop    = makeEdgeGradient("VigTop",    UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0, 0),    90)
local vignetteBottom = makeEdgeGradient("VigBottom", UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0.7, 0), 270)
local vignetteLeft   = makeEdgeGradient("VigLeft",   UDim2.new(0.2, 0, 1, 0), UDim2.new(0, 0, 0, 0),   180)
local vignetteRight  = makeEdgeGradient("VigRight",  UDim2.new(0.2, 0, 1, 0), UDim2.new(0.8, 0, 0, 0),   0)

-- Start invisible
local vignetteFrames = { vignetteTop, vignetteBottom, vignetteLeft, vignetteRight }
for _, f in vignetteFrames do
	f.BackgroundTransparency = 1
	-- Set gradient transparency to fully invisible
	for _, child in f:GetChildren() do
		if child:IsA("UIGradient") then
			child.Transparency = NumberSequence.new(1)
		end
	end
end

-- Countdown overlay text
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "PanicCountdown"
countdownLabel.Size = UDim2.new(1, 0, 0, 80)
countdownLabel.Position = UDim2.new(0, 0, 0.5, -40)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Font = Enum.Font.GothamBlack
countdownLabel.TextSize = 72
countdownLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
countdownLabel.Text = ""
countdownLabel.TextStrokeTransparency = 0.3
countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
countdownLabel.Visible = false
countdownLabel.Parent = vignetteGui

-- =========================================================
-- HEARTBEAT SOUND (use a short beep sound from Roblox library)
-- =========================================================
local heartbeatSound = Instance.new("Sound")
heartbeatSound.Name = "PanicHeartbeat"
-- rbxassetid://9113590730 = heartbeat/pulse SFX (commonly used, safe)
heartbeatSound.SoundId = "rbxasset://sounds/bass.wav"
heartbeatSound.Volume = 0
heartbeatSound.RollOffMaxDistance = 0
heartbeatSound.Looped = false
heartbeatSound.Parent = SoundService

-- Tick sound (sharp click for each second countdown)
local tickSound = Instance.new("Sound")
tickSound.Name = "PanicTick"
tickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"  -- clock tick SFX
tickSound.Volume = 0.4
tickSound.Looped = false
tickSound.Parent = SoundService

-- =========================================================
-- CAMERA SHAKE
-- =========================================================
local shakeActive = false
local shakeMagnitude = 0
local shakeConn: RBXScriptConnection?

local function startCameraShake(magnitude: number)
	shakeMagnitude = magnitude
	shakeActive = true
	if shakeConn then shakeConn:Disconnect() end

	local baseCFrame = Camera.CFrame

	shakeConn = RunService.RenderStepped:Connect(function()
		if not shakeActive then
			if shakeConn then shakeConn:Disconnect() end
			return
		end
		local offset = Vector3.new(
			math.sin(os.clock() * 20) * shakeMagnitude * 0.05,
			math.cos(os.clock() * 17) * shakeMagnitude * 0.04,
			0
		)
		Camera.CFrame = Camera.CFrame * CFrame.new(offset)
	end)
end

local function stopCameraShake()
	shakeActive = false
	shakeMagnitude = 0
	if shakeConn then
		shakeConn:Disconnect()
		shakeConn = nil
	end
end

-- =========================================================
-- VIGNETTE SHOW / HIDE
-- =========================================================
local function setVignetteIntensity(intensity: number)
	-- intensity 0 = invisible, 1 = full red panic
	local alphaStart = math.clamp(1 - intensity, 0, 1)
	local newSeq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, math.clamp(intensity * 0.85, 0, 1)),
		NumberSequenceKeypoint.new(0.5, math.clamp(intensity * 0.4, 0, 1)),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	for _, frame in vignetteFrames do
		for _, child in frame:GetChildren() do
			if child:IsA("UIGradient") then
				child.Transparency = newSeq
			end
		end
	end
end

-- =========================================================
-- PANIC SEQUENCE COROUTINE
-- =========================================================
local panicActive = false
local panicThread: thread?

local function runPanicSequence(countdownSeconds: number)
	panicActive = true
	countdownLabel.Visible = true

	local startTime = os.clock()
	local duration  = countdownSeconds

	while panicActive and os.clock() - startTime < duration do
		local elapsed   = os.clock() - startTime
		local remaining = duration - elapsed
		local progress  = elapsed / duration  -- 0→1 as panic increases

		-- Update countdown text
		local secsLeft = math.ceil(remaining)
		countdownLabel.Text = tostring(secsLeft)

		-- Scale up effects as countdown approaches 0
		local intensity = math.clamp(progress * 1.3, 0, 1)

		-- Vignette
		setVignetteIntensity(intensity)

		-- Camera shake (gets stronger)
		startCameraShake(intensity * 2.5)

		-- Heartbeat sound gets louder
		heartbeatSound.Volume = intensity * 0.8

		-- Countdown label pulse
		local scale = 1 + math.sin(os.clock() * (8 + intensity * 10)) * 0.08 * intensity
		countdownLabel.TextSize = 72 * scale

		-- Color goes from yellow→orange→red as countdown drops
		local r = 255
		local g = math.clamp(math.floor(255 * (1 - progress)), 20, 255)
		countdownLabel.TextColor3 = Color3.fromRGB(r, g, 20)

		-- Tick every second
		local prevSec = math.ceil(duration - (elapsed - 0.016))
		if secsLeft ~= prevSec and secsLeft <= 5 then
			tickSound:Play()
		end

		task.wait(0.016)  -- ~60fps
	end

	-- Fade out
	panicActive = false
	stopCameraShake()

	TweenService:Create(countdownLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()

	local fadeStart = os.clock()
	while os.clock() - fadeStart < 0.6 do
		local t = (os.clock() - fadeStart) / 0.6
		setVignetteIntensity(1 - t)
		task.wait(0.016)
	end

	setVignetteIntensity(0)
	countdownLabel.Visible = false
	countdownLabel.TextTransparency = 0
	heartbeatSound.Volume = 0
end

-- =========================================================
-- REMOTE EVENT HANDLERS
-- =========================================================
evPanicMode.OnClientEvent:Connect(function(config: { active: boolean, countdown: number? })
	if config.active then
		-- Cancel existing panic thread if any
		if panicThread then
			panicActive = false
			task.cancel(panicThread)
			stopCameraShake()
			setVignetteIntensity(0)
			countdownLabel.Visible = false
		end
		local secs = config.countdown or 5
		heartbeatSound:Play()
		panicThread = task.spawn(runPanicSequence, secs)
	else
		-- Force stop
		panicActive = false
		stopCameraShake()
		setVignetteIntensity(0)
		countdownLabel.Visible = false
	end
end)

print("[PanicFeedbackController] ✅ Loaded — Camera shake, red vignette, countdown pulse ready.")

