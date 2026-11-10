local Workspace = game:GetService("Workspace")

local PadInteraction = {}

local api
local panels
local prompt
local promptLabel
local targets = {}
local targetsAt = 0
local current = nil
local lastZoneId = nil

local function playerRoot()
	local character = api.Player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function refreshTargets()
	targets = {}
	local world = Workspace:FindFirstChild(api.Config.Game.WorldFolderName)
	if not world then
		return
	end
	for _, instance in world:GetDescendants() do
		if instance:IsA("BasePart") then
			local zoneId = instance:GetAttribute("TSZonePad")
			if type(zoneId) == "string" then
				table.insert(targets, {
					kind = "zone",
					value = zoneId,
					position = instance.Position,
					label = "TRAVEL",
				})
			end
			local action = instance:GetAttribute("TSInteract")
			if type(action) == "string" then
				table.insert(targets, {
					kind = "action",
					value = action,
					position = instance.Position,
					label = string.upper(action),
				})
			end
		end
	end
end

local function recompute()
	local root = playerRoot()
	if not root then
		current = nil
		return
	end
	if os.clock() >= targetsAt then
		targetsAt = os.clock() + 5
		refreshTargets()
	end

	local best = nil
	local bestDistance = 16
	for _, target in targets do
		local distance = (target.position - root.Position).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			best = target
		end
	end
	current = best
end

local function activate()
	if not current then
		return false
	end
	if current.kind == "zone" then
		api.Remotes.Get("TS_TeleportRequest"):FireServer(current.value)
	elseif current.kind == "action" then
		panels.Toggle(current.value)
	end
	return true
end

function PadInteraction.Create(createApi, createPanels)
	api = createApi
	panels = createPanels

	prompt = Instance.new("Frame")
	prompt.Name = "PadPrompt"
	prompt.Size = UDim2.new(0, 280, 0, 58)
	prompt.Position = UDim2.new(0.5, -140, 1, -230)
	prompt.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	prompt.BackgroundTransparency = 0.15
	prompt.BorderSizePixel = 0
	prompt.Visible = false
	prompt.Parent = api.Root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = prompt

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(64, 200, 255)
	stroke.Thickness = 2
	stroke.Parent = prompt

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = prompt
	button.Activated:Connect(function()
		activate()
	end)

	promptLabel = Instance.new("TextLabel")
	promptLabel.Size = UDim2.new(1, -12, 1, 0)
	promptLabel.Position = UDim2.new(0, 6, 0, 0)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Text = ""
	promptLabel.TextColor3 = Color3.fromRGB(235, 240, 248)
	promptLabel.Font = Enum.Font.GothamBold
	promptLabel.TextSize = 17
	promptLabel.TextScaled = false
	promptLabel.TextWrapped = true
	promptLabel.Parent = prompt

	task.spawn(function()
		while true do
			task.wait(0.2)
			recompute()
			if current then
				local prefix = current.kind == "zone" and "TRAVEL: " or "OPEN: "
				promptLabel.Text = prefix .. tostring(current.label) .. "   [E] / TAP"
				prompt.Visible = true
			else
				prompt.Visible = false
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local zone = api.Config.Zones.GetZoneAtPosition((playerRoot() and playerRoot().Position) or Vector3.zero)
			local zoneId = zone and zone.id or "hub"
			if zoneId ~= lastZoneId then
				lastZoneId = zoneId
				if zone and not zone.isHub then
					-- Close hub panels when entering danger, so the HUD stays usable.
					panels.Close()
				end
			end
		end
	end)

	return PadInteraction
end

function PadInteraction.TryInteract()
	if prompt and prompt.Visible then
		return activate()
	end
	return false
end

return PadInteraction
