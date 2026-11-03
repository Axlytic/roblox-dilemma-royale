--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: SHOP SERVER HANDLER ★
-- Server Script: Validasi Transaksi Koin & Pembelian Perk / Skill
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
if not shopRemote then
    shopRemote = Instance.new("RemoteFunction")
    shopRemote.Name = "ShopRemote"
    shopRemote.Parent = ReplicatedStorage
end

local PERK_CATALOG = {
    ["ForcePush"] = {
        Name = "Force Push (Dorong Lawan)",
        Price = 5,
        Description = "Mendorong pemain di sekitar sejauh 15 studs!"
    },
    ["SpeedDash"] = {
        Name = "Speed Dash (Lari Kilat)",
        Price = 3,
        Description = "Meningkatkan kecepatan lari 2x lipat selama 5 detik!"
    },
    ["GravityFeather"] = {
        Name = "Gravity Feather (Bulu Gravitasi)",
        Price = 4,
        Description = "Lompat lebih tinggi dan melayang pelan saat jatuh!"
    }
}

local function grantPerk(player: Player, perkId: string): (boolean, string)
    local char = player.Character
    if not char then
        return false, "Karakter belum spawn!"
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "Humanoid tidak ditemukan!"
    end

    if perkId == "ForcePush" then
        -- Berikan Tool Force Push ke Backpack
        local backpack = player:FindFirstChild("Backpack")
        if backpack and not backpack:FindFirstChild("Force Push") and not char:FindFirstChild("Force Push") then
            local tool = Instance.new("Tool")
            tool.Name = "Force Push"
            tool.RequiresHandle = false
            tool.CanBeDropped = false

            tool.Activated:Connect(function()
                local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if not root then return end

                local PUSH_RADIUS = 15
                local PUSH_FORCE = 60

                for _, otherPlayer in ipairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                        if otherRoot then
                            local dist = (otherRoot.Position - root.Position).Magnitude
                            if dist <= PUSH_RADIUS then
                                local pushDir = (otherRoot.Position - root.Position).Unit
                                pushDir = Vector3.new(pushDir.X, 0.4, pushDir.Z).Unit
                                otherRoot:ApplyImpulse(pushDir * PUSH_FORCE * otherRoot.AssemblyMass)
                            end
                        end
                    end
                end
            end)

            tool.Parent = backpack
            return true, "Tool Force Push berhasil didapatkan!"
        else
            return false, "Kamu sudah memiliki Force Push!"
        end

    elseif perkId == "SpeedDash" then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 32
        task.delay(5, function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
        end)
        return true, "Speed Dash aktif selama 5 detik!"

    elseif perkId == "GravityFeather" then
        local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if root then
            local bodyForce = Instance.new("VectorForce")
            local attachment = Instance.new("Attachment", root)
            bodyForce.Attachment0 = attachment
            bodyForce.Force = Vector3.new(0, workspace.Gravity * root.AssemblyMass * 0.4, 0)
            bodyForce.RelativeTo = Enum.ActuatorRelativeTo.World
            bodyForce.Parent = root

            task.delay(10, function()
                bodyForce:Destroy()
                attachment:Destroy()
            end)
            return true, "Gravity Feather aktif selama 10 detik!"
        end
    end

    return false, "Perk tidak dikenal"
end

shopRemote.OnServerInvoke = function(player: Player, perkId: string)
    local perk = PERK_CATALOG[perkId]
    if not perk then
        return {Success = false, Message = "Perk tidak ditemukan di katalog!", NewBalance = 0}
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return {Success = false, Message = "Leaderstats belum dimuat!", NewBalance = 0}
    end

    local coinsStat = leaderstats:FindFirstChild("Coins") :: IntValue?
    if not coinsStat then
        return {Success = false, Message = "Data koin tidak ditemukan!", NewBalance = 0}
    end

    if coinsStat.Value < perk.Price then
        return {
            Success = false,
            Message = string.format("Koin tidak cukup! Butuh %d koin, kamu punya %d.", perk.Price, coinsStat.Value),
            NewBalance = coinsStat.Value
        }
    end

    local granted, grantMsg = grantPerk(player, perkId)
    if granted then
        coinsStat.Value -= perk.Price
        return {
            Success = true,
            Message = string.format("Sukses membeli %s! Sisa koin: %d", perk.Name, coinsStat.Value),
            NewBalance = coinsStat.Value
        }
    else
        return {
            Success = false,
            Message = grantMsg,
            NewBalance = coinsStat.Value
        }
    end
end

print(">> [SUKSES] ShopServerHandler Resmi Berjalan! <<")

