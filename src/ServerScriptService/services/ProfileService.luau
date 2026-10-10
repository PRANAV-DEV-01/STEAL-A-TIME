local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ProfileService = {
	StartCalled = false,
}

local store
local profiles = {}
local ctxData

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

	local ok = writeToStore("profile_" .. tostring(userId), entry.data)
	if ok then
		entry.dirty = false
		entry.failCount = 0
	else
		entry.failCount = (entry.failCount or 0) + 1
	end
	return ok
end

function ProfileService.Start(ctx)
	ctxData = ctx
	ProfileService.StartCalled = true

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local raw = loadFromStore("profile_" .. tostring(player.UserId))
			local data = ctxData.ProfileSchema.Sanitize(raw or {})
			profiles[player.UserId] = {
				data = data,
				dirty = true,
				failCount = 0,
			}

			ctxData.services.ZoneService:OnPlayerProfileReady(player)

			local syncProfile = ctxData.Remotes.Get("TS_SyncProfile")
			syncProfile:FireClient(player, ctxData.ProfileSchema.SanitizeOutgoing(data))
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		task.spawn(function()
			ProfileService.SavePlayer(player)
			profiles[player.UserId] = nil
		end)
	end)

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

function ProfileService.SetDirty(player: Player)
	local entry = profiles[player.UserId]
	if entry then
		entry.dirty = true
	end
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