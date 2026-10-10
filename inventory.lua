local dm = fs.read("game.rbxl", "rbxl")
local ws
for _, i in ipairs(dm:GetChildren()) do if i.ClassName == "Workspace" then ws = i break end end
print("GameWorkspace children:")
for _, c in ipairs(ws:GetChildren()) do
  print("  " .. c.ClassName .. " :: " .. tostring(c.Name))
end