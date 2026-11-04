--!strict
-- DailyRewardsController.luau
-- CLIENT-SIDE: Glassmorphism 7-day calendar UI.
-- Auto-opens on join if daily reward is available.
-- Communicates with DailyRewardsHandler.luau via RemoteFunctions.

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- WAIT FOR EVENTS
-- =========================================================
local Events = ReplicatedStorage:WaitForChild("DilemmaEvents", 30) :: Folder

local function waitForChild(parent: Instance, name: string, timeout: number): Instance?
	local child = parent:FindFirstChild(name)
	if child then return child end
	local start = os.clock()
	while os.clock() - start < timeout do
		child = parent:FindFirstChild(name)
		if child then return child end
		task.wait(0.1)
	end
	return nil
end

local rfClaim  = waitForChild(Events, "ClaimDailyReward", 15)  :: RemoteFunction
local rfStatus = waitForChild(Events, "GetDailyStatus", 15)    :: RemoteFunction
local evNotify = waitForChild(Events, "DailyRewardAvailable", 15) :: RemoteEvent

if not rfClaim or not rfStatus or not evNotify then
	warn("[DailyRewardsController] Remote events not found — aborting.")
	return
end

-- =========================================================
-- UI CONSTANTS
-- =========================================================
local DAY_COLORS = {
	claimed   = Color3.fromRGB(80, 160, 80),
	claimable = Color3.fromRGB(255, 200, 40),
	pending   = Color3.fromRGB(80, 80, 120),
	locked    = Color3.fromRGB(50, 50, 70),
}

local REWARD_ICONS = {
	["🪙"] = "🪙", ["💰"] = "💰", ["⚡"] = "⚡",
	["🏅"] = "🏅", ["👼"] = "👼",
}

-- =========================================================
-- BUILD GUI
-- =========================================================
local screenGui: ScreenGui
local mainFrame: Frame
local isOpen = false

local function buildGUI()
	-- Remove old if exists
	local old = PlayerGui:FindFirstChild("DailyRewardsGUI")
	if old then old:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardsGUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 15
	screenGui.Enabled = false
	screenGui.Parent = PlayerGui

	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 10
	overlay.Parent = screenGui

	-- Main card
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainCard"
	mainFrame.Size = UDim2.new(0, 580, 0, 420)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 28)
	mainFrame.BackgroundTransparency = 0.08
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 11
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = mainFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -50, 0, 50)
	titleLabel.Position = UDim2.new(0, 20, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.Text = "🎁  HADIAH LOGIN HARIAN"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 12
	titleLabel.Parent = mainFrame

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Sub"
	subLabel.Size = UDim2.new(1, -50, 0, 24)
	subLabel.Position = UDim2.new(0, 20, 0, 48)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextSize = 14
	subLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	subLabel.Text = "Login setiap hari untuk reward eksklusif! Jangan sampai ketinggalan."
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.ZIndex = 12
	subLabel.Parent = mainFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	closeBtn.BackgroundTransparency = 0.3
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 12
	closeBtn.Parent = mainFrame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	-- Day cards container
	local cardsFrame = Instance.new("Frame")
	cardsFrame.Name = "CardsFrame"
	cardsFrame.Size = UDim2.new(1, -40, 0, 220)
	cardsFrame.Position = UDim2.new(0, 20, 0, 85)
	cardsFrame.BackgroundTransparency = 1
	cardsFrame.ZIndex = 12
	cardsFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = cardsFrame

	-- Status message label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -40, 0, 40)
	statusLabel.Position = UDim2.new(0, 20, 0, 318)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 16
	statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	statusLabel.Text = ""
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.ZIndex = 12
	statusLabel.Parent = mainFrame

	-- Claim button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimBtn"
	claimBtn.Size = UDim2.new(0, 220, 0, 46)
	claimBtn.Position = UDim2.new(0.5, -110, 0, 362)
	claimBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 20)
	claimBtn.Text = "🎁 KLAIM HADIAH HARI INI"
	claimBtn.Font = Enum.Font.GothamBlack
	claimBtn.TextSize = 15
	claimBtn.TextColor3 = Color3.fromRGB(20, 15, 5)
	claimBtn.BorderSizePixel = 0
	claimBtn.ZIndex = 12
	claimBtn.Parent = mainFrame
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 12)

	return closeBtn, cardsFrame, statusLabel, claimBtn
end

-- =========================================================
-- POPULATE DAY CARDS
-- =========================================================
local function buildDayCard(parent: Frame, dayData: { day: number, state: string, reward: { icon: string, label: string, day: number } }): Frame
	local card = Instance.new("Frame")
	card.Name = "Day" .. dayData.day
	card.Size = UDim2.new(0, 72, 1, 0)
	card.BackgroundColor3 = DAY_COLORS[dayData.state] or DAY_COLORS.locked
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel = 0
	card.ZIndex = 13
	card.Parent = parent

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = dayData.state == "claimable" and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(100, 100, 150)
	stroke.Thickness = dayData.state == "claimable" and 2.5 or 1
	stroke.Parent = card

	-- Day number
	local dayLabel = Instance.new("TextLabel")
	dayLabel.Size = UDim2.new(1, 0, 0, 24)
	dayLabel.Position = UDim2.new(0, 0, 0, 4)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.TextSize = 13
	dayLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	dayLabel.Text = "Hari " .. dayData.day
	dayLabel.ZIndex = 14
	dayLabel.Parent = card

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 0, 44)
	iconLabel.Position = UDim2.new(0, 0, 0, 30)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 36
	iconLabel.Text = dayData.reward.icon
	iconLabel.ZIndex = 14
	iconLabel.Parent = card

	-- Reward label
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, -4, 0, 36)
	rewardLabel.Position = UDim2.new(0, 2, 0, 76)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Font = Enum.Font.Gotham
	rewardLabel.TextSize = 11
	rewardLabel.TextWrapped = true
	rewardLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rewardLabel.Text = dayData.reward.label
	rewardLabel.ZIndex = 14
	rewardLabel.Parent = card

	-- Claimed checkmark overlay
	if dayData.state == "claimed" then
		local check = Instance.new("TextLabel")
		check.Size = UDim2.fromScale(1, 1)
		check.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		check.BackgroundTransparency = 0.5
		check.Font = Enum.Font.GothamBlack
		check.TextSize = 32
		check.TextColor3 = Color3.fromRGB(80, 220, 80)
		check.Text = "✓"
		check.ZIndex = 15
		check.Parent = card
		Instance.new("UICorner", check).CornerRadius = UDim.new(0, 10)
	end

	-- Pulsing glow for claimable
	if dayData.state == "claimable" then
		task.spawn(function()
			while card.Parent do
				TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.7 }):Play()
				task.wait(1.5)
			end
		end)
	end

	return card
end

-- =========================================================
-- REFRESH UI STATE
-- =========================================================
local claimBtnRef: TextButton
local statusLabelRef: TextLabel
local cardFrameRef: Frame

local function refreshUI()
	if not rfStatus then return end
	local ok, result = pcall(rfStatus.InvokeServer, rfStatus)
	if not ok or not result then return end

	-- Clear old cards
	for _, child in cardFrameRef:GetChildren() do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local hasClaimable = false
	for _, dayData in result.days do
		buildDayCard(cardFrameRef, dayData)
		if dayData.state == "claimable" then
			hasClaimable = true
		end
	end

	if hasClaimable then
		claimBtnRef.BackgroundColor3 = Color3.fromRGB(255, 180, 20)
		claimBtnRef.Text = "🎁 KLAIM HADIAH HARI INI"
		claimBtnRef.Active = true
	else
		claimBtnRef.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		claimBtnRef.Text = "⏳ Belum waktunya..."
		claimBtnRef.Active = false
	end
end

-- =========================================================
-- CLAIM ANIMATION
-- =========================================================
local function playCoinAnimation(reward: { icon: string, label: string })
	local notif = Instance.new("ScreenGui")
	notif.Name = "RewardNotif"
	notif.ResetOnSpawn = false
	notif.DisplayOrder = 20
	notif.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 100)
	frame.Position = UDim2.new(0.5, -150, 0.15, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = notif
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 22
	lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	lbl.Text = reward.icon .. "  " .. reward.label .. " diterima!"
	lbl.Parent = frame

	-- Slide in
	frame.Position = UDim2.new(0.5, -150, -0.1, 0)
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, -150, 0.15, 0) }):Play()
	task.wait(2.5)
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { Position = UDim2.new(0.5, -150, -0.15, 0) }):Play()
	task.wait(0.3)
	notif:Destroy()
end

-- =========================================================
-- OPEN / CLOSE
-- =========================================================
local function openGUI()
	if isOpen then return end
	isOpen = true
	screenGui.Enabled = true
	refreshUI()
	mainFrame.Size = UDim2.new(0, 580, 0, 1)
	TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(0, 580, 0, 420) }):Play()
end

local function closeGUI()
	if not isOpen then return end
	TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Sine), { Size = UDim2.new(0, 580, 0, 1) }):Play()
	task.wait(0.25)
	screenGui.Enabled = false
	isOpen = false
end

-- =========================================================
-- WIRE UP
-- =========================================================
local closeBtn, cardsFrame, statusLabel, claimBtn = buildGUI()
cardFrameRef   = cardsFrame
statusLabelRef = statusLabel
claimBtnRef    = claimBtn

closeBtn.Activated:Connect(closeGUI)

claimBtn.Activated:Connect(function()
	if not rfClaim then return end
	claimBtn.Active = false
	claimBtn.Text = "⏳ Memproses..."

	local ok, result = pcall(rfClaim.InvokeServer, rfClaim)
	if ok and result then
		if result.success then
			statusLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
			statusLabel.Text = "✅ Berhasil! " .. (result.reward and result.reward.label or "")
			refreshUI()
			task.spawn(playCoinAnimation, result.reward or { icon = "🎁", label = "Reward" })
		else
			statusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
			statusLabel.Text = "❌ " .. (result.message or "Gagal mengklaim.")
			refreshUI()
		end
	else
		statusLabel.Text = "❌ Koneksi error. Coba lagi."
	end
end)

-- Auto-open when server notifies
evNotify.OnClientEvent:Connect(function(_data)
	task.wait(2)
	openGUI()
end)

-- Keyboard shortcut: L key to open/close
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.L then
		if isOpen then closeGUI() else openGUI() end
	end
end)

print("[DailyRewardsController] ✅ Loaded — Press L to open Daily Rewards. Auto-opens when available.")
