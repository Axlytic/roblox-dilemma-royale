import os

# 1. OverheadTitleHandler
p = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\OverheadTitleHandler.luau"
with open(p, "r", encoding="utf-8") as f:
    c = f.read()

c = c.replace("rbxassetid://6880497226", "rbxasset://textures/particles/sparkles_main.dds")
c = c.replace("rbxassetid://6880479568", "rbxasset://textures/particles/sparkles_main.dds")

old_event = """local evWinStreakChanged = getOrMakeEvent("WinStreakChanged") -- DilemmaServer fires this

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

new_event = """local function getOrMakeBindable(name: string): BindableEvent
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

c = c.replace(old_event, new_event)
with open(p, "w", encoding="utf-8") as f:
    f.write(c)
print("1. OverheadTitleHandler updated, len:", len(c))

# 2. ColosseumBuilder
cb_p = r"d:\VIBE CODE\roblox-dilemma-royale\src\server\ColosseumBuilder.luau"
with open(cb_p, "r", encoding="utf-8") as f:
    cb = f.read()

old_vip = """	-- ── IMPERIAL VIP BOX (ALWAYS GOLD — biome accent color) ──
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

new_vip = """	-- ── IMPERIAL VIP BOX (Container Model for VIPPassHandler) ──
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

cb = cb.replace(old_vip, new_vip)
with open(cb_p, "w", encoding="utf-8") as f:
    f.write(cb)
print("2. ColosseumBuilder updated, len:", len(cb))
