local Players = game:GetService("Players")

local TradeService = {}

local ctxData
local sessions = {}
local playerSession = {}

local function keyFor(a: number, b: number)
	if a < b then
		return tostring(a) .. "_" .. tostring(b)
	end
	return tostring(b) .. "_" .. tostring(a)
end

local function otherUser(session, userId: number): number
	if session.a == userId then
		return session.b
	end
	return session.a
end

local function viewFor(session, userId: number)
	local partnerId = otherUser(session, userId)
	local partner = Players:GetPlayerByUserId(partnerId)
	local state
	if session.accepted then
		state = "open"
	elseif userId == session.a then
		state = "outgoing"
	else
		state = "requested"
	end
	return {
		state = state,
		partner = partnerId,
		partnerName = partner and partner.DisplayName or ("User " .. tostring(partnerId)),
		offers = session.offers,
		confirmed = session.confirmed,
		expiresIn = math.max(0, math.floor(session.expiresAt - os.clock())),
	}
end

local function notify(session, stateOverride: string?)
	for _, userId in ipairs({ session.a, session.b }) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local payload = viewFor(session, userId)
			if stateOverride then
				payload.state = stateOverride
			end
			ctxData.Remotes.Get("TS_TradeUpdate"):FireClient(player, payload)
		end
	end
end

local function close(session, reason: string?)
	if not session then
		return
	end
	sessions[session.key] = nil
	playerSession[session.a] = nil
	playerSession[session.b] = nil
	local payload = { state = "ended", reason = reason }
	for _, userId in ipairs({ session.a, session.b }) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			ctxData.Remotes.Get("TS_TradeUpdate"):FireClient(player, payload)
		end
	end
end

local function execute(session)
	local playerA = Players:GetPlayerByUserId(session.a)
	local playerB = Players:GetPlayerByUserId(session.b)
	if not playerA or not playerB then
		close(session, "partner_left")
		return
	end
	local profileA = ctxData.Services.ProfileService.GetProfile(playerA)
	local profileB = ctxData.Services.ProfileService.GetProfile(playerB)
	if not profileA or not profileB then
		close(session, "no_profile")
		return
	end

	local offerA = math.floor(session.offers[session.a] or 0)
	local offerB = math.floor(session.offers[session.b] or 0)
	if profileA.bankedTime < offerA or profileB.bankedTime < offerB then
		close(session, "insufficient_bank")
		return
	end

	profileA.bankedTime = profileA.bankedTime - offerA + offerB
	profileB.bankedTime = profileB.bankedTime - offerB + offerA
	profileA.stats.trades = (profileA.stats.trades or 0) + 1
	profileB.stats.trades = (profileB.stats.trades or 0) + 1

	ctxData.Services.ProfileService.SetDirty(playerA)
	ctxData.Services.ProfileService.SetDirty(playerB)
	ctxData.Services.ProfileService.Sync(playerA)
	ctxData.Services.ProfileService.Sync(playerB)
	if ctxData.Services.BankService then
		ctxData.Services.BankService.SendUpdate(playerA)
		ctxData.Services.BankService.SendUpdate(playerB)
	end

	local feedback = ctxData.Remotes.Get("TS_Feedback")
	feedback:FireClient(playerA, { text = ("Trade complete (%+ds)"):format(offerB - offerA), kind = "steal" })
	feedback:FireClient(playerB, { text = ("Trade complete (%+ds)"):format(offerA - offerB), kind = "steal" })
	close(session, "complete")
end

local function handle(player: Player, payload: any)
	if type(payload) ~= "table" then
		return { ok = false, reason = "invalid" }
	end
	if not ctxData.Services.RateLimiter.Allow(player, "trade") then
		ctxData.Services.RateLimiter.Suspect(player, "trade")
		return { ok = false, reason = "rate" }
	end

	local action = payload.action
	local key = playerSession[player.UserId]
	local session = key and sessions[key] or nil
	local cfg = ctxData.Config.Social.Trade

	if action == "request" then
		local targetId = tonumber(payload.target)
		if not targetId or targetId == player.UserId then
			return { ok = false, reason = "invalid_target" }
		end
		local target = Players:GetPlayerByUserId(targetId)
		if not target then
			return { ok = false, reason = "offline" }
		end
		if sessions[keyFor(player.UserId, targetId)] then
			return { ok = false, reason = "busy" }
		end
		local tradeKey = keyFor(player.UserId, targetId)
		local newSession = {
			key = tradeKey,
			a = player.UserId,
			b = targetId,
			offers = {},
			confirmed = {},
			accepted = false,
			expiresAt = os.clock() + cfg.SessionSeconds,
		}
		sessions[tradeKey] = newSession
		playerSession[player.UserId] = tradeKey
		playerSession[targetId] = tradeKey
		notify(newSession)
		return { ok = true }
	end

	if not session then
		return { ok = false, reason = "no_session" }
	end

	if action == "respond" then
		if player.UserId ~= session.b then
			return { ok = false, reason = "not_invited" }
		end
		if payload.accept == true then
			session.accepted = true
			session.expiresAt = os.clock() + cfg.SessionSeconds
			notify(session)
			return { ok = true }
		end
		close(session, "declined")
		return { ok = true }
	elseif action == "offer" then
		if not session.accepted then
			return { ok = false, reason = "not_accepted" }
		end
		local amount = math.floor(ctxData.Validation.NormalizeFiniteNumber(payload.amount, 0, cfg.MaxAmount, 0))
		if amount < 0 then
			return { ok = false, reason = "invalid" }
		end
		local profile = ctxData.Services.ProfileService.GetProfile(player)
		if not profile or profile.bankedTime < amount then
			return { ok = false, reason = "insufficient_bank" }
		end
		session.offers[player.UserId] = amount
		session.confirmed[session.a] = false
		session.confirmed[session.b] = false
		session.expiresAt = os.clock() + cfg.SessionSeconds
		notify(session)
		return { ok = true }
	elseif action == "confirm" then
		if not session.accepted then
			return { ok = false, reason = "not_accepted" }
		end
		if not session.offers[session.a] or not session.offers[session.b] then
			return { ok = false, reason = "missing_offer" }
		end
		session.confirmed[player.UserId] = true
		if session.confirmed[session.a] and session.confirmed[session.b] then
			execute(session)
			return { ok = true }
		end
		notify(session)
		return { ok = true }
	elseif action == "cancel" then
		close(session, "cancelled")
		return { ok = true }
	end

	return { ok = false, reason = "unknown_action" }
end

function TradeService.Start(ctx)
	ctxData = ctx

	ctxData.Remotes.Get("TS_TradeAction").OnServerInvoke = function(player, payload)
		local ok, result = pcall(handle, player, payload)
		if ok then
			return result
		end
		warn(("%s trade error: %s"):format(ctxData.Config.Game.LogPrefix, tostring(result)))
		return { ok = false, reason = "server_error" }
	end

	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.clock()
			for _, session in pairs(sessions) do
				if session.expiresAt <= now then
					close(session, "timeout")
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local key = playerSession[player.UserId]
		local session = key and sessions[key]
		if session then
			close(session, "partner_left")
		end
	end)

	return true
end

return TradeService
