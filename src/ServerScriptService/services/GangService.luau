local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local GangService = {}

local ctxData
local registry = { gangs = {} }
local invites = {}
local store
local dirty = false
local started = false

local function getStore()
	if store then
		return store
	end
	local cfg = ctxData.Config.Social.Gangs
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(cfg.StoreName)
	end)
	store = ok and result or nil
	return store
end

local function saveRegistry()
	if not dirty then
		return
	end
	local current = getStore()
	if current then
		local ok = pcall(function()
			current:SetAsync(ctxData.Config.Social.Gangs.StoreKey, registry)
		end)
		if not ok then
			return
		end
	end
	dirty = false
end

local function gangFor(player: Player)
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile or not profile.gangId then
		return nil
	end
	return registry.gangs[profile.gangId]
end

local function viewOf(gang)
	local members = {}
	for _, userId in ipairs(gang.members) do
		local member = Players:GetPlayerByUserId(userId)
		table.insert(members, {
			userId = userId,
			name = member and member.DisplayName or ("User " .. tostring(userId)),
			online = member ~= nil,
		})
	end
	return {
		id = gang.id,
		name = gang.name,
		ownerId = gang.ownerId,
		bank = gang.bank,
		members = members,
	}
end

local function sendTo(gang, action: string?)
	if not gang then
		return
	end
	local remote = ctxData.Remotes.Get("TS_GangUpdate")
	local view = viewOf(gang)
	for _, userId in ipairs(gang.members) do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			remote:FireClient(member, { gang = view, action = action })
		end
	end
end

local function inviteView(player: Player)
	local invite = invites[player.UserId]
	if not invite then
		return nil
	end
	local gang = registry.gangs[invite.gangId]
	if not gang then
		invites[player.UserId] = nil
		return nil
	end
	return { gangId = gang.id, name = gang.name, from = invite.from }
end

local function sendPlayer(player: Player)
	local gang = gangFor(player)
	ctxData.Remotes.Get("TS_GangUpdate"):FireClient(player, {
		gang = gang and viewOf(gang) or nil,
		invite = inviteView(player),
	})
end

local function removeMember(player: Player, gang, userId: number)
	for index, id in ipairs(gang.members) do
		if id == userId then
			table.remove(gang.members, index)
			break
		end
	end
	local member = Players:GetPlayerByUserId(userId)
	if member then
		local profile = ctxData.Services.ProfileService.GetProfile(member)
		if profile then
			profile.gangId = nil
			ctxData.Services.ProfileService.SetDirty(member)
			ctxData.Services.ProfileService.Sync(member)
		end
		sendPlayer(member)
	end

	if #gang.members == 0 then
		registry.gangs[gang.id] = nil
	elseif gang.ownerId == userId then
		gang.ownerId = gang.members[1]
	end
	dirty = true
	if player then
		sendPlayer(player)
	end
end

local function handleCreate(player: Player, profile, payload)
	if profile.gangId then
		return false, "already_in_gang", nil
	end
	local name = payload.name
	if type(name) ~= "string" then
		return false, "invalid_name", nil
	end
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	local cfg = ctxData.Config.Social.Gangs
	if #name < cfg.MinNameLength or #name > cfg.MaxNameLength then
		return false, "invalid_name", nil
	end
	if not string.match(name, ctxData.Config.Social.GangNames.AllowedPattern) then
		return false, "invalid_name", nil
	end
	if profile.bankedTime < cfg.CreateCost then
		return false, "insufficient_bank", nil
	end

	profile.bankedTime -= cfg.CreateCost
	local id = ("%d_%d"):format(os.time(), math.random(1000, 9999))
	while registry.gangs[id] do
		id = ("%d_%d"):format(os.time(), math.random(1000, 9999))
	end
	local gang = {
		id = id,
		name = name,
		ownerId = player.UserId,
		bank = 0,
		createdAt = os.time(),
		members = { player.UserId },
	}
	registry.gangs[id] = gang
	profile.gangId = id
	invites[player.UserId] = nil
	profile.stats.purchases = (profile.stats.purchases or 0) + 1
	ctxData.Services.ProfileService.SetDirty(player)
	ctxData.Services.ProfileService.Sync(player)
	if ctxData.Services.BankService then
		ctxData.Services.BankService.SendUpdate(player)
	end
	dirty = true
	return true, nil, gang
end

local function handleDeposit(player: Player, profile, payload)
	local gang = gangFor(player)
	if not gang then
		return false, "no_gang", nil
	end
	local cfg = ctxData.Config.Social.Gangs
	local amount = math.floor(ctxData.Validation.NormalizeFiniteNumber(payload.amount, 0, cfg.MaxDeposit, 0))
	if amount < cfg.MinDeposit then
		return false, "invalid_amount", nil
	end
	if profile.bankedTime < amount then
		return false, "insufficient_bank", nil
	end
	profile.bankedTime -= amount
	gang.bank += amount
	dirty = true

	ctxData.Services.ProfileService.SetDirty(player)
	ctxData.Services.ProfileService.Sync(player)
	if ctxData.Services.BankService then
		ctxData.Services.BankService.SendUpdate(player)
	end
	return true, nil, gang
end

local function handleAction(player: Player, payload: any)
	if type(payload) ~= "table" then
		return { ok = false, reason = "invalid" }
	end
	if not ctxData.Services.RateLimiter.Allow(player, "trade") then
		ctxData.Services.RateLimiter.Suspect(player, "trade")
		return { ok = false, reason = "rate" }
	end
	local profile = ctxData.Services.ProfileService.GetProfile(player)
	if not profile then
		return { ok = false, reason = "no_profile" }
	end

	local action = payload.action
	if action == "create" then
		local ok, reason, gang = handleCreate(player, profile, payload)
		if ok then
			sendTo(gang, "created")
			ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = "Gang created", kind = "steal" })
			return { ok = true, gang = viewOf(gang) }
		end
		return { ok = false, reason = reason }
	elseif action == "deposit" then
		local ok, reason, gang = handleDeposit(player, profile, payload)
		if ok then
			sendTo(gang, "deposit")
			ctxData.Remotes.Get("TS_Feedback"):FireClient(player, { text = "Gang bank topped up", kind = "steal" })
			return { ok = true, gang = viewOf(gang) }
		end
		return { ok = false, reason = reason }
	elseif action == "leave" then
		local gang = gangFor(player)
		if not gang then
			return { ok = false, reason = "no_gang" }
		end
		removeMember(player, gang, player.UserId)
		sendTo(gang, "member_left")
		return { ok = true }
	elseif action == "kick" then
		local gang = gangFor(player)
		if not gang or gang.ownerId ~= player.UserId then
			return { ok = false, reason = "not_owner" }
		end
		local userId = tonumber(payload.userId)
		if not userId or userId == player.UserId then
			return { ok = false, reason = "invalid" }
		end
		local found = false
		for _, id in ipairs(gang.members) do
			if id == userId then
				found = true
				break
			end
		end
		if not found then
			return { ok = false, reason = "not_member" }
		end
		removeMember(player, gang, userId)
		sendTo(gang, "kick")
		return { ok = true }
	elseif action == "invite" then
		local gang = gangFor(player)
		if not gang then
			return { ok = false, reason = "no_gang" }
		end
		local cfg = ctxData.Config.Social.Gangs
		if #gang.members >= cfg.MaxMembers then
			return { ok = false, reason = "gang_full" }
		end
		local userId = tonumber(payload.userId)
		if not userId or userId == player.UserId then
			return { ok = false, reason = "invalid" }
		end
		local target = Players:GetPlayerByUserId(userId)
		if not target then
			return { ok = false, reason = "offline" }
		end
		local targetProfile = ctxData.Services.ProfileService.GetProfile(target)
		if not targetProfile or targetProfile.gangId then
			return { ok = false, reason = "already_in_gang" }
		end
		invites[userId] = { gangId = gang.id, from = player.DisplayName, at = os.time() }
		sendPlayer(target)
		ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
			text = ("Invited %s"):format(target.DisplayName),
			kind = "announcement",
		})
		return { ok = true }
	elseif action == "accept" then
		local invite = invites[player.UserId]
		if not invite then
			return { ok = false, reason = "no_invite" }
		end
		local gang = registry.gangs[invite.gangId]
		invites[player.UserId] = nil
		if not gang then
			sendPlayer(player)
			return { ok = false, reason = "gang_gone" }
		end
		if profile.gangId then
			sendPlayer(player)
			return { ok = false, reason = "already_in_gang" }
		end
		if #gang.members >= ctxData.Config.Social.Gangs.MaxMembers then
			sendPlayer(player)
			return { ok = false, reason = "gang_full" }
		end
		table.insert(gang.members, player.UserId)
		profile.gangId = gang.id
		ctxData.Services.ProfileService.SetDirty(player)
		ctxData.Services.ProfileService.Sync(player)
		dirty = true
		sendTo(gang, "member_joined")
		ctxData.Remotes.Get("TS_Feedback"):FireClient(player, {
			text = ("Joined %s"):format(gang.name),
			kind = "steal",
		})
		return { ok = true, gang = viewOf(gang) }
	elseif action == "decline" then
		invites[player.UserId] = nil
		sendPlayer(player)
		return { ok = true }
	elseif action == "disband" then
		local gang = gangFor(player)
		if not gang or gang.ownerId ~= player.UserId then
			return { ok = false, reason = "not_owner" }
		end
		for _, userId in ipairs(gang.members) do
			invites[userId] = nil
			local member = Players:GetPlayerByUserId(userId)
			if member then
				local memberProfile = ctxData.Services.ProfileService.GetProfile(member)
				if memberProfile then
					memberProfile.gangId = nil
					ctxData.Services.ProfileService.SetDirty(member)
					ctxData.Services.ProfileService.Sync(member)
				end
				ctxData.Remotes.Get("TS_GangUpdate"):FireClient(member, { gang = nil })
			end
		end
		for userId, invite in pairs(invites) do
			if invite.gangId == gang.id then
				invites[userId] = nil
				local invited = Players:GetPlayerByUserId(userId)
				if invited then
					sendPlayer(invited)
				end
			end
		end
		registry.gangs[gang.id] = nil
		profile.gangId = nil
		ctxData.Services.ProfileService.SetDirty(player)
		ctxData.Services.ProfileService.Sync(player)
		dirty = true
		return { ok = true }
	end

	return { ok = false, reason = "unknown_action" }
end

function GangService.Start(ctx)
	ctxData = ctx

	Players.PlayerRemoving:Connect(function(player)
		invites[player.UserId] = nil
	end)

	local current = getStore()
	if current then
		local ok, data = pcall(function()
			return current:GetAsync(ctxData.Config.Social.Gangs.StoreKey)
		end)
		if ok and type(data) == "table" and type(data.gangs) == "table" then
			registry = data
		end
	end

	if not started then
		started = true
		task.spawn(function()
			while true do
				task.wait(ctxData.Config.Social.Gangs.SaveDebounce)
				pcall(saveRegistry)
			end
		end)
	end

	ctxData.Remotes.Get("TS_GangAction").OnServerInvoke = function(player, payload)
		local ok, result = pcall(handleAction, player, payload)
		if ok then
			return result
		end
		warn(("%s gang error: %s"):format(ctxData.Config.Game.LogPrefix, tostring(result)))
		return { ok = false, reason = "server_error" }
	end

	return true
end

function GangService.OnProfileReady(player: Player)
	task.defer(sendPlayer, player)
end

function GangService.Sync(player: Player)
	sendPlayer(player)
end

function GangService.Shutdown()
	pcall(saveRegistry)
end

function GangService.GetGang(player: Player)
	local gang = gangFor(player)
	return gang and viewOf(gang) or nil
end

return GangService
