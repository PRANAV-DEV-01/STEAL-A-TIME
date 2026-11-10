local Players = game:GetService("Players")

local ZoneService = {}

local ctxData
local playerZone = {}

function ZoneService.Start(ctx)
	ctxData = ctx
	return true
end

local function characterRoot(player: Player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function notifyTutorial(player: Player, eventName: string)
	local tutorial = ctxData.Services.TutorialService
	if tutorial and tutorial.Notify then
		tutorial.Notify(player, eventName)
	end
end

function ZoneService.GetPlayerZone(player: Player)
	local root = characterRoot(player)
	if not root then
		return nil
	end
	return ctxData.Config.Zones.GetZoneAtPosition(root.Position)
end

function ZoneService.IsPlayerInHub(player: Player)
	local zone = ZoneService.GetPlayerZone(player)
	return zone ~= nil and zone.isHub
end

function ZoneService.GetCachedZoneId(player: Player)
	return playerZone[player.UserId]
end

function ZoneService.SetPlayerZone(player: Player, zoneId: string)
	playerZone[player.UserId] = zoneId
end

function ZoneService.OnPlayerProfileReady(player: Player)
	local zone = ZoneService.GetPlayerZone(player)
	if zone then
		ZoneService.SetPlayerZone(player, zone.id)
	end
end

function ZoneService.OnProfileReady(player: Player)
	ZoneService.OnPlayerProfileReady(player)
end

function ZoneService.GetRandomHubSpawn()
	local spawns = ctxData.Config.Zones.HubSpawnPoints
	local index = math.random(1, #spawns)
	return spawns[index]
end

function ZoneService.PlaceAtHub(player: Player)
	local root = characterRoot(player)
	if not root then
		return false
	end
	local spot = ZoneService.GetRandomHubSpawn()
	root.CFrame = CFrame.new(spot)
	root.AssemblyLinearVelocity = Vector3.zero
	ZoneService.SetPlayerZone(player, ctxData.Config.Zones.Hub.id)
	notifyTutorial(player, "returned_hub")
	return true
end

function ZoneService.PlaceAt(player: Player, position: Vector3)
	local root = characterRoot(player)
	if not root then
		return false
	end
	root.CFrame = CFrame.new(position)
	root.AssemblyLinearVelocity = Vector3.zero
	local zone = ctxData.Config.Zones.GetZoneAtPosition(position)
	if zone then
		ZoneService.SetPlayerZone(player, zone.id)
		if not zone.isHub then
			notifyTutorial(player, "entered_zone")
		else
			notifyTutorial(player, "returned_hub")
		end
	end
	return true
end

Players.PlayerRemoving:Connect(function(player)
	playerZone[player.UserId] = nil
end)

return ZoneService