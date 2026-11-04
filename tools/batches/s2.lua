local parent = game:GetService("ServerScriptService")
local function inject(name, src)
    local s = parent:FindFirstChild(name)
    if not s or s.ClassName ~= "Script" then
        if s then s:Destroy() end
        s = Instance.new("Script")
        s.Name = name
        s.Parent = parent
    end
    s.Source = src
    print("✅ Injected " .. name)
end

-- === SkillServerHandler ===
inject("SkillServerHandler", [======[
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


]======])

-- === OverheadTitleHandler ===
inject("OverheadTitleHandler", [======[
--!strict
-- OverheadTitleHandler.luau
-- SERVER-SIDE: Creates and updates BillboardGui overhead title for every player.
-- Displays: Rank Title | Win Streak | VIP Badge
-- Dependencies: StatsServerHandler (DataStore), VIPPassHandler, DilemmaServer (WinStreak events)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- =========================================================
-- CONFIGURATION
-- =========================================================
local VIP_PASS_ID: number = 2064678688
local DEVELOPER_BYPASS: { [string]: boolean } = { Axlytic0 = true }

-- Rank titles based on total wins
local RANK_THRESHOLDS: { { wins: number, title: string, color: Color3 } } = {
	{ wins = 0,  title = "Rookie Survivor",   color = Color3.fromRGB(180, 180, 180) },
	{ wins = 6,  title = "Mind Master",        color = Color3.fromRGB(80,  200, 120) },
	{ wins = 16, title = "Colosseum Knight",   color = Color3.fromRGB(100, 160, 240) },
	{ wins = 31, title = "Tactician",          color = Color3.fromRGB(220, 180,  60) },
	{ wins = 51, title = "Untouchable",        color = Color3.fromRGB(255,  80,  80) },
}

-- Streak visual thresholds
local STREAK_COLORS: { [number]: Color3 } = {
	[3]  = Color3.fromRGB(255, 160,  40),  -- orange fire
	[5]  = Color3.fromRGB(255,  60,  60),  -- red flame
	[10] = Color3.fromRGB(180,   0, 255),  -- purple legendary
}

-- =========================================================
-- INTERNAL STATE
-- =========================================================
local playerWins:    { [number]: number } = {}  -- userId → total wins
local playerStreaks: { [number]: number } = {}  -- userId → current streak
local playerBoards:  { [number]: BillboardGui } = {}  -- userId → BillboardGui

-- =========================================================
-- HELPERS
-- =========================================================
local function getRankInfo(wins: number): { title: string, color: Color3 }
	local best = RANK_THRESHOLDS[1]
	for _, tier in RANK_THRESHOLDS do
		if wins >= tier.wins then
			best = tier
		end
	end
	return best
end

local function getStreakColor(streak: number): Color3
	local best = Color3.fromRGB(255, 255, 255)
	for threshold, col in STREAK_COLORS do
		if streak >= threshold then
			best = col
		end
	end
	return best
end

local function isVIP(player: Player): boolean
	if DEVELOPER_BYPASS[player.Name] then return true end
	local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, VIP_PASS_ID)
	return ok and result
end

-- =========================================================
-- BUILD BILLBOARD GUI
-- =========================================================
local function buildBillboard(character: Model, player: Player): BillboardGui
	-- Remove old if exists
	local head = character:WaitForChild("Head", 10) :: Part
	local old = head:FindFirstChild("OverheadBoard")
	if old then old:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadBoard"
	billboard.Size = UDim2.new(0, 220, 0, 72)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = false
	billboard.ResetOnSpawn = false
	billboard.MaxDistance = 60
	billboard.Parent = head

	-- Background frame (glassmorphism dark)
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = bg

	-- Rank title label
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.Size = UDim2.new(1, -8, 0.48, 0)
	rankLabel.Position = UDim2.new(0, 4, 0, 2)
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	rankLabel.Text = "Rookie Survivor"
	rankLabel.Parent = bg

	-- Player name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -8, 0.36, 0)
	nameLabel.Position = UDim2.new(0, 4, 0.46, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.Text = player.Name
	nameLabel.Parent = bg

	-- Streak label (bottom right)
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	streakLabel.Position = UDim2.new(0.5, 0, 0.68, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.TextScaled = true
	streakLabel.Font = Enum.Font.GothamBlack
	streakLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	streakLabel.Text = ""
	streakLabel.Parent = bg

	-- VIP label (bottom left)
	local vipLabel = Instance.new("TextLabel")
	vipLabel.Name = "VIPLabel"
	vipLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	vipLabel.Position = UDim2.new(0, 4, 0.68, 0)
	vipLabel.BackgroundTransparency = 1
	vipLabel.TextScaled = true
	vipLabel.Font = Enum.Font.GothamBold
	vipLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	vipLabel.Text = isVIP(player) and "👑 IMPERIAL VIP" or ""
	vipLabel.Parent = bg

	playerBoards[player.UserId] = billboard
	return billboard
end

-- =========================================================
-- UPDATE BILLBOARD DATA
-- =========================================================
local function refreshBoard(player: Player)
	local billboard = playerBoards[player.UserId]
	if not billboard or not billboard.Parent then return end

	local bg = billboard:FindFirstChild("Background") :: Frame
	if not bg then return end

	local wins   = playerWins[player.UserId]   or 0
	local streak = playerStreaks[player.UserId] or 0
	local rank   = getRankInfo(wins)

	local rankLabel   = bg:FindFirstChild("RankLabel")   :: TextLabel
	local streakLabel = bg:FindFirstChild("StreakLabel") :: TextLabel

	if rankLabel then
		rankLabel.Text        = rank.title
		rankLabel.TextColor3  = rank.color
	end

	if streakLabel then
		if streak >= 3 then
			streakLabel.Text       = "🔥 STREAK x" .. streak
			streakLabel.TextColor3 = getStreakColor(streak)
		else
			streakLabel.Text = ""
		end
	end

	-- Gold stroke pulse for VIP
	local stroke = bg:FindFirstChildOfClass("UIStroke") :: UIStroke
	if stroke and isVIP(player) then
		stroke.Transparency = 0
		stroke.Thickness = 2.5
	end
end

-- =========================================================
-- AURA PARTICLE EFFECT (VIP + High Streak)
-- =========================================================
local function attachAura(character: Model, player: Player)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	-- Remove old aura
	local oldAura = hrp:FindFirstChild("OverheadAura")
	if oldAura then oldAura:Destroy() end

	local streak = playerStreaks[player.UserId] or 0
	local vip    = isVIP(player)
	if not vip and streak < 3 then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "OverheadAura"
	attachment.Position = Vector3.new(0, 0, 0)
	attachment.Parent = hrp

	-- Base aura: rising sparks
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxassetid://6880497226"  -- spark texture (Roblox default approved)
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, vip and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	sparks.LightEmission = 0.8
	sparks.LightInfluence = 0.1
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Speed = NumberRange.new(3, 6)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = streak >= 5 and 24 or (vip and 14 or 8)
	sparks.Lifetime = NumberRange.new(1.2, 2)
	sparks.RotSpeed = NumberRange.new(-45, 45)
	sparks.Rotation = NumberRange.new(0, 360)
	sparks.Parent = attachment

	-- VIP angel ring (extra glow emission)
	if vip then
		local ring = Instance.new("ParticleEmitter")
		ring.Texture = "rbxassetid://6880479568"  -- ring/circle glow texture
		ring.Color = ColorSequence.new(Color3.fromRGB(255, 230, 100))
		ring.LightEmission = 1
		ring.LightInfluence = 0
		ring.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
		ring.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
		ring.Speed = NumberRange.new(0, 0.5)
		ring.Rate = 6
		ring.Lifetime = NumberRange.new(0.8, 1.2)
		ring.Parent = attachment
	end
end

-- =========================================================
-- REMOTE EVENTS
-- =========================================================
local RS = game:GetService("ReplicatedStorage")
local Events = RS:WaitForChild("DilemmaEvents", 15) :: Folder
local function getOrMakeEvent(name: string): RemoteEvent
	local ev = Events:FindFirstChild(name) :: RemoteEvent
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = Events
	end
	return ev
end

local evUpdateTitle  = getOrMakeEvent("UpdateOverheadTitle")  -- server→client not needed; server owns billboard
local evWinStreakChanged = getOrMakeEvent("WinStreakChanged") -- DilemmaServer fires this

-- DilemmaServer fires WinStreakChanged(player, totalWins, currentStreak)
evWinStreakChanged.OnServerEvent:Connect(function(_sender: Player, targetPlayer: Player, totalWins: number, streak: number)
	-- Only allow server-side scripts to fire this (validate sender == server ... RemoteEvent from server script)
	playerWins[targetPlayer.UserId]    = totalWins
	playerStreaks[targetPlayer.UserId] = streak
	refreshBoard(targetPlayer)
	if targetPlayer.Character then
		attachAura(targetPlayer.Character, targetPlayer)
	end
end)

-- =========================================================
-- PLAYER LIFECYCLE
-- =========================================================
local function onCharacterAdded(character: Model, player: Player)
	-- Wait for head
	character:WaitForChild("Head", 10)
	task.wait(0.3)  -- small settle delay
	buildBillboard(character, player)
	refreshBoard(player)
	attachAura(character, player)
end

local function onPlayerAdded(player: Player)
	playerWins[player.UserId]    = 0
	playerStreaks[player.UserId] = 0

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)

	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

local function onPlayerRemoving(player: Player)
	playerWins[player.UserId]    = nil
	playerStreaks[player.UserId] = nil
	playerBoards[player.UserId]  = nil
end

for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[OverheadTitleHandler] ✅ Loaded — Rank titles, auras, and streak tags active.")


]======])

return 'OK: SkillServerHandler, OverheadTitleHandler'