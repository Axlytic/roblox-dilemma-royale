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
    print("✅ Injected LocalScript: " .. name)
end

-- === DoubleJumpClient ===
inject("DoubleJumpClient", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: DOUBLE JUMP CLIENT CONTROLLER ★
-- LocalScript: StarterPlayerScripts - Integrasi Agility Stat Booster
-- ============================================================

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character: Model? = nil
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil

local canDoubleJump = false
local hasDoubleJumped = false

local function getAgilityBoost(): number
    local stats = player:FindFirstChild("PlayerStats")
    if stats then
        local agility = stats:FindFirstChild("Agility") :: IntValue?
        if agility then
            return agility.Value * 3.5
        end
    end
    return 0
end

local function setupCharacter(char: Model)
    character = char
    humanoid = char:WaitForChild("Humanoid") :: Humanoid
    rootPart = char:WaitForChild("HumanoidRootPart") :: BasePart

    canDoubleJump = false
    hasDoubleJumped = false

    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            canDoubleJump = false
            hasDoubleJumped = false
        elseif newState == Enum.HumanoidStateType.Freefall then
            task.wait(0.1)
            if not hasDoubleJumped then
                canDoubleJump = true
            end
        end
    end)
end

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

UserInputService.JumpRequest:Connect(function()
    if not humanoid or not rootPart or not character then return end

    if canDoubleJump and not hasDoubleJumped then
        hasDoubleJumped = true
        canDoubleJump = false

        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        local jumpBoost = 48 + getAgilityBoost()
        rootPart.AssemblyLinearVelocity = Vector3.new(
            rootPart.AssemblyLinearVelocity.X,
            jumpBoost,
            rootPart.AssemblyLinearVelocity.Z
        )

        -- Efek visual cincin loncatan neon
        local ring = Instance.new("Part")
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.2, 5, 5)
        ring.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
        ring.Anchored = true
        ring.CanCollide = false
        ring.Material = Enum.Material.Neon
        ring.Color = Color3.fromRGB(0, 255, 255)
        ring.Transparency = 0.3
        ring.Parent = workspace

        task.spawn(function()
            for i = 1, 10 do
                task.wait(0.02)
                ring.Size += Vector3.new(0, 0.5, 0.5)
                ring.Transparency += 0.07
            end
            ring:Destroy()
        end)
    end
end)

print(">> [CLIENT] DoubleJumpClient (Agility Powered) Sukses Dimuat! <<")

]======])

-- === SkillHUDController ===
inject("SkillHUDController", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: SKILL HUD CONTROLLER ★
-- LocalScript: StarterPlayerScripts - Aspek 3: HUD Skill Taktikal
-- Dukungan Keyboard PC (Q, E, R) dan Sentuhan Layar Mobile
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local useSkillRemote = ReplicatedStorage:WaitForChild("UseSkillRemote") :: RemoteEvent
local skillFeedbackRemote = ReplicatedStorage:WaitForChild("SkillFeedbackRemote") :: RemoteEvent

-- Buat ScreenGui SkillHUD
local screenGui = playerGui:FindFirstChild("SkillHUD") :: ScreenGui?
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SkillHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
end

local hudContainer = Instance.new("Frame")
hudContainer.Name = "HUDContainer"
hudContainer.Size = UDim2.new(0, 320, 0, 80)
hudContainer.Position = UDim2.new(0.5, -160, 1, -95)
hudContainer.BackgroundTransparency = 1
hudContainer.Parent = screenGui

local SKILLS = {
    { Id = "ForcePush", Key = Enum.KeyCode.Q, KeyName = "Q", Name = "PUSH", Color = Color3.fromRGB(0, 200, 255) },
    { Id = "SpeedDash", Key = Enum.KeyCode.E, KeyName = "E", Name = "DASH", Color = Color3.fromRGB(255, 170, 0) },
    { Id = "GravityFeather", Key = Enum.KeyCode.R, KeyName = "R", Name = "FLOAT", Color = Color3.fromRGB(180, 80, 255) }
}

local skillButtons: {[string]: { Button: TextButton, CooldownOverlay: Frame, CooldownText: TextLabel, IsCoolingDown: boolean }} = {}

for i, skill in ipairs(SKILLS) do
    local slot = Instance.new("Frame")
    slot.Name = "Slot_" .. skill.Id
    slot.Size = UDim2.new(0, 90, 0, 75)
    slot.Position = UDim2.new(0, (i - 1) * 115, 0, 0)
    slot.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
    slot.BorderSizePixel = 0
    slot.Parent = hudContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = slot

    local stroke = Instance.new("UIStroke")
    stroke.Color = skill.Color
    stroke.Thickness = 2
    stroke.Parent = slot

    local btn = Instance.new("TextButton")
    btn.Name = "TriggerBtn"
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = slot

    local keyBadge = Instance.new("TextLabel")
    keyBadge.Size = UDim2.new(0, 22, 0, 20)
    keyBadge.Position = UDim2.new(0, 6, 0, 6)
    keyBadge.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    keyBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBadge.Font = Enum.Font.GothamBlack
    keyBadge.TextSize = 12
    keyBadge.Text = skill.KeyName
    keyBadge.Parent = slot
    local badgeCorner = Instance.new("UICorner", keyBadge)
    badgeCorner.CornerRadius = UDim.new(0, 4)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.45, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Text = skill.Name
    nameLabel.Parent = slot

    -- Cooldown Dark Overlay
    local cdOverlay = Instance.new("Frame")
    cdOverlay.Name = "CooldownOverlay"
    cdOverlay.Size = UDim2.new(1, 0, 0, 0) -- 0 height when ready
    cdOverlay.Position = UDim2.new(0, 0, 1, 0)
    cdOverlay.AnchorPoint = Vector2.new(0, 1)
    cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cdOverlay.BackgroundTransparency = 0.5
    cdOverlay.BorderSizePixel = 0
    cdOverlay.Parent = slot
    local cdCorner = Instance.new("UICorner", cdOverlay)
    cdCorner.CornerRadius = UDim.new(0, 10)

    local cdText = Instance.new("TextLabel")
    cdText.Name = "CooldownText"
    cdText.Size = UDim2.new(1, 0, 1, 0)
    cdText.BackgroundTransparency = 1
    cdText.TextColor3 = Color3.fromRGB(255, 255, 255)
    cdText.Font = Enum.Font.GothamBlack
    cdText.TextSize = 18
    cdText.Text = ""
    cdText.Visible = false
    cdText.Parent = slot

    skillButtons[skill.Id] = {
        Button = btn,
        CooldownOverlay = cdOverlay,
        CooldownText = cdText,
        IsCoolingDown = false
    }

    -- Click / Touch Handler (Mobile + PC)
    btn.MouseButton1Click:Connect(function()
        if not skillButtons[skill.Id].IsCoolingDown then
            useSkillRemote:FireServer(skill.Id)
        end
    end)
end

-- Keyboard Keybinds Handler (Q, E, R)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    for _, skill in ipairs(SKILLS) do
        if input.KeyCode == skill.Key then
            if not skillButtons[skill.Id].IsCoolingDown then
                useSkillRemote:FireServer(skill.Id)
            end
        end
    end
end)

-- Feedback Handler dari Server
skillFeedbackRemote.OnClientEvent:Connect(function(skillId: string, success: boolean, cdDuration: number)
    local slotData = skillButtons[skillId]
    if not slotData then return end

    if success then
        slotData.IsCoolingDown = true
        slotData.CooldownText.Visible = true
        slotData.CooldownOverlay.Size = UDim2.new(1, 0, 1, 0)

        task.spawn(function()
            local remaining = cdDuration
            while remaining > 0 do
                slotData.CooldownText.Text = string.format("%ds", math.ceil(remaining))
                local progress = remaining / cdDuration
                slotData.CooldownOverlay.Size = UDim2.new(1, 0, progress, 0)
                task.wait(0.1)
                remaining = remaining - 0.1
            end

            slotData.IsCoolingDown = false
            slotData.CooldownText.Visible = false
            slotData.CooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
        end)
    end
end)

print(">> [CLIENT] SkillHUDController Resmi Dimuat! <<")


]======])

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

-- === ShopController ===
inject("ShopController", [======[
--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: SHOP CLIENT CONTROLLER ★
-- LocalScript: StarterPlayerScripts / StarterGui (Toko Perk Controller)
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopRemote = ReplicatedStorage:WaitForChild("ShopRemote") :: RemoteFunction

-- Menunggu ScreenGui Toko Perk
local screenGui = playerGui:WaitForChild("ShopGui") :: ScreenGui
local openButton = screenGui:WaitForChild("OpenShopBtn") :: TextButton
local shopModal = screenGui:WaitForChild("ShopModal") :: Frame
local closeButton = shopModal:WaitForChild("CloseBtn") :: TextButton
local itemsFrame = shopModal:WaitForChild("ItemsFrame") :: ScrollingFrame

local function toggleShop(visible: boolean)
    shopModal.Visible = visible
end

openButton.MouseButton1Click:Connect(function()
    toggleShop(not shopModal.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
    toggleShop(false)
end)

local function showToast(message: string, isSuccess: boolean)
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 300, 0, 45)
    toast.Position = UDim2.new(0.5, -150, 0.85, 0)
    toast.BackgroundColor3 = isSuccess and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    toast.TextColor3 = Color3.fromRGB(255, 255, 255)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 14
    toast.Text = message
    toast.TextWrapped = true
    toast.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toast

    task.delay(3, function()
        if toast and toast.Parent then
            local tween = TweenService:Create(toast, TweenInfo.new(0.5), {TextTransparency = 1, BackgroundTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function()
                toast:Destroy()
            end)
        end
    end)
end

-- Hubungkan tombol pembelian tiap item di dalam ItemsFrame
for _, child in ipairs(itemsFrame:GetChildren()) do
    if child:IsA("Frame") and child:FindFirstChild("BuyBtn") then
        local buyBtn = child:FindFirstChild("BuyBtn") :: TextButton
        local perkId = child.Name -- e.g. "ForcePush", "SpeedDash", "GravityFeather"

        buyBtn.MouseButton1Click:Connect(function()
            buyBtn.Text = "MEMPROSES..."
            buyBtn.Active = false

            local response = shopRemote:InvokeServer(perkId)

            buyBtn.Text = "BELI"
            buyBtn.Active = true

            if response and response.Success then
                showToast(response.Message, true)
            else
                local errMsg = (response and response.Message) or "Gagal memproses transaksi!"
                showToast(errMsg, false)
            end
        end)
    end
end

print(">> [CLIENT] ShopController Sukses Dimuat! <<")


]======])

return 'Batch Injected Successfully'