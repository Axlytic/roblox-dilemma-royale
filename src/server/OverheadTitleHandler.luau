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
