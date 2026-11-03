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
