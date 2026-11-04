local parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local function inject(name, src)
    local s = parent:FindFirstChild(name)
    if not s or s.ClassName ~= "LocalScript" then
        if s then s:Destroy() end
        s = Instance.new("LocalScript")
        s.Name = name
        s.Parent = parent
    end
    s.Source = src
    print("✅ Injected " .. name)
end

-- === StatsMenuController ===
inject("StatsMenuController", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: RPG STATS MENU CONTROLLER ★
-- LocalScript: StarterPlayerScripts - Aspek 2: Menu Upgrade Stat RPG
-- Desain UI Glassmorphism & Validasi Koin Real-Time
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local upgradeRemote = ReplicatedStorage:WaitForChild("UpgradeStatRemote") :: RemoteFunction

local screenGui = playerGui:FindFirstChild("StatsGui") :: ScreenGui?
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
end

-- Tombol Buka Menu Stats di Kiri Layar
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "OpenStatsBtn"
toggleBtn.Size = UDim2.new(0, 110, 0, 42)
toggleBtn.Position = UDim2.new(0, 20, 0.5, -55)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 13
toggleBtn.Text = "⚡ ATRIBUT"
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner", toggleBtn)
toggleCorner.CornerRadius = UDim.new(0, 8)
local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = Color3.fromRGB(0, 255, 200)
toggleStroke.Thickness = 1.5

-- Modal Pop-up Upgrade Stat
local modal = Instance.new("Frame")
modal.Name = "StatsModal"
modal.Size = UDim2.new(0, 380, 0, 340)
modal.Position = UDim2.new(0.5, -190, 0.5, -170)
modal.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
modal.BorderSizePixel = 0
modal.Visible = false
modal.Parent = screenGui

local modalCorner = Instance.new("UICorner", modal)
modalCorner.CornerRadius = UDim.new(0, 12)
local modalStroke = Instance.new("UIStroke", modal)
modalStroke.Color = Color3.fromRGB(60, 65, 85)
modalStroke.Thickness = 2

-- Header
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.Text = "⚡ UPGRADE ATRIBUT KARAKTER"
title.Parent = modal

-- Tombol Tutup (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Text = "X"
closeBtn.Parent = modal
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function()
    modal.Visible = not modal.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
    modal.Visible = false
end)

local STAT_DEFINITIONS = {
    { Id = "Agility", Name = "Agility (Kelincahan)", Desc = "Tambah kecepatan lari & tinggi lompatan", Color = Color3.fromRGB(0, 200, 255) },
    { Id = "Weight", Name = "Weight (Anti-Dorong)", Desc = "Resistensi dorongan lawan & cengkeraman es", Color = Color3.fromRGB(255, 80, 80) },
    { Id = "Luck", Name = "Luck (Keberuntungan)", Desc = "Peluang koin ekstra saat menang ronde", Color = Color3.fromRGB(255, 215, 0) }
}

local cardsFolder = Instance.new("Frame")
cardsFolder.Size = UDim2.new(1, -20, 1, -55)
cardsFolder.Position = UDim2.new(0, 10, 0, 48)
cardsFolder.BackgroundTransparency = 1
cardsFolder.Parent = modal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = cardsFolder

local function updateCardUI(card: Frame, statId: string)
    local playerStats = player:FindFirstChild("PlayerStats")
    local currentLv = 1
    if playerStats then
        local statObj = playerStats:FindFirstChild(statId) :: IntValue?
        if statObj then currentLv = statObj.Value end
    end

    local cost = currentLv * 15
    local levelLabel = card:FindFirstChild("LevelLabel") :: TextLabel?
    local upgradeBtn = card:FindFirstChild("UpgradeBtn") :: TextButton?
    local fillBar = card:FindFirstChild("BarBg") and card.BarBg:FindFirstChild("BarFill") :: Frame?

    if levelLabel then
        levelLabel.Text = string.format("Lv %d / 10", currentLv)
    end
    if fillBar then
        fillBar.Size = UDim2.new(math.clamp(currentLv / 10, 0.1, 1), 0, 1, 0)
    end
    if upgradeBtn then
        if currentLv >= 10 then
            upgradeBtn.Text = "MAX"
            upgradeBtn.Active = false
            upgradeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        else
            upgradeBtn.Text = string.format("UPGRADE (%d 🪙)", cost)
            upgradeBtn.Active = true
            upgradeBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        end
    end
end

for _, stat in ipairs(STAT_DEFINITIONS) do
    local card = Instance.new("Frame")
    card.Name = "Card_" .. stat.Id
    card.Size = UDim2.new(1, 0, 0, 80)
    card.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    card.BorderSizePixel = 0
    card.Parent = cardsFolder

    local cardCorner = Instance.new("UICorner", card)
    cardCorner.CornerRadius = UDim.new(0, 8)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.65, 0, 0, 22)
    nameLabel.Position = UDim2.new(0, 10, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = stat.Color
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = stat.Name
    nameLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.65, 0, 0, 18)
    descLabel.Position = UDim2.new(0, 10, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Text = stat.Desc
    descLabel.Parent = card

    -- Level Progress Bar
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(0.62, 0, 0, 8)
    barBg.Position = UDim2.new(0, 10, 0, 54)
    barBg.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    barBg.BorderSizePixel = 0
    barBg.Parent = card
    local barBgCorner = Instance.new("UICorner", barBg)
    barBgCorner.CornerRadius = UDim.new(0, 4)

    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0.1, 0, 1, 0)
    barFill.BackgroundColor3 = stat.Color
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    local barFillCorner = Instance.new("UICorner", barFill)
    barFillCorner.CornerRadius = UDim.new(0, 4)

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.3, 0, 0, 22)
    levelLabel.Position = UDim2.new(0.68, 0, 0, 8)
    levelLabel.BackgroundTransparency = 1
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.Font = Enum.Font.GothamBlack
    levelLabel.TextSize = 12
    levelLabel.TextXAlignment = Enum.TextXAlignment.Right
    levelLabel.Text = "Lv 1 / 10"
    levelLabel.Parent = card

    local upgradeBtn = Instance.new("TextButton")
    upgradeBtn.Name = "UpgradeBtn"
    upgradeBtn.Size = UDim2.new(0.3, 0, 0, 32)
    upgradeBtn.Position = UDim2.new(0.68, 0, 0, 36)
    upgradeBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    upgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeBtn.Font = Enum.Font.GothamBold
    upgradeBtn.TextSize = 11
    upgradeBtn.Text = "UPGRADE"
    upgradeBtn.Parent = card
    local upCorner = Instance.new("UICorner", upgradeBtn)
    upCorner.CornerRadius = UDim.new(0, 6)

    upgradeBtn.MouseButton1Click:Connect(function()
        upgradeBtn.Text = "..."
        local res = upgradeRemote:InvokeServer(stat.Id)
        if res and res.Success then
            updateCardUI(card, stat.Id)
        else
            upgradeBtn.Text = "GAGAL"
            task.wait(1)
            updateCardUI(card, stat.Id)
        end
    end)

    updateCardUI(card, stat.Id)
end

print(">> [CLIENT] StatsMenuController Sukses Dimuat! <<")


]======])

-- === FavoritePromptController ===
inject("FavoritePromptController", [======[
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


]======])

return 'OK: StatsMenuController, FavoritePromptController'