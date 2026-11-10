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
		local profile = ctxData.Services.ProfileService.GetProfile(player)
		local secondChanceUsed = false

		if profile then
			-- Second Chance consumes the one-time upgrade and skips the bank setback.
			if (profile.upgrades.Second_Chance or 0) > 0 then
				profile.upgrades.Second_Chance = 0
				secondChanceUsed = true
			else
				local insured = (profile.upgrades.Time_Insurance or 0) > 0
				local setbackFraction = insured
						and ctxData.Config.Balance.InsuranceSetbackFraction
					or ctxData.Config.Balance.DeathBankSetbackFraction

				local inComebackWindow = (comebackUntil[userId] or 0) > now
				if not inComebackWindow then
					local lost = profile.bankedTime * setbackFraction
					profile.bankedTime = math.max(0, profile.bankedTime - lost)
				end
			end

			profile.stats.deaths = (profile.stats.deaths or 0) + 1
			ctxData.Services.ProfileService.SetDirty(player)
		end

		local bonus = ctxData.Config.Game.ComebackBonus
		if (comebackUntil[userId] or 0) > now then
			bonus = bonus + ctxData.Config.Balance.ComebackFlatBonus
		end
		local restored = ctxData.Config.Balance.StartingTime + bonus

		ctxData.Services.TimeService.SetTime(player, restored)
		ctxData.Services.ZoneService.PlaceAtHub(player)
		ctxData.Services.ZoneService.SetPlayerZone(player, ctxData.Config.Zones.Hub.id)
		ctxData.Services.TimeService.Protect(player, ctxData.Config.Game.RespawnProtectionDuration)

		if ctxData.Services.BankService then
			ctxData.Services.BankService.SendUpdate(player)
		end
		if ctxData.Services.ProfileService then
			ctxData.Services.ProfileService.Sync(player)
		end

		comebackUntil[userId] = now + ctxData.Config.Game.ComebackWindow
		ctxData.state.processingDeath[userId] = false

		ctxData.Remotes.Get("TS_TimeUp"):FireClient(player)
		ctxData.Remotes.Get("TS_RespawnNotice"):FireClient(player, {
			restored = restored,
			keptUpgrades = true,
			secondChance = secondChanceUsed,
		})
		if secondChanceUsed then
			ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
				text = "Second Chance used — no bank penalty",
				kind = "announcement",
			})
		end
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
