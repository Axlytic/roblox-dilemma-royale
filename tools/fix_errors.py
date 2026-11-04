import os

# ========================================================
# 1. FIX DilemmaServer.luau
# ========================================================
ds_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\DilemmaServer.luau"
with open(ds_path, "r", encoding="utf-8") as f:
    ds = f.read()

# Fix FireServer error: change RemoteEvent to BindableEvent
ds = ds.replace(
    'local evWinStreakChanged  = getOrMakeEvent("WinStreakChanged")',
    'local beWinStreakChanged = getOrMakeBindable("WinStreakChanged")'
)
ds = ds.replace(
    'evWinStreakChanged:FireServer(player, playerWins[uid], playerStreaks[uid])',
    'beWinStreakChanged:Fire(player, playerWins[uid], playerStreaks[uid])'
)

# Fix DataStore queue flooding (debounce on save)
old_save = """local function savePlayer(player: Player)
	if not PlayerDataStore then return end"""
new_save = """local lastSaved: { [number]: number } = {}
local function savePlayer(player: Player)
	if not PlayerDataStore then return end
	local now = os.clock()
	if lastSaved[player.UserId] and (now - lastSaved[player.UserId]) < 4 then
		return
	end
	lastSaved[player.UserId] = now"""
ds = ds.replace(old_save, new_save)

with open(ds_path, "w", encoding="utf-8") as f:
    f.write(ds)
print("1. DilemmaServer.luau fixed!")

# ========================================================
# 2. FIX OverheadTitleHandler.luau
# ========================================================
oth_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\OverheadTitleHandler.luau"
with open(oth_path, "r", encoding="utf-8") as f:
    oth = f.read()

# Replace missing particle textures with built-in sparkles texture
oth = oth.replace('rbxassetid://6880497226', 'rbxasset://textures/particles/sparkles_main.dds')
oth = oth.replace('rbxassetid://6880479568', 'rbxasset://textures/particles/sparkles_main.dds')

# Change WinStreakChanged listener to BindableEvent
old_streak_listener = """local evWinStreakChanged = getOrMakeEvent("WinStreakChanged") -- DilemmaServer fires this

-- DilemmaServer fires WinStreakChanged(player, totalWins, currentStreak)
evWinStreakChanged.OnServerEvent:Connect(function(_sender: Player, targetPlayer: Player, totalWins: number, streak: number)
	-- Only allow server-side scripts to fire this (validate sender == server ... RemoteEvent from server script)
	playerWins[targetPlayer.UserId]    = totalWins
	playerStreaks[targetPlayer.UserId] = streak
	refreshBoard(targetPlayer)
	if targetPlayer.Character then
		attachAura(targetPlayer.Character, targetPlayer)
	end
end)"""

new_streak_listener = """local function getOrMakeBindable(name: string): BindableEvent
	local be = Events:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = Events
	end
	return be
end

local beWinStreakChanged = getOrMakeBindable("WinStreakChanged")

beWinStreakChanged.Event:Connect(function(targetPlayer: Player, totalWins: number, streak: number)
	playerWins[targetPlayer.UserId]    = totalWins
	playerStreaks[targetPlayer.UserId] = streak
	refreshBoard(targetPlayer)
	if targetPlayer.Character then
		attachAura(targetPlayer.Character, targetPlayer)
	end
end)"""

oth = oth.replace(old_streak_listener, new_streak_listener)

with open(oth_path, "w", encoding="utf-8") as f:
    f.write(oth)
print("2. OverheadTitleHandler.luau fixed!")

# ========================================================
# 3. FIX ColosseumBuilder.luau (Add ImperialVIPBox & VIPGateSensor)
# ========================================================
cb_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\ColosseumBuilder.luau"
with open(cb_path, "r", encoding="utf-8") as f:
    cb = f.read()

old_vip_code = """	-- ── IMPERIAL VIP BOX (ALWAYS GOLD — biome accent color) ──
	local vipBox = createPart("VIPBox_Platform",
		Vector3.new(28, 2, 14),
		CFrame.new(0, 68, -52),
		Color3.fromRGB(80, 70, 50), Enum.Material.Marble, folder
	)

	-- VIP Throne
	createPart("GoldenThrone",
		Vector3.new(4, 5, 3),
		CFrame.new(0, 70.5, -52),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, folder
	)
	createPart("ThroneBack",
		Vector3.new(4, 7, 1),
		CFrame.new(0, 73.5, -53.5),
		Color3.fromRGB(255, 180, 0), Enum.Material.SmoothPlastic, folder
	)

	-- VIP Gold railing
	for side = -1, 1, 2 do
		createPart("VIPRailing_" .. (side > 0 and "R" or "L"),
			Vector3.new(0.5, 3, 14),
			CFrame.new(side * 14, 70, -52),
			Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, folder
		)
	end
	createPart("VIPRailing_Front",
		Vector3.new(28, 3, 0.5),
		CFrame.new(0, 70, -45),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, folder
	)

	-- VIP gold lighting
	addPointLight(vipBox, Color3.fromRGB(255, 215, 80), 1.5, 18)

	-- VIP red carpet
	createPart("RedCarpet",
		Vector3.new(6, 0.2, 14),
		CFrame.new(0, 69.1, -52),
		Color3.fromRGB(180, 20, 20), Enum.Material.SmoothPlastic, folder
	)"""

new_vip_code = """	-- ── IMPERIAL VIP BOX (Container Model for VIPPassHandler) ──
	local vipModel = folder:FindFirstChild("ImperialVIPBox") :: Model?
	if not vipModel then
		vipModel = Instance.new("Model")
		vipModel.Name = "ImperialVIPBox"
		vipModel.Parent = folder
	end

	local vipBox = createPart("VIPBox_Platform",
		Vector3.new(28, 2, 14),
		CFrame.new(0, 68, -52),
		Color3.fromRGB(80, 70, 50), Enum.Material.Marble, vipModel
	)

	-- VIP Gate Sensor Part (Touch sensor for game pass check)
	local vipGate = createPart("VIPGateSensor",
		Vector3.new(12, 8, 2),
		CFrame.new(0, 71, -44.5),
		Color3.fromRGB(255, 215, 0), Enum.Material.Neon, vipModel,
		0.75, false
	)

	-- VIP Throne
	createPart("GoldenThrone",
		Vector3.new(4, 5, 3),
		CFrame.new(0, 70.5, -52),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, vipModel
	)
	createPart("ThroneBack",
		Vector3.new(4, 7, 1),
		CFrame.new(0, 73.5, -53.5),
		Color3.fromRGB(255, 180, 0), Enum.Material.SmoothPlastic, vipModel
	)

	-- VIP Gold railing
	for side = -1, 1, 2 do
		createPart("VIPRailing_" .. (side > 0 and "R" or "L"),
			Vector3.new(0.5, 3, 14),
			CFrame.new(side * 14, 70, -52),
			Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, vipModel
		)
	end
	createPart("VIPRailing_Front",
		Vector3.new(28, 3, 0.5),
		CFrame.new(0, 70, -45),
		Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, vipModel
	)

	addPointLight(vipBox, Color3.fromRGB(255, 215, 80), 1.5, 18)

	createPart("RedCarpet",
		Vector3.new(6, 0.2, 14),
		CFrame.new(0, 69.1, -52),
		Color3.fromRGB(180, 20, 20), Enum.Material.SmoothPlastic, vipModel
	)"""

cb = cb.replace(old_vip_code, new_vip_code)

with open(cb_path, "w", encoding="utf-8") as f:
    f.write(cb)
print("3. ColosseumBuilder.luau fixed!")

# ========================================================
# 4. FIX VIPPassHandler.luau (Add timeout on WaitForChild)
# ========================================================
vip_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\VIPPassHandler.luau"
with open(vip_path, "r", encoding="utf-8") as f:
    vip = f.read()

old_vip_wait = """local arena = workspace:WaitForChild("DilemmaArena")
local colosseum = arena:WaitForChild("ColosseumStructure")
local vipBox = colosseum:WaitForChild("ImperialVIPBox")
local vipGate = vipBox:WaitForChild("VIPGateSensor") :: Part"""

new_vip_wait = """local arena = workspace:WaitForChild("DilemmaArena", 15) :: Folder?
if not arena then return end
local colosseum = arena:WaitForChild("ColosseumStructure", 15) :: Folder?
if not colosseum then return end

-- Dynamically listen for ImperialVIPBox when ColosseumBuilder finishes
local function setupVIPGate(vipBox: Instance)
	local vipGate = vipBox:WaitForChild("VIPGateSensor", 10) :: Part?
	if not vipGate then return end
	
	vipGate.Touched:Connect(onGateTouched)
	print(">> [VIP] Gate Sensor terhubung! <<")
end

local existingVIP = colosseum:FindFirstChild("ImperialVIPBox")
if existingVIP then
	setupVIPGate(existingVIP)
end
colosseum.ChildAdded:Connect(function(child)
	if child.Name == "ImperialVIPBox" then
		setupVIPGate(child)
	end
end)"""

# In VIPPassHandler, definition of onGateTouched is below the waits!
# So we need to put setupVIPGate AFTER onGateTouched!
old_vip_full = """local arena = workspace:WaitForChild("DilemmaArena")
local colosseum = arena:WaitForChild("ColosseumStructure")
local vipBox = colosseum:WaitForChild("ImperialVIPBox")
local vipGate = vipBox:WaitForChild("VIPGateSensor") :: Part

local debounceList: {[number]: boolean} = {}"""

new_vip_full = """local arena = workspace:WaitForChild("DilemmaArena", 15) :: Folder?
local colosseum = arena and arena:WaitForChild("ColosseumStructure", 15) :: Folder?

local debounceList: {[number]: boolean} = {}"""

vip = vip.replace(old_vip_full, new_vip_full)

# At the bottom of VIPPassHandler:
old_bottom = """vipGate.Touched:Connect(onGateTouched)

print(">> [SUKSES] VIPPassHandler Imperial Gate Resmi Aktif! <<")"""

new_bottom = """if colosseum then
	local function wireGate(vipBox: Instance)
		local vipGate = vipBox:WaitForChild("VIPGateSensor", 10) :: Part?
		if vipGate then
			vipGate.Touched:Connect(onGateTouched)
			print(">> [VIP] Gate Sensor terhubung! <<")
		end
	end

	local cur = colosseum:FindFirstChild("ImperialVIPBox")
	if cur then wireGate(cur) end
	colosseum.ChildAdded:Connect(function(c)
		if c.Name == "ImperialVIPBox" then wireGate(c) end
	end)
end

print(">> [SUKSES] VIPPassHandler Imperial Gate Resmi Aktif! <<")"""

vip = vip.replace(old_bottom, new_bottom)

with open(vip_path, "w", encoding="utf-8") as f:
    f.write(vip)
print("4. VIPPassHandler.luau fixed!")

# ========================================================
# 5. FIX GraphicsOverhaulInstaller.luau (Particle texture)
# ========================================================
go_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\GraphicsOverhaulInstaller.luau"
with open(go_path, "r", encoding="utf-8") as f:
    go = f.read()

go = go.replace('rbxassetid://6880497226', 'rbxasset://textures/particles/sparkles_main.dds')

with open(go_path, "w", encoding="utf-8") as f:
    f.write(go)
print("5. GraphicsOverhaulInstaller.luau fixed!")

# ========================================================
# 6. FIX PanicFeedbackController.luau (Audio IDs)
# ========================================================
pf_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\client\PanicFeedbackController.luau"
with open(pf_path, "r", encoding="utf-8") as f:
    pf = f.read()

pf = pf.replace('heartbeatSound.SoundId = "rbxassetid://9113590730"', 'heartbeatSound.SoundId = "rbxasset://sounds/bass.wav"')
pf = pf.replace('tickSound.SoundId = "rbxassetid://6895079072"', 'tickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"')

with open(pf_path, "w", encoding="utf-8") as f:
    f.write(pf)
print("6. PanicFeedbackController.luau fixed!")

# ========================================================
# 7. FIX MasterInstaller.luau (Audio assets + BindableEvent)
# ========================================================
mi_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\MasterInstaller.luau"
with open(mi_path, "r", encoding="utf-8") as f:
    mi = f.read()

# WinStreakChanged is BindableEvent, not RemoteEvent
mi = mi.replace('"WinStreakChanged",\n\t"UpdateOverheadTitle",', '"UpdateOverheadTitle",')
mi = mi.replace('"ServerAddCoins",', '"WinStreakChanged",\n\t"ServerAddCoins",')

# Audio IDs
mi = mi.replace('"rbxassetid://6895079072"', '"rbxasset://sounds/electronicpingshort.wav"')
mi = mi.replace('"rbxassetid://9113590730"', '"rbxasset://sounds/bell.wav"')

with open(mi_path, "w", encoding="utf-8") as f:
    f.write(mi)
print("7. MasterInstaller.luau fixed!")

# ========================================================
# 8. FIX StatsServerHandler.luau (DataStore debounce)
# ========================================================
ssh_path = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\StatsServerHandler.luau"
with open(ssh_path, "r", encoding="utf-8") as f:
    ssh = f.read()

old_ssh_save = """local function savePlayerStats(player: Player)
    if not PlayerDataStore then return end"""
new_ssh_save = """local lastSavedStats: { [number]: number } = {}
local function savePlayerStats(player: Player)
    if not PlayerDataStore then return end
    local now = os.clock()
    if lastSavedStats[player.UserId] and (now - lastSavedStats[player.UserId]) < 4 then
        return
    end
    lastSavedStats[player.UserId] = now"""

ssh = ssh.replace(old_ssh_save, new_ssh_save)
with open(ssh_path, "w", encoding="utf-8") as f:
    f.write(ssh)
print("8. StatsServerHandler.luau fixed!")
