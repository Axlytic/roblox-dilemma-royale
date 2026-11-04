--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: TACTICAL SKILLS SERVER HANDLER ★
-- Server Script: Aspek 3 - Validasi Server Cooldown & Fisika Skill
-- Anti-Exploit: Semua aksi diverifikasi di Server
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local useSkillRemote = ReplicatedStorage:FindFirstChild("UseSkillRemote") :: RemoteEvent?
if not useSkillRemote then
    useSkillRemote = Instance.new("RemoteEvent")
    useSkillRemote.Name = "UseSkillRemote"
    useSkillRemote.Parent = ReplicatedStorage
end

local skillFeedbackRemote = ReplicatedStorage:FindFirstChild("SkillFeedbackRemote") :: RemoteEvent?
if not skillFeedbackRemote then
    skillFeedbackRemote = Instance.new("RemoteEvent")
    skillFeedbackRemote.Name = "SkillFeedbackRemote"
    skillFeedbackRemote.Parent = ReplicatedStorage
end

local SKILL_CONFIG = {
    ["ForcePush"] = { Cooldown = 10, Range = 18, BaseForce = 75 },
    ["SpeedDash"] = { Cooldown = 8, Duration = 2.5, SpeedBoost = 42 },
    ["GravityFeather"] = { Cooldown = 12, Duration = 4.0, Buoyancy = 0.55 }
}

-- Cooldown Tracker di Server (Anti-Spam / Anti-Cheat)
local playerCooldowns: {[number]: {[string]: number}} = {}

local function getTargetWeightLevel(targetPlayer: Player): number
    local stats = targetPlayer:FindFirstChild("PlayerStats")
    if stats then
        local w = stats:FindFirstChild("Weight") :: IntValue?
        if w then return w.Value end
    end
    return 1
end

local function executeForcePush(player: Player, config: typeof(SKILL_CONFIG.ForcePush))
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return end

    -- Visual Shockwave Ring
    local shockwave = Instance.new("Part")
    shockwave.Shape = Enum.PartType.Cylinder
    shockwave.Size = Vector3.new(0.5, 4, 4)
    shockwave.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Material = Enum.Material.Neon
    shockwave.Color = Color3.fromRGB(0, 255, 255)
    shockwave.Parent = workspace

    task.spawn(function()
        for i = 1, 12 do
            task.wait(0.02)
            shockwave.Size += Vector3.new(0, config.Range / 6, config.Range / 6)
            shockwave.Transparency = i / 12
        end
        shockwave:Destroy()
    end)

    -- Berikan impulse pada pemain sekitar yang berada dalam jangkauan
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherRoot = otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
            local otherHum = otherChar:FindFirstChildOfClass("Humanoid")
            if otherRoot and otherHum and otherHum.Health > 0 then
                local dist = (otherRoot.Position - root.Position).Magnitude
                if dist <= config.Range then
                    -- Hitung resistensi berat (Stat Weight)
                    local weightLv = getTargetWeightLevel(otherPlayer)
                    local resistanceMultiplier = 1 / (1 + (weightLv * 0.12)) -- Lv 10 -> -55% dorongan!

                    local pushDir = (otherRoot.Position - root.Position).Unit
                    pushDir = Vector3.new(pushDir.X, 0.35, pushDir.Z).Unit

                    local finalImpulse = pushDir * config.BaseForce * resistanceMultiplier * otherRoot.AssemblyMass
                    otherRoot:ApplyImpulse(finalImpulse)
                end
            end
        end
    end
end

local function executeSpeedDash(player: Player, config: typeof(SKILL_CONFIG.SpeedDash))
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not root then return end

    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = config.SpeedBoost

    -- Trail Particle
    local attachment0 = Instance.new("Attachment", root)
    local attachment1 = Instance.new("Attachment", root)
    attachment0.Position = Vector3.new(0, 1, 0)
    attachment1.Position = Vector3.new(0, -1, 0)

    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 180), Color3.fromRGB(255, 255, 0))
    trail.Lifetime = 0.35
    trail.Parent = root

    task.delay(config.Duration, function()
        if humanoid and humanoid.Parent then
            humanoid.WalkSpeed = originalSpeed
        end
        trail:Destroy()
        attachment0:Destroy()
        attachment1:Destroy()
    end)
end

local function executeGravityFeather(player: Player, config: typeof(SKILL_CONFIG.GravityFeather))
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return end

    local vf = Instance.new("VectorForce")
    local att = Instance.new("Attachment", root)
    vf.Attachment0 = att
    -- Memberikan gaya angkat ke atas (meringankan gravitasi 55%)
    vf.Force = Vector3.new(0, workspace.Gravity * root.AssemblyMass * config.Buoyancy, 0)
    vf.RelativeTo = Enum.ActuatorRelativeTo.World
    vf.Parent = root

    -- Visual Glowing Sparkles
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255))
    pe.Size = NumberSequence.new(0.4, 0)
    pe.Rate = 20
    pe.Lifetime = NumberRange.new(0.6, 1.2)
    pe.Parent = att

    task.delay(config.Duration, function()
        vf:Destroy()
        att:Destroy()
    end)
end

useSkillRemote.OnServerEvent:Connect(function(player: Player, skillId: string)
    local config = SKILL_CONFIG[skillId]
    if not config then return end

    local userId = player.UserId
    if not playerCooldowns[userId] then
        playerCooldowns[userId] = {}
    end

    local now = os.clock()
    local lastUsed = playerCooldowns[userId][skillId] or 0

    if now - lastUsed < config.Cooldown then
        -- Masih cooldown!
        local remaining = math.ceil(config.Cooldown - (now - lastUsed))
        skillFeedbackRemote:FireClient(player, skillId, false, remaining)
        return
    end

    -- Set Cooldown
    playerCooldowns[userId][skillId] = now
    skillFeedbackRemote:FireClient(player, skillId, true, config.Cooldown)

    if skillId == "ForcePush" then
        executeForcePush(player, config)
    elseif skillId == "SpeedDash" then
        executeSpeedDash(player, config)
    elseif skillId == "GravityFeather" then
        executeGravityFeather(player, config)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player.UserId] = nil
end)

print(">> [SUKSES] SkillServerHandler (Aspek 3: Tactical Skills) Berjalan! <<")

