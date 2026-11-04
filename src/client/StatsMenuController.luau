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

