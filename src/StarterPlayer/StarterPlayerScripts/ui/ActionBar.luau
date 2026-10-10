local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ActionBar = {}

local api
local targetLabel
local targetList = {}
local pillarsCache = {}
local pillarsDirtyAt = 0

local function playerRoot(thisPlayer: Player)
	local character = thisPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function refreshPillarCache()
	if os.clock() < pillarsDirtyAt then
		return
	end
	pillarsDirtyAt = os.clock() + 5
	pillarsCache = {}
	local world = Workspace:FindFirstChild(api.Config.Game.WorldFolderName)
	if not world then
		return
	end
	local zones = world:FindFirstChild("Zones")
	if not zones then
		return
	end
	for _, instance in zones:GetDescendants() do
		if instance:IsA("BasePart") then
			local id = instance:GetAttribute("TSNpcId")
			if type(id) == "string" then
				table.insert(pillarsCache, { id = id, position = instance.Position })
			end
		end
	end
end

local function recomputeTarget()
	local myRoot = playerRoot(api.Player)
	if not myRoot then
		targetList = {}
		return
	end
	local myPos = myRoot.Position
	local myZone = api.Config.Zones.GetZoneAtPosition(myPos)

	local bestKey
	local bestLabel
	local bestDistance = math.huge

	if myZone and not myZone.isHub then
		refreshPillarCache()
		for _, pillar in pillarsCache do
			local pillarZone = api.Config.Zones.GetZoneAtPosition(pillar.position)
			if not pillarZone or pillarZone.isHub or pillarZone.id ~= myZone.id then
				continue
			end
			local distance = (pillar.position - myPos).Magnitude
			if distance <= myZone.maxStealDistance and distance < bestDistance then
				bestDistance = distance
				bestKey = "npc:" .. pillar.id
				bestLabel = pillar.id .. "  (" .. tostring(math.floor(distance)) .. "m)"
			end
		end

		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer == api.Player then
				continue
			end
			local otherRoot = playerRoot(otherPlayer)
			if not otherRoot then
				continue
			end
			local otherZone = api.Config.Zones.GetZoneAtPosition(otherRoot.Position)
			if not otherZone or otherZone.isHub or otherZone.id ~= myZone.id then
				continue
			end
			local distance = (otherRoot.Position - myPos).Magnitude
			if distance <= myZone.maxStealDistance and distance < bestDistance then
				bestDistance = distance
				bestKey = "player:" .. tostring(otherPlayer.UserId)
				bestLabel = otherPlayer.Name .. "  (" .. tostring(math.floor(distance)) .. "m)"
			end
		end
	end

	targetList = {}
	if bestKey then
		targetList = { key = bestKey, label = bestLabel }
	end
end

function ActionBar.Create(createApi)
	api = createApi

	local frame = Instance.new("Frame")
	frame.Name = "ActionBar"
	frame.Size = UDim2.new(0, 240, 0, 90)
	frame.Position = UDim2.new(1, -250, 1, -100)
	frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Parent = api.Root

	targetLabel = Instance.new("TextLabel")
	targetLabel.Name = "Target"
	targetLabel.Size = UDim2.new(1, 0, 0.3, 0)
	targetLabel.BackgroundTransparency = 1
	targetLabel.Text = "No target"
	targetLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
	targetLabel.Font = Enum.Font.GothamMedium
	targetLabel.TextScaled = true
	targetLabel.Parent = frame

	local stealButton = Instance.new("TextButton")
	stealButton.Name = "StealButton"
	stealButton.Size = UDim2.new(0, 140, 0, 50)
	stealButton.Position = UDim2.new(0.5, -70, 1, -55)
	stealButton.BackgroundColor3 = Color3.fromRGB(255, 90, 70)
	stealButton.BorderSizePixel = 0
	stealButton.Text = "STEAL  [E]"
	stealButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stealButton.Font = Enum.Font.GothamBold
	stealButton.TextScaled = true
	stealButton.Parent = frame
	stealButton.Activated:Connect(function()
		ActionBar.Fire()
	end)

	task.spawn(function()
		while true do
			recomputeTarget()
			if targetList.key then
				targetLabel.Text = targetList.label
				targetLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
			else
				targetLabel.Text = "No target in range"
				targetLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
			end
			task.wait(1)
		end
	end)

	return ActionBar
end

function ActionBar.Fire()
	if not targetList.key then
		return
	end
	api.Remotes.Get("TS_StealRequest"):FireServer(targetList.key)
end

return ActionBar