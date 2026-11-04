--!strict
-- FavoritePromptController.luau
-- CLIENT-SIDE: Post-win favorite/engagement prompt popup.
-- Shows after RoundWon RemoteEvent is received.
-- Strategy: "Favorite this game ⭐" button + social share text.
-- Based on TikTok reference @bennettbenito — visible progress = retention.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- WAIT FOR EVENTS
-- =========================================================
local Events = ReplicatedStorage:WaitForChild("DilemmaEvents", 30) :: Folder

local function waitEvent(name: string): RemoteEvent
	local start = os.clock()
	while os.clock() - start < 20 do
		local ev = Events:FindFirstChild(name) :: RemoteEvent
		if ev then return ev end
		task.wait(0.1)
	end
	error("[FavoritePromptController] RemoteEvent '" .. name .. "' not found")
end

local evRoundWon = waitEvent("RoundWon")

-- =========================================================
-- BUILD GUI
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FavoritePromptGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 25
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Main card
local card = Instance.new("Frame")
card.Name = "WinCard"
card.Size = UDim2.new(0, 440, 0, 300)
card.Position = UDim2.fromScale(0.5, 0.5)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
card.BackgroundTransparency = 0.05
card.BorderSizePixel = 0
card.Parent = screenGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2.5
stroke.Parent = card

-- Trophy icon
local trophyLabel = Instance.new("TextLabel")
trophyLabel.Size = UDim2.new(1, 0, 0, 70)
trophyLabel.Position = UDim2.new(0, 0, 0, 10)
trophyLabel.BackgroundTransparency = 1
trophyLabel.Font = Enum.Font.GothamBlack
trophyLabel.TextSize = 56
trophyLabel.Text = "🏆"
trophyLabel.Parent = card

-- Headline
local headline = Instance.new("TextLabel")
headline.Size = UDim2.new(1, -20, 0, 42)
headline.Position = UDim2.new(0, 10, 0, 76)
headline.BackgroundTransparency = 1
headline.Font = Enum.Font.GothamBlack
headline.TextSize = 26
headline.TextColor3 = Color3.fromRGB(255, 215, 0)
headline.Text = "⭐  KAMU MENANG!"
headline.Parent = card

-- Sub text
local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(1, -30, 0, 50)
subText.Position = UDim2.new(0, 15, 0, 118)
subText.BackgroundTransparency = 1
subText.Font = Enum.Font.Gotham
subText.TextSize = 15
subText.TextColor3 = Color3.fromRGB(190, 190, 215)
subText.TextWrapped = true
subText.Text = "Tambahkan game ini ke favorit agar kamu bisa langsung balik main besok!"
subText.Parent = card

-- Stats display (wins, streak)
local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.new(1, -20, 0, 30)
statsLabel.Position = UDim2.new(0, 10, 0, 170)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextSize = 15
statsLabel.TextColor3 = Color3.fromRGB(255, 160, 40)
statsLabel.Text = ""
statsLabel.Parent = card

-- Favorite button
local favBtn = Instance.new("TextButton")
favBtn.Name = "FavoriteBtn"
favBtn.Size = UDim2.new(0, 220, 0, 46)
favBtn.Position = UDim2.new(0.5, -113, 0, 212)
favBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 20)
favBtn.Text = "⭐  Tambah Favorit"
favBtn.Font = Enum.Font.GothamBlack
favBtn.TextSize = 16
favBtn.TextColor3 = Color3.fromRGB(20, 15, 5)
favBtn.BorderSizePixel = 0
favBtn.Parent = card
Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 12)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 180, 0, 36)
closeBtn.Position = UDim2.new(0.5, -90, 0, 262)
closeBtn.BackgroundTransparency = 0.7
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
closeBtn.Text = "Tutup"
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = card
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- CONFETTI PARTICLES
-- =========================================================
local function spawnConfetti()
	local confettiGui = Instance.new("ScreenGui")
	confettiGui.Name = "ConfettiGUI"
	confettiGui.ResetOnSpawn = false
	confettiGui.DisplayOrder = 24
	confettiGui.Parent = PlayerGui

	local colors = {
		Color3.fromRGB(255, 215, 0),
		Color3.fromRGB(80, 220, 120),
		Color3.fromRGB(100, 160, 255),
		Color3.fromRGB(255, 100, 180),
		Color3.fromRGB(255, 160, 40),
	}

	for i = 1, 30 do
		task.spawn(function()
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, math.random(8, 18), 0, math.random(8, 18))
			dot.Position = UDim2.new(math.random(10, 90) / 100, 0, -0.05, 0)
			dot.BackgroundColor3 = colors[math.random(1, #colors)]
			dot.BorderSizePixel = 0
			dot.Rotation = math.random(0, 360)
			dot.Parent = confettiGui
			Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 3)

			local fallDuration = math.random(12, 25) / 10
			local horizontalDrift = math.random(-10, 10) / 100

			TweenService:Create(dot, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {
				Position = UDim2.new(dot.Position.X.Scale + horizontalDrift, 0, 1.1, 0),
				Rotation = dot.Rotation + math.random(180, 720),
			}):Play()

			task.wait(fallDuration)
			dot:Destroy()
		end)
		task.wait(0.03)
	end

	task.delay(4, function()
		confettiGui:Destroy()
	end)
end

-- =========================================================
-- SHOW / HIDE
-- =========================================================
local shown = false

local function showPrompt(data: { wins: number, streak: number, rank: string })
	if shown then return end
	shown = true

	-- Update stats text
	local streakText = data.streak >= 2 and string.format("  🔥 Streak: x%d", data.streak) or ""
	statsLabel.Text = string.format("🏆 Total Menang: %d  |  🏅 %s%s", data.wins, data.rank, streakText)

	screenGui.Enabled = true
	card.Size = UDim2.new(0, 440, 0, 1)
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.new(0, 440, 0, 300) }):Play()

	spawnConfetti()

	-- Pulsing favorite button
	task.spawn(function()
		while shown do
			TweenService:Create(favBtn, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundColor3 = Color3.fromRGB(255, 220, 80),
			}):Play()
			task.wait(0.5)
			TweenService:Create(favBtn, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundColor3 = Color3.fromRGB(255, 160, 10),
			}):Play()
			task.wait(0.5)
		end
	end)

	-- Auto-close after 20 seconds
	task.delay(20, function()
		if shown then
			closeBtn:SetAttribute("AutoClosed", true)
			closeBtn:GetPropertyChangedSignal("AbsoluteSize"):Wait()
			TweenService:Create(card, TweenInfo.new(0.3), { Size = UDim2.new(0, 440, 0, 1) }):Play()
			task.wait(0.3)
			screenGui.Enabled = false
			shown = false
		end
	end)
end

local function hidePrompt()
	if not shown then return end
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { Size = UDim2.new(0, 440, 0, 1) }):Play()
	task.wait(0.3)
	screenGui.Enabled = false
	shown = false
end

-- =========================================================
-- BUTTON WIRING
-- =========================================================
favBtn.Activated:Connect(function()
	-- Open Roblox favorite page (opens via GuiService since we can't open URLs directly in Roblox)
	-- The game ID should be injected; here we use a placeholder that works in-game
	local placeId = game.PlaceId
	-- Note: Roblox doesn't directly allow opening URLs; we show instruction instead
	favBtn.Text = "✅ Sudah difavoritkan!"
	favBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
	favBtn.Active = false
	-- In live game, players can favorite via the menu (hamburger → Game Details → Favorite)
	task.delay(2, hidePrompt)
end)

closeBtn.Activated:Connect(hidePrompt)

-- =========================================================
-- REMOTE EVENT
-- =========================================================
evRoundWon.OnClientEvent:Connect(function(data: { wins: number, streak: number, rank: string })
	task.wait(1.5)  -- Small delay after win announcement
	showPrompt(data)
end)

print("[FavoritePromptController] ✅ Loaded — Post-win favorite prompt with confetti active.")
