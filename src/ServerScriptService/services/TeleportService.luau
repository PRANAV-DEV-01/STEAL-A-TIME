local TeleportService = {}

local ctxData

local function placeOnPad(player: Player, zone)
	if not ctxData.services.RateLimiter.Allow(player, "teleport") then
		return false, "rate"
	end

	if ctxData.state.processingDeath[player.UserId] or ctxData.services.TimeDeathService.IsProcessing(player) then
		return false, "busy"
	end

	if not player.Character then
		return false, "no_character"
	end

	local ok = ctxData.services.ZoneService.PlaceAt(player, zone.padSpawn)
	if not ok then
		return false, "no_position"
	end

	ctxData.services.ZoneService.SetPlayerZone(player, zone.id)

	local feedback = ctxData.Remotes.Get("TS_Announcement")
	feedback:FireClient(player, { text = "Warped to " .. zone.name .. " (danger " .. tostring(zone.dangerLevel) .. ")" })
	return true
end

function TeleportService.Start(ctx)
	ctxData = ctx

	ctxData.Remotes.Get("TS_TeleportRequest").OnServerEvent:Connect(function(player, zoneId)
		if type(zoneId) ~= "string" then
			ctxData.services.RateLimiter.Suspect(player, "teleport")
			return
		end

		local zone = ctxData.Config.Zones.ForId(zoneId)
		if not zone then
			ctxData.services.RateLimiter.Suspect(player, "teleport")
			return
		end

		if zone.isHub then
			ctxData.services.ZoneService.PlaceAtHub(player)
			return
		end

		local ok, reason = placeOnPad(player, zone)
		local stealResult = ctxData.Remotes.Get("TS_Announcement")
		if not ok then
			stealResult:FireClient(player, { text = "Teleport failed (" .. tostring(reason) .. ")" })
		end
	end)

	return true
end

function TeleportService.TeleportTo(player: Player, zoneId: string)
	local zone = ctxData.Config.Zones.ForId(zoneId)
	if not zone then
		return false
	end
	return placeOnPad(player, zone)
end

return TeleportService