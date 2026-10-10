local Players = game:GetService("Players")

local TimeDeathService = {}

local ctxData
local comebackUntil = {}

function TimeDeathService.Start(ctx)
	ctxData = ctx
	return true
end

function TimeDeathService.IsProcessing(player: Player)
	return ctxData.state.processingDeath[player.UserId] or false
end

function TimeDeathService.HandleTimeUp(player: Player)
	local userId = player.UserId
	if ctxData.state.processingDeath[userId] then
		return
	end
	ctxData.state.processingDeath[userId] = true

	local ok, err = pcall(function()
		local now = os.clock()
		local profile = ctxData.services.ProfileService.GetProfile(player)

		if profile then
			local insured = (profile.upgrades.Time_Insurance or 0) > 0
			local setbackFraction = insured
					and ctxData.Config.Balance.InsuranceSetbackFraction
				or ctxData.Config.Balance.DeathBankSetbackFraction

			local inComebackWindow = (comebackUntil[userId] or 0) > now
			if not inComebackWindow then
				local lost = profile.bankedTime * setbackFraction
				profile.bankedTime = math.max(0, profile.bankedTime - lost)
			end

			profile.stats.deaths = (profile.stats.deaths or 0) + 1
			ctxData.services.ProfileService.SetDirty(player)
		end

		local bonus = ctxData.Config.Game.ComebackBonus
		if (comebackUntil[userId] or 0) > now then
			bonus = bonus + ctxData.Config.Balance.ComebackFlatBonus
		end
		local restored = ctxData.Config.Balance.StartingTime + bonus

		ctxData.services.TimeService.SetTime(player, restored)
		ctxData.services.ZoneService.PlaceAtHub(player)
		ctxData.services.ZoneService.SetPlayerZone(player, ctxData.Config.Zones.Hub.id)
		ctxData.services.TimeService.Protect(player, ctxData.Config.Game.RespawnProtectionDuration)

		comebackUntil[userId] = now + ctxData.Config.Game.ComebackWindow

		local timeUp = ctxData.Remotes.Get("TS_TimeUp")
		timeUp:FireClient(player)

		local respawnNotice = ctxData.Remotes.Get("TS_RespawnNotice")
		respawnNotice:FireClient(player, { restored = restored, keptUpgrades = true })
	end)

	if not ok then
		warn(ctxData.Config.Game.LogPrefix .. " TimeDeathService error: " .. tostring(err))
	end

	ctxData.state.processingDeath[userId] = false
end

function TimeDeathService.IsProtectedByComeback(player: Player)
	local userId = player.UserId
	return (comebackUntil[userId] or 0) > os.clock()
end

Players.PlayerRemoving:Connect(function(player)
	comebackUntil[player.UserId] = nil
end)

return TimeDeathService