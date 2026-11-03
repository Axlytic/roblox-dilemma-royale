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
