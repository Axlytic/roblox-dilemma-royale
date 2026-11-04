--!strict
-- CombatServerMaster.luau
-- SERVER SCRIPT: Manages Combat Remotes, Replicated Config, & Server Verification

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 1. Ensure CombatEvents folder
local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents") :: Folder?
if not combatEvents then
	combatEvents = Instance.new("Folder")
	combatEvents.Name = "CombatEvents"
	combatEvents.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evNinjaDash = ensureRemote("NinjaDashEvent")
local evSidestep  = ensureRemote("SidestepEvent")
local evBlock     = ensureRemote("BlockEvent")
local evParry     = ensureRemote("ParryEvent")

-- 2. Track Player Combat States
local playerCombatStates: { [number]: { isBlocking: boolean, blockType: string, guardHealth: number } } = {}

local function setupPlayer(player: Player)
	playerCombatStates[player.UserId] = {
		isBlocking = false,
		blockType = "None",
		guardHealth = 100
	}
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerCombatStates[player.UserId] = nil
end)
for _, p in Players:GetPlayers() do setupPlayer(p) end

-- 3. Remote Listeners
evBlock.OnServerEvent:Connect(function(player: Player, isBlocking: boolean, blockType: string)
	local state = playerCombatStates[player.UserId]
	if state then
		state.isBlocking = isBlocking
		state.blockType = blockType or "High"
		-- Broadcast to other clients for stance visuals
		evBlock:FireAllClients(player, isBlocking, blockType)
	end
end)

evParry.OnServerEvent:Connect(function(player: Player, targetModel: Model)
	-- Successful Just-Frame Parry executed by player
	print(string.format(">> [PARRY] %s berhasil melakukan Tekken Perfect Parry! <<", player.Name))
	evParry:FireAllClients(player, targetModel)
end)

print("[CombatServerMaster] ✅ Combat Remotes and State Tracking initialized.")
