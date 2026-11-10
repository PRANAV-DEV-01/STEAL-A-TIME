local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ProfileService = {
	StartCalled = false,
}

local store
local profiles = {}
local ctxData
local loading = {}

local function getStore()
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("StealATime_PROFILES_V1")
	end)
	store = ok and result or nil
	return store
end

local function loadFromStore(key: string)
	local current = getStore()
	if not current then
		return nil
	end
	local ok, data = pcall(function()
		return current:GetAsync(key)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

local function writeToStore(key: string, data: table)
	local current = getStore()
	if not current then
		return false
	end
	local ok = pcall(function()
		current:SetAsync(key, data)
	end)
	return ok
end

local function saveProfileNow(userId: number)
	local entry = profiles[userId]
	if not entry then
		return
	end
	if not entry.dirty then
		return
	end

	entry.data.lastSeenAt = os.time()
	local ok = writeToStore("profile_" .. tostring(userId), entry.data)
	if ok then
		entry.dirty = false
		entry.failCount = 0
		local player = Players:GetPlayerByUserId(userId)
		if player and ctxData.Services.LeaderboardService and ctxData.Services.LeaderboardService.SubmitProfile then
			pcall(ctxData.Services.LeaderboardService.SubmitProfile, ctxData.Services.LeaderboardService, player, entry.data)
		end
	else
		entry.failCount = (entry.failCount or 0) + 1
	end
	return ok
end

local function sendProfile(player: Player)
	local entry = profiles[player.UserId]
	if not entry then
		return
	end
	local remote = ctxData.Remotes.Get("TS_SyncProfile")
	remote:FireClient(player, ctxData.ProfileSchema.Snapshot(entry.data))
end

local function loadPlayer(player: Player)
	local userId = player.UserId
	if profiles[userId] or loading[userId] then
		return
	end
	loading[userId] = true

	local raw = loadFromStore("profile_" .. tostring(userId))
	local data = ctxData.ProfileSchema.Sanitize(raw or {})
	profiles[userId] = {
		data = data,
		dirty = true,
		failCount = 0,
	}
	loading[userId] = nil

	-- Fan out to every service that wants to initialise per-player state.
	for _, service in pairs(ctxData.Services) do
		if type(service) == "table" and type(service.OnProfileReady) == "function" then
			local ok, err = pcall(service.OnProfileReady, service, player)
			if not ok then
				warn(("[%s] OnProfileReady failed: %s"):format(ctxData.Config.Game.LogPrefix, tostring(err)))
			end
		end
	end

	sendProfile(player)
	ProfileService.SetDirty(player)

	-- RemoteEvents can fire before the client script connects. Re-send shortly after.
	task.delay(3, function()
		if profiles[userId] and player.Parent then
			sendProfile(player)
			pcall(ProfileService.SyncAll, player)
		end
	end)
end

function ProfileService.Start(ctx)
	ctxData = ctx
	ProfileService.StartCalled = true

	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadPlayer, player)
	end)

	ctxData.Remotes.Get("TS_ProfileRequest").OnServerInvoke = function(player)
		local entry = profiles[player.UserId]
		if not entry then
			return nil
		end
		pcall(ProfileService.SyncAll, player)
		return ctxData.ProfileSchema.Snapshot(entry.data)
	end

	Players.PlayerRemoving:Connect(function(player)
		task.spawn(function()
			ProfileService.SavePlayer(player)
			profiles[player.UserId] = nil
			loading[player.UserId] = nil
		end)
	end)

	-- Studio Play can start with the LocalPlayer already present.
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	task.spawn(function()
		while task.wait(10) do
			ProfileService.SaveAll()
		end
	end)

	return true
end

function ProfileService.GetProfile(player: Player)
	local entry = profiles[player.UserId]
	if entry then
		return entry.data
	end
	return nil
end

function ProfileService.IsReady(player: Player)
	return profiles[player.UserId] ~= nil
end

function ProfileService.SyncAll(player: Player)
	for _, service in pairs(ctxData.Services) do
		if type(service) == "table" and type(service.Sync) == "function" then
			pcall(service.Sync, service, player)
		end
	end
end

function ProfileService.SetDirty(player: Player)
	local entry = profiles[player.UserId]
	if entry then
		entry.dirty = true
	end
end

function ProfileService.Sync(player: Player)
	sendProfile(player)
end

function ProfileService.SavePlayer(player: Player)
	local entry = profiles[player.UserId]
	if not entry then
		return
	end
	saveProfileNow(player.UserId)
end

function ProfileService.SaveAll()
	for userId, entry in pairs(profiles) do
		if entry.dirty then
			saveProfileNow(userId)
		end
	end
end

function ProfileService.Shutdown()
	ProfileService.SaveAll()
end

function ProfileService.HasDataStore()
	return getStore() ~= nil
end

return ProfileService
