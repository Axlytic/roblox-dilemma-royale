import os

src_dir = r"d:\VIBE CODE\roblox-dilemma-royale\src"
out_dir = r"d:\VIBE CODE\roblox-dilemma-royale\tools\batches"
os.makedirs(out_dir, exist_ok=True)

def make_chunk(files, base_folder, parent_expr, class_name):
    lines = []
    lines.append("local parent = " + parent_expr)
    lines.append("local function inject(name, src)")
    lines.append("    local s = parent:FindFirstChild(name)")
    lines.append("    if not s or s.ClassName ~= \"" + class_name + "\" then")
    lines.append("        if s then s:Destroy() end")
    lines.append("        s = Instance.new(\"" + class_name + "\")")
    lines.append("        s.Name = name")
    lines.append("        s.Parent = parent")
    lines.append("    end")
    lines.append("    s.Source = src")
    lines.append("    print(\"✅ Injected \" .. name)")
    lines.append("end\n")
    
    for f in files:
        name = os.path.splitext(f)[0]
        path = os.path.join(src_dir, base_folder, f)
        with open(path, "r", encoding="utf-8") as fh:
            content = fh.read()
        lines.append(f"-- === {name} ===")
        lines.append(f"inject(\"{name}\", [======[")
        lines.append(content)
        lines.append("]======])\n")
    lines.append("return 'OK: " + ", ".join([os.path.splitext(x)[0] for x in files]) + "'")
    return "\n".join(lines)

groups = [
    ("s1.lua", ["VIPPassHandler.luau", "ShopServerHandler.luau", "StatsServerHandler.luau"], "server", 'game:GetService("ServerScriptService")', "Script"),
    ("s2.lua", ["SkillServerHandler.luau", "OverheadTitleHandler.luau"], "server", 'game:GetService("ServerScriptService")', "Script"),
    ("s3.lua", ["DailyRewardsHandler.luau", "GraphicsOverhaulInstaller.luau"], "server", 'game:GetService("ServerScriptService")', "Script"),
    ("s4.lua", ["ColosseumBuilder.luau"], "server", 'game:GetService("ServerScriptService")', "Script"),
    ("s5.lua", ["DilemmaServer.luau"], "server", 'game:GetService("ServerScriptService")', "Script"),
    ("c1.lua", ["DoubleJumpClient.luau", "ShopController.luau", "SkillHUDController.luau"], "client", 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")', "LocalScript"),
    ("c2.lua", ["StatsMenuController.luau", "FavoritePromptController.luau"], "client", 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")', "LocalScript"),
    ("c3.lua", ["PanicFeedbackController.luau", "DailyRewardsController.luau"], "client", 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")', "LocalScript"),
]

for filename, filelist, folder, parent, cname in groups:
    code = make_chunk(filelist, folder, parent, cname)
    with open(os.path.join(out_dir, filename), "w", encoding="utf-8") as fh:
        fh.write(code)

print("8 micro-batches generated!")
