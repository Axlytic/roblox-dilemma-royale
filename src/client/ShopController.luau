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

