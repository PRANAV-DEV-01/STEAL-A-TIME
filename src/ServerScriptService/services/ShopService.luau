local ShopService = {}

local ctxData

local function feedback(player: Player, text: string, kind: string)
	ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = text, kind = kind })
end

local function upgradeCost(def, level: number)
	-- Repeatable upgrades get more expensive per level.
	return math.floor(def.cost * math.max(1, level + 1))
end

local function applyCharacter(player: Player)
	local characterService = ctxData.Services.CharacterService
	if characterService and characterService.ApplyStats then
		characterService.ApplyStats(player)
	end
end

local function buyUpgrade(player: Player, profile, id: any)
	if type(id) ~= "string" then
		return false, "invalid"
	end
	local def = ctxData.Config.Balance.Upgrades[id]
	if not def then
		return false, "unknown_item"
	end

	local level = profile.upgrades[id] or 0
	if level >= def.maxLevel then
		return false, "max_level"
	end

	local cost = upgradeCost(def, level)
	if profile.bankedTime < cost then
		return false, "insufficient_bank"
	end

	profile.bankedTime -= cost
	profile.upgrades[id] = level + 1
	profile.stats.purchases = (profile.stats.purchases or 0) + 1
	ctxData.Services.ProfileService.SetDirty(player)
	applyCharacter(player)
	return true, nil, ("%s level %d"):format(id, level + 1), cost
end

local function buyPet(player: Player, profile, id: any)
	if type(id) ~= "string" then
		return false, "invalid"
	end
	local def = ctxData.Config.Balance.Pets[id]
	if not def then
		return false, "unknown_item"
	end
	if profile.pets[id] then
		-- Toggle equip for owned pets instead of double charging.
		profile.pets[id].equipped = not profile.pets[id].equipped
		ctxData.Services.ProfileService.SetDirty(player)
		return true, nil, ("%s %s"):format(id, profile.pets[id].equipped and "equipped" or "unequipped"), 0
	end
	if def.cost <= 0 then
		return false, "not_for_sale"
	end
	if profile.bankedTime < def.cost then
		return false, "insufficient_bank"
	end

	profile.bankedTime -= def.cost
	profile.pets[id] = { level = 1, xp = 0, equipped = true }
	profile.stats.purchases = (profile.stats.purchases or 0) + 1
	ctxData.Services.ProfileService.SetDirty(player)
	return true, nil, ("Adopted %s"):format(id), def.cost
end

local function buyBankCap(player: Player, profile)
	local nextLevel = (profile.bankCapIndex or 0) + 1
	local maxLevel = #ctxData.Config.Balance.BankCapLevels - 1
	if nextLevel > maxLevel then
		return false, "max_level"
	end
	local cost = ctxData.Config.Balance.BankCapCosts[nextLevel + 1] or 0
	if profile.bankedTime < cost then
		return false, "insufficient_bank"
	end

	profile.bankedTime -= cost
	profile.bankCapIndex = nextLevel
	profile.stats.purchases = (profile.stats.purchases or 0) + 1
	ctxData.Services.ProfileService.SetDirty(player)
	ctxData.Services.BankService.SendUpdate(player)
	return true, nil, ("Bank cap %ds"):format(ctxData.Config.Balance.BankCapLevels[nextLevel + 1]), cost
end

local function handlePurchase(player: Player, payload: any)
	if type(payload) ~= "table" then
		ctxData.Services.RateLimiter.Suspect(player, "purchase")
		return { ok = false, reason = "invalid" }
	end
	if not ctxData.Services.RateLimiter.Allow(player, "purchase") then
		ctxData.Services.RateLimiter.Suspect(player, "purchase")
		return { ok = false, reason = "rate" }
	end
	if ctxData.state.processingDeath[player.UserId] or ctxData.Services.TimeDeathService.IsProcessing(player) then
		return { ok = false, reason = "busy" }
	end

	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return { ok = false, reason = "no_profile" }
	end

	local kind = payload.kind
	local id = payload.id
	local ok, reason, message, cost

	if kind == "upgrade" then
		ok, reason, message, cost = buyUpgrade(player, profile, id)
	elseif kind == "pet" then
		ok, reason, message, cost = buyPet(player, profile, id)
	elseif kind == "bankcap" then
		ok, reason, message, cost = buyBankCap(player, profile)
	else
		return { ok = false, reason = "invalid" }
	end

	if not ok then
		return { ok = false, reason = reason }
	end

	ctxData.Services.ProfileService.Sync(player)
	feedback(player, message .. (cost and ("  (-%ds)"):format(cost) or ""), "announcement")

	local tutorial = ctxData.Services.TutorialService
	if tutorial and tutorial.Notify then
		tutorial.Notify(player, "purchased")
	end

	return { ok = true, cost = cost or 0 }
end

function ShopService.Start(ctx)
	ctxData = ctx
	local remote = ctxData.Remotes.Get("TS_PurchaseRequest")
	remote.OnServerInvoke = function(player, payload)
		local ok, result = pcall(handlePurchase, player, payload)
		if ok then
			return result
		end
		warn(("%s shop error: %s"):format(ctxData.Config.Game.LogPrefix, tostring(result)))
		return { ok = false, reason = "server_error" }
	end
	return true
end

return ShopService
