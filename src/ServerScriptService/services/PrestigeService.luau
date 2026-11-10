local PrestigeService = {}

local ctxData

local function nextTier(profile)
	local tiers = ctxData.Config.Balance.PrestigeTiers
	return tiers[(profile.prestige or 0) + 1]
end

local function sendUpdate(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return
	end
	local tier = nextTier(profile)
	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
		text = tier
				and ("Prestige %d needs %dh lived"):format(profile.prestige + 1, tier.hours)
			or "Maximum prestige reached",
		kind = "announcement",
	})
end

function PrestigeService.GetStealBonus(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return 0
	end
	return math.min((profile.prestige or 0) * 0.05, ctxData.Config.Balance.MaxPrestigeBonus)
end

function PrestigeService.Start(ctx)
	ctxData = ctx

	ctxData.Remotes.Get("TS_PrestigeRequest").OnServerInvoke = function(player)
		if not ctxData.Services.RateLimiter.Allow(player, "claim") then
			ctxData.Services.RateLimiter.Suspect(player, "claim")
			return { ok = false, reason = "rate" }
		end

		if ctxData.state.processingDeath[player.UserId] then
			return { ok = false, reason = "busy" }
		end

		local profile = ctxData.Services.ProfileService.GetProfile(player)
		if not profile then
			return { ok = false, reason = "no_profile" }
		end

		local tier = nextTier(profile)
		if not tier then
			return { ok = false, reason = "max_prestige" }
		end

		local requiredSeconds = tier.hours * 3600
		if (profile.totalTimeLived or 0) < requiredSeconds then
			return {
				ok = false,
				reason = "not_ready",
				required = requiredSeconds,
				current = profile.totalTimeLived,
			}
		end

		profile.prestige = (profile.prestige or 0) + 1
		profile.stats.prestiges = (profile.stats.prestiges or 0) + 1
		profile.lastPrestigeAt = os.time()

		if ctxData.Config.Economy.Prestige.ResetUpgrades then
			profile.upgrades = {}
		end
		if ctxData.Config.Economy.Prestige.ResetBanked then
			profile.bankedTime = 0
		end
		if ctxData.Config.Economy.Prestige.ResetActive then
			ctxData.Services.TimeService.SetTime(player, ctxData.Config.Balance.StartingTime)
		end
		if not ctxData.Config.Economy.Prestige.KeepBankCap then
			profile.bankCapIndex = 0
		end

		local title = "Prestige " .. tostring(profile.prestige)
		local hasTitle = false
		for _, existing in ipairs(profile.titles) do
			if existing == title then
				hasTitle = true
				break
			end
		end
		if not hasTitle and #profile.titles < ctxData.ProfileSchema.MaxTitles then
			table.insert(profile.titles, title)
		end

		ctxData.Services.ProfileService.SetDirty(player)
		ctxData.Services.ProfileService.Sync(player)
		if ctxData.Services.BankService then
			ctxData.Services.BankService.SendUpdate(player)
		end
		if ctxData.Services.CharacterService then
			ctxData.Services.CharacterService.ApplyStats(player)
		end

		ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
			text = ("PRESTIGE %d! +%d%% steal power"):format(
				profile.prestige,
				math.floor(PrestigeService.GetStealBonus(player) * 100)
			),
			kind = "steal",
		})
		ctxData.Remotes.Get("TS_Announcement"):FireClient(player, {
			text = ("%s reached Prestige %d"):format(player.DisplayName, profile.prestige),
		})

		return { ok = true, prestige = profile.prestige }
	end

	return true
end

function PrestigeService.OnProfileReady(player: Player)
	task.defer(sendUpdate, player)
end

return PrestigeService
