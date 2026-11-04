--!strict
-- ============================================================
-- ★ DILEMMA ROYALE: MASTER INSTALLER v2.0 ★
-- Jalankan script ini SEKALI di Command Bar Roblox Studio:
-- game:GetService("ServerScriptService"):FindFirstChild("MasterInstaller"):Clone().Parent = workspace
-- ATAU: Paste ke Command Bar dan tekan Enter
--
-- Fungsi: Membuat seluruh struktur ServerScriptService + StarterPlayerScripts
-- secara otomatis dari kode terbaru.
-- ============================================================

local SSS   = game:GetService("ServerScriptService")
local SPS   = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS    = game:GetService("ReplicatedStorage")

-- =========================================================
-- STEP 1: REPLICATEDSTORAGE SETUP
-- =========================================================
local eventsFolder = RS:FindFirstChild("DilemmaEvents") :: Folder?
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "DilemmaEvents"
	eventsFolder.Parent = RS
	print("[Installer] ✅ DilemmaEvents folder created in ReplicatedStorage")
end

-- RemoteEvents
local remoteEvents = {
	"PanicMode",
	"RoundWon",
	"UpdateOverheadTitle",
	"DailyRewardAvailable",
}
for _, name in remoteEvents do
	if not eventsFolder:FindFirstChild(name) then
		local ev = Instance.new("RemoteEvent")
		ev.Name   = name
		ev.Parent = eventsFolder
		print("[Installer] ✅ RemoteEvent created:", name)
	end
end

-- RemoteFunctions
local remoteFunctions = {
	"ClaimDailyReward",
	"GetDailyStatus",
}
for _, name in remoteFunctions do
	if not eventsFolder:FindFirstChild(name) then
		local rf = Instance.new("RemoteFunction")
		rf.Name   = name
		rf.Parent = eventsFolder
		print("[Installer] ✅ RemoteFunction created:", name)
	end
end

-- BindableEvents (server-internal)
local bindableEvents = {
	"WinStreakChanged",
	"ServerAddCoins",
	"ServerGrantConsumable",
	"ServerGrantTitle",
	"ServerGrantCosmetic",
}
for _, name in bindableEvents do
	if not eventsFolder:FindFirstChild(name) then
		local be = Instance.new("BindableEvent")
		be.Name   = name
		be.Parent = eventsFolder
		print("[Installer] ✅ BindableEvent created:", name)
	end
end

-- BindableFunctions (server-internal)
local bindableFunctions = {
	"ApplyBiomeLighting",
	"BuildColosseum",
}
for _, name in bindableFunctions do
	if not RS:FindFirstChild(name) then
		local bf = Instance.new("BindableFunction")
		bf.Name   = name
		bf.Parent = RS
		print("[Installer] ✅ BindableFunction created:", name)
	end
end

-- =========================================================
-- STEP 2: SOUND SETUP (di SoundService)
-- =========================================================
local SoundService = game:GetService("SoundService")
local sounds = {
	{ name = "SFX_Tick",   id = "rbxasset://sounds/electronicpingshort.wav" },
	{ name = "SFX_Alarm",  id = "rbxasset://sounds/bell.wav" },
	{ name = "SFX_Rumble", id = "rbxasset://sounds/electronicpingshort.wav" },
	{ name = "SFX_Win",    id = "rbxasset://sounds/bell.wav" },
}
for _, s in sounds do
	if not SoundService:FindFirstChild(s.name) then
		local sound     = Instance.new("Sound")
		sound.Name      = s.name
		sound.SoundId   = s.id
		sound.Volume    = 0.5
		sound.Parent    = SoundService
		print("[Installer] ✅ Sound created:", s.name)
	end
end

-- =========================================================
-- STEP 3: ARENA PARTS (minimal check — ColosseumBuilder builds the full thing)
-- =========================================================
local arenaFolder = workspace:FindFirstChild("DilemmaArena") :: Folder?
if not arenaFolder then
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "DilemmaArena"
	arenaFolder.Parent = workspace
	print("[Installer] ✅ DilemmaArena folder created in Workspace")
end

-- Minimal DilemmaScreen for DilemmaServer to find
local function ensurePart(name: string, parent: Instance, size: Vector3, pos: Vector3, color: Color3): Part
	local existing = parent:FindFirstChild(name) :: Part?
	if existing and existing:IsA("Part") then return existing end
	local p = Instance.new("Part")
	p.Name     = name; p.Size = size; p.Position = pos
	p.Color    = color; p.Anchored = true; p.CanCollide = true
	p.Parent   = parent
	return p
end

local screen = arenaFolder:FindFirstChild("DilemmaScreen")
if not screen then
	local screenPart = ensurePart("DilemmaScreen", arenaFolder,
		Vector3.new(20, 10, 1), Vector3.new(0, 56, -50), Color3.fromRGB(20, 20, 20))

	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = screenPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	frame.Parent = sg

	local function makeLabel(name: string, pos: UDim2, size: UDim2, fontSize: number): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Name = name; lbl.Size = size; lbl.Position = pos
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
		lbl.Text = name
		lbl.Parent = frame
		return lbl
	end

	makeLabel("TitleText",    UDim2.new(0, 0, 0, 0),    UDim2.new(1, 0, 0.3, 0), 20)
	makeLabel("QuestionText", UDim2.new(0, 0, 0.3, 0),  UDim2.new(1, 0, 0.45, 0), 16)
	makeLabel("TimerText",    UDim2.new(0, 0, 0.75, 0), UDim2.new(1, 0, 0.25, 0), 18)

	print("[Installer] ✅ DilemmaScreen with SurfaceGui created")
end

-- =========================================================
-- STEP 4: INSTRUCTION SUMMARY
-- =========================================================
print([[
╔══════════════════════════════════════════════════════════════╗
║       DILEMMA ROYALE — MASTER INSTALLER v2.0 COMPLETE       ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  📦 ReplicatedStorage:                                       ║
║     DilemmaEvents/ (RemoteEvents + RemoteFunctions)          ║
║     ApplyBiomeLighting (BindableFunction)                    ║
║     BuildColosseum (BindableFunction)                        ║
║                                                              ║
║  🔊 SoundService: SFX_Tick, Alarm, Rumble, Win               ║
║                                                              ║
║  📺 Workspace: DilemmaArena + DilemmaScreen                  ║
║                                                              ║
║  ⚠️  NEXT STEPS — Paste these scripts manually:              ║
║                                                              ║
║  SERVER (ServerScriptService):                               ║
║    1. DilemmaServer.luau         (Game Loop v4)              ║
║    2. ColosseumBuilder.luau      (Multi-Biome v2)            ║
║    3. GraphicsOverhaulInstaller.luau (Future Lighting)       ║
║    4. OverheadTitleHandler.luau  (Rank + Aura + VIP)         ║
║    5. DailyRewardsHandler.luau   (7-Day Daily Rewards)       ║
║    6. StatsServerHandler.luau    (RPG Stats)                 ║
║    7. SkillServerHandler.luau    (Q/E/R Skills)              ║
║    8. ShopServerHandler.luau     (Shop)                      ║
║    9. VIPPassHandler.luau        (VIP Gate)                  ║
║                                                              ║
║  CLIENT (StarterPlayerScripts):                              ║
║    1. DailyRewardsController.luau  (Calendar UI)             ║
║    2. PanicFeedbackController.luau (Camera Shake + Vignette) ║
║    3. FavoritePromptController.luau (Post-Win Popup)         ║
║    4. SkillHUDController.luau      (Q/E/R HUD)               ║
║    5. StatsMenuController.luau     (RPG Stats UI)            ║
║    6. ShopController.luau          (Shop UI)                 ║
║    7. DoubleJumpClient.luau        (Multi-Jump)              ║
║                                                              ║
║  ✅ Install order: GraphicsOverhaul → ColosseumBuilder       ║
║     → DilemmaServer → all others                            ║
╚══════════════════════════════════════════════════════════════╝
]])

print("[MasterInstaller v2.0] ✅ Selesai. Ikuti petunjuk di atas untuk paste semua script.")
