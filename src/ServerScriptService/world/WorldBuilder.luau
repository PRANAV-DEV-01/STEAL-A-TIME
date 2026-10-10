local WorldBuilder = {}

local ctxData

local function ensureFolder(parent: Instance, name: string)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function part(properties: any)
	local p = Instance.new("Part")
	for key, value in properties do
		p[key] = value
	end
	return p
end

local function cylinder(properties: any)
	local c = Instance.new("Part")
	c.Shape = Enum.PartType.Cylinder
	for key, value in properties do
		c[key] = value
	end
	return c
end

local function sphere(properties: any)
	local s = Instance.new("Part")
	s.Shape = Enum.PartType.Ball
	for key, value in properties do
		s[key] = value
	end
	return s
end

local function buildHub()
	local zones = ctxData.Config.Zones
	local hub = ensureFolder(ctxData.world, "Hub")

	part({
		Name = "Hub_Floor",
		Size = Vector3.new(500, 2, 500),
		Position = Vector3.new(0, 0, 0),
		Anchored = true,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(40, 45, 60),
		Parent = hub,
	})

	cylinder({
		Name = "Hub_Ring",
		Size = Vector3.new(0.5, 480, 480),
		Position = Vector3.new(0, 1.2, 0),
		Orientation = Vector3.new(0, 0, 90),
		Anchored = true,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(64, 200, 255),
		CanCollide = false,
		Parent = hub,
	})

	local function clockTower(name: string, position: Vector3, height: number)
		cylinder({
			Name = name .. "_Pillar",
			Size = Vector3.new(6, height, 6),
			Position = position,
			Anchored = true,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(220, 190, 90),
			Parent = hub,
		})
		sphere({
			Name = name .. "_Face",
			Size = Vector3.new(10, 10, 10),
			Position = position + Vector3.new(0, height / 2 + 3, 0),
			Anchored = true,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 220, 120),
			Parent = hub,
		})
	end

	clockTower("Clock_Tower_Center", Vector3.new(0, 20, 0), 40)
	clockTower("Clock_Tower_NW", Vector3.new(-200, 12, -200), 24)
	clockTower("Clock_Tower_NE", Vector3.new(200, 12, -200), 24)
	clockTower("Clock_Tower_SW", Vector3.new(-200, 12, 200), 24)
	clockTower("Clock_Tower_SE", Vector3.new(200, 12, 200), 24)

	for index, spawnPoint in zones.HubSpawnPoints do
		cylinder({
			Name = "Spawn_Marker_" .. tostring(index),
			Size = Vector3.new(0.4, 3, 3),
			Position = spawnPoint + Vector3.new(0, 0.3, 0),
			Orientation = Vector3.new(0, 0, 90),
			Anchored = true,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(80, 220, 160),
			Parent = hub,
		})
	end

	for _, pad in zones.Pads do
		local padDir = Vector3.new(8, 1, 8)
		local padPart = part({
			Name = "Pad_" .. pad.zone,
			Size = padDir,
			Position = pad.position + Vector3.new(0, 0.5, 0),
			Anchored = true,
			Material = Enum.Material.Neon,
			Color = pad.color,
			Parent = hub,
		})
		padPart:SetAttribute("TSZonePad", pad.zone)

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "Popup"
		billboard.Size = UDim2.new(10, 0, 2, 0)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = false
		billboard.Parent = padPart

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = pad.label
		label.TextColor3 = pad.color
		label.TextStrokeTransparency = 0.5
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = billboard
	end
end

local function zoneColor(zone)
	if zone.dangerLevel == 1 then
		return Color3.fromRGB(64, 120, 200)
	elseif zone.dangerLevel == 2 then
		return Color3.fromRGB(220, 120, 60)
	elseif zone.dangerLevel == 3 then
		return Color3.fromRGB(150, 70, 220)
	end
	return Color3.fromRGB(60, 200, 90)
end

local function buildZones()
	local zones = ctxData.Config.Zones
	local zoneFolder = ensureFolder(ctxData.world, "Zones")

	for _, zone in zones.Zones do
		if zone.isHub then
			continue
		end

		local zoneRoot = ensureFolder(zoneFolder, "Zone_" .. zone.name)
		part({
			Name = "Zone_Floor",
			Size = Vector3.new(zone.halfExtents.X * 2, 2, zone.halfExtents.Z * 2),
			Position = zone.center + Vector3.new(0, 1, 0),
			Anchored = true,
			Material = Enum.Material.Neon,
			Color = zoneColor(zone),
			CanCollide = true,
			Parent = zoneRoot,
		})

		local labelPart = part({
			Name = "Zone_Label",
			Size = Vector3.new(1, 1, 1),
			Position = zone.center + Vector3.new(0, 30, 0),
			Anchored = true,
			Transparency = 1,
			CanCollide = false,
			Parent = zoneRoot,
		})

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "Sign"
		billboard.Size = UDim2.new(24, 0, 6, 0)
		billboard.StudsOffset = Vector3.new(0, 0, 0)
		billboard.Parent = labelPart

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0.5, 0)
		title.BackgroundTransparency = 1
		title.Text = zone.name
		title.TextColor3 = zoneColor(zone)
		title.Font = Enum.Font.GothamBold
		title.TextScaled = true
		title.Parent = billboard

		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, 0, 0.5, 0)
		sub.Position = UDim2.new(0, 0, 0.5, 0)
		sub.BackgroundTransparency = 1
		sub.Text = "DANGER " .. tostring(zone.dangerLevel)
		sub.TextColor3 = Color3.fromRGB(255, 255, 255)
		sub.Font = Enum.Font.GothamBold
		sub.TextScaled = true
		sub.Parent = billboard
	end

	for _, pillarDef in zones.NpcPillars do
		local zone = zones.ForId(pillarDef.zone)
		if not zone then
			continue
		end
		local zoneRoot = zoneFolder:FindFirstChild("Zone_" .. zone.name)
		if not zoneRoot then
			continue
		end

		local pillar = cylinder({
			Name = "Pillar_" .. pillarDef.id,
			Size = Vector3.new(12, 5, 5),
			Position = pillarDef.position + Vector3.new(0, 6, 0),
			Orientation = Vector3.new(0, 0, 90),
			Anchored = true,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 210, 90),
			Parent = zoneRoot,
		})
		pillar:SetAttribute("TSNpcId", pillarDef.id)

		sphere({
			Name = "Pillar_Orb",
			Size = Vector3.new(4, 4, 4),
			Position = pillarDef.position + Vector3.new(0, 14, 0),
			Anchored = true,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 240, 150),
			Parent = zoneRoot,
		})
	end
end

local function freezeLegacy()
	local legacyBaseplate = ctxData.world:FindFirstChild("Baseplate")
	if legacyBaseplate then
		local floor = legacyBaseplate:FindFirstChild("Baseplate") or legacyBaseplate:FindFirstChildOfClass("Part")
		if floor then
			floor.Anchored = true
			floor.CanCollide = true
			floor.Color = Color3.fromRGB(38, 40, 48)
		end
	end

	for _, instance in ctxData.world:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.Anchored = true
		end
	end

	for _, spawnLocation in ctxData.world:GetDescendants() do
		if spawnLocation:IsA("SpawnLocation") then
			spawnLocation.CFrame = CFrame.new(0, 8, 0)
			spawnLocation.Enabled = true
			spawnLocation.Neutral = true
		end
	end
end

function WorldBuilder.Start(ctx)
	ctxData = ctx

	local workspace = game:GetService("Workspace")
	ctxData.world = workspace:FindFirstChild(ctxData.Config.Game.WorldFolderName)
	if not ctxData.world then
		warn(("[%s] WorldBuilder: %s not found in Workspace"):format(ctxData.Config.Game.LogPrefix, ctxData.Config.Game.WorldFolderName))
		return false
	end

	freezeLegacy()
	buildHub()
	buildZones()
	return true
end

return WorldBuilder