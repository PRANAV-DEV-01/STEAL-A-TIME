local Hub = {
	id = "hub",
	name = "TIME SANCTUARY",
	center = Vector3.new(0, 0, 0),
	halfExtents = Vector3.new(250, 150, 250),
	dangerLevel = 0,
	decayPerSecond = 0,
	isHub = true,
	baseReward = 0,
	stealCooldown = 0,
	maxStealDistance = 0,
	minActiveToSteal = 0,
	recommended = "None",
	padSpawn = Vector3.new(0, 8, 150),
}

local NpcVillage = {
	id = "npc_village",
	name = "NPC Village",
	center = Vector3.new(-800, 0, -800),
	halfExtents = Vector3.new(200, 120, 200),
	dangerLevel = 1,
	decayPerSecond = 0.05,
	isHub = false,
	baseReward = 8,
	stealCooldown = 12,
	maxStealDistance = 22,
	minActiveToSteal = 10,
	recommended = "Starting zone",
	padSpawn = Vector3.new(-800, 8, -800),
}

local PlayerCity = {
	id = "player_city",
	name = "Player City",
	center = Vector3.new(900, 0, -900),
	halfExtents = Vector3.new(300, 150, 300),
	dangerLevel = 2,
	decayPerSecond = 0.15,
	isHub = false,
	baseReward = 12,
	stealCooldown = 20,
	maxStealDistance = 30,
	minActiveToSteal = 10,
	recommended = "Speed I + Power I",
	padSpawn = Vector3.new(900, 8, -900),
}

local TimeVaults = {
	id = "time_vaults",
	name = "Time Vaults",
	center = Vector3.new(-950, 0, 1050),
	halfExtents = Vector3.new(150, 120, 150),
	dangerLevel = 3,
	decayPerSecond = 0.10,
	isHub = false,
	baseReward = 25,
	stealCooldown = 30,
	maxStealDistance = 26,
	minActiveToSteal = 15,
	recommended = "Power III + Stealth I",
	padSpawn = Vector3.new(-950, 8, 1050),
}

local SecretAreas = {
	id = "secret",
	name = "Secret Areas",
	center = Vector3.new(300, 250, 400),
	halfExtents = Vector3.new(150, 150, 150),
	dangerLevel = 2,
	decayPerSecond = 0.15,
	isHub = false,
	baseReward = 30,
	stealCooldown = 45,
	maxStealDistance = 24,
	minActiveToSteal = 5,
	recommended = "Discovery required",
	padSpawn = Vector3.new(300, 260, 400),
}

local ZoneConfig = {
	Zones = {
		Hub = Hub,
		NpcVillage = NpcVillage,
		PlayerCity = PlayerCity,
		TimeVaults = TimeVaults,
		SecretAreas = SecretAreas,
	},

	Pads = {
		{
			zone = "npc_village",
			label = "NPC Village",
			position = Vector3.new(0, 1, 240),
			color = Color3.fromRGB(64, 200, 255),
		},
		{
			zone = "player_city",
			label = "Player City",
			position = Vector3.new(35, 1, 245),
			color = Color3.fromRGB(255, 120, 60),
		},
		{
			zone = "time_vaults",
			label = "Time Vaults",
			position = Vector3.new(-35, 1, 245),
			color = Color3.fromRGB(220, 90, 255),
		},
		{
			zone = "secret",
			label = "Secret Areas",
			position = Vector3.new(70, 1, 250),
			color = Color3.fromRGB(130, 255, 120),
		},
	},

	HubSpawnPoints = {
		Vector3.new(0, 8, 0),
		Vector3.new(25, 8, 10),
		Vector3.new(-25, 8, 10),
		Vector3.new(12, 8, -25),
		Vector3.new(-12, 8, -25),
		Vector3.new(30, 8, -10),
		Vector3.new(-30, 8, -10),
		Vector3.new(0, 8, 30),
		Vector3.new(40, 8, 20),
		Vector3.new(-40, 8, 20),
	},

	NpcPillars = {
		{
			id = "NPC_TimeKeeper01",
			zone = "npc_village",
			position = Vector3.new(-780, 12, -770),
			pool = 40,
			respawnTime = 30,
		},
		{
			id = "NPC_TimeKeeper02",
			zone = "npc_village",
			position = Vector3.new(-820, 12, -770),
			pool = 40,
			respawnTime = 30,
		},
		{
			id = "NPC_TimeKeeper03",
			zone = "npc_village",
			position = Vector3.new(-780, 12, -830),
			pool = 40,
			respawnTime = 30,
		},
		{
			id = "NPC_TimeKeeper04",
			zone = "npc_village",
			position = Vector3.new(-820, 12, -830),
			pool = 40,
			respawnTime = 30,
		},
	},
}

function ZoneConfig.ForId(zoneId: string)
	for _, zone in ZoneConfig.Zones do
		if zone.id == zoneId then
			return zone
		end
	end
	return nil
end

function ZoneConfig.GetZoneAtPosition(position: Vector3)
	for _, zone in ZoneConfig.Zones do
		local rel = position - zone.center
		local abs = Vector3.new(math.abs(rel.X), math.abs(rel.Y), math.abs(rel.Z))
		if abs.X <= zone.halfExtents.X and abs.Y <= zone.halfExtents.Y and abs.Z <= zone.halfExtents.Z then
			return zone
		end
	end
	return nil
end

function ZoneConfig.IsHubPosition(position: Vector3)
	local zone = ZoneConfig.GetZoneAtPosition(position)
	return zone ~= nil and zone.isHub
end

return ZoneConfig