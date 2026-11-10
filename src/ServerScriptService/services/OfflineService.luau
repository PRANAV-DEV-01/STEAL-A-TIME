local OfflineService = {}

local ctxData

local function sendUpdate(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end
	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
		text = profile.offlinePending > 0
				and ("Offline time ready: +%ds"):format(math.floor(profile.offlinePending))
			or "",
		kind = "announcement",
	})
end

function OfflineService.OnProfileReady(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end

	local lastSeen = profile.lastSeenAt or 0
	local now = os.time()
	if lastSeen <= 0 or lastSeen > now then
		profile.lastSeenAt = now
		return
	end

	local hours = math.clamp(
		(now - lastSeen) / 3600,
		0,
		ctxData.Config.Balance.OfflineEarningsMaxHours
	)

	if hours >= ctxData.Config.Economy.Offline.MinHours then
		local earned = profile.bankedTime
			* ctxData.Config.Balance.OfflineEarningsFractionPerHour
			* hours
		earned = math.min(earned, ctxData.Config.Balance.OfflineEarningsCap)
		earned = math.floor(earned)
		if earned > 0 then
			profile.offlinePending = math.min(
				(profile.offlinePending or 0) + earned,
				ctxData.Config.Balance.OfflineEarningsCap
			)
			profile.offlineEarningsAt = now
			ctxData.Services.ProfileService.SetDirty(player)
			task.defer(sendUpdate, player)
		end
	end

	profile.lastSeenAt = now
	ctxData.Services.ProfileService.SetDirty(player)
end

function OfflineService.Start(ctx)
	ctxData = ctx

	ctxData.Remotes.Get("TS_ClaimOffline").OnServerInvoke = function(player)
		if not ctxData.Services.RateLimiter.Allow(player, "claim") then
			ctxData.Services.RateLimiter.Suspect(player, "claim")
			return { ok = false, reason = "rate" }
		end

		local profile = ctxData.Services.ProfileService.GetProfile(player)
		if not profile then
			return { ok = false, reason = "no_profile" }
		end

		local pending = math.floor(profile.offlinePending or 0)
		if pending <= 0 then
			return { ok = false, reason = "nothing" }
		end

		local cap = ctxData.ProfileSchema.BankCap(profile)
		local room = math.max(0, cap - profile.bankedTime)
		local credited = math.min(pending, math.floor(room))
		if credited <= 0 then
			return { ok = false, reason = "bank_full" }
		end

		profile.offlinePending = pending - credited
		profile.bankedTime += credited
		ctxData.Services.ProfileService.SetDirty(player)
		ctxData.Services.ProfileService.Sync(player)
		if ctxData.Services.BankService then
			ctxData.Services.BankService.SendUpdate(player)
		end
		ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
			text = ("Collected %ds offline time"):format(credited),
			kind = "steal",
		})
		return { ok = true, amount = credited }
	end

	return true
end

return OfflineService
