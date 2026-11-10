local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LeaderboardService = {}

local ctxData
local memory = {}
local cached = {}
local stores = {}
local started = false

local BOARDS = { "totalTimeStolen", "bankedTime" }

local BOARD_LABELS = {
	totalTimeStolen = "Most Time Stolen",
	bankedTime = "Richest Bank",
}

local function boardStore(board: string)
	if stores[board] ~= nil then
		return stores[board] or nil
	end
	local cfg = ctxData.Config.Economy.Leaderboards
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(cfg.StoreName .. "_" .. board)
	end)
	stores[board] = ok and store or false
	return ok and store or nil
end

local function nameFor(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end
	return "User " .. tostring(userId)
end

local function refreshBoard(board: string)
	local list = {}
	local store = boardStore(board)

	if store then
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, ctxData.Config.Economy.Leaderboards.TopCount)
		end)
		if ok and pages then
			local entries = pages:GetCurrentPage()
			for rank, entry in ipairs(entries) do
				local userId = tonumber(entry.key)
				if userId then
					table.insert(list, { rank = rank, name = nameFor(userId), value = entry.value })
				end
			end
		end
	end

	if #list == 0 then
		-- In-memory fallback (Studio without DataStore access).
		local rows = {}
		for userId, value in pairs(memory[board] or {}) do
			table.insert(rows, { userId = userId, value = value })
		end
		table.sort(rows, function(a, b)
			return a.value > b.value
		end)
		for index, row in ipairs(rows) do
			if index > ctxData.Config.Economy.Leaderboards.TopCount then
				break
			end
			table.insert(list, { rank = index, name = nameFor(row.userId), value = row.value })
		end
	end

	cached[board] = list
end

local function refreshAll()
	for _, board in ipairs(BOARDS) do
		pcall(refreshBoard, board)
	end
	local remote = ctxData.Remotes.Get("TS_LeaderboardUpdate")
	for _, player in Players:GetPlayers() do
		remote:FireClient(player, cached)
	end
end

function LeaderboardService.Start(ctx)
	ctxData = ctx
	for _, board in ipairs(BOARDS) do
		cached[board] = cached[board] or {}
		memory[board] = memory[board] or {}
	end

	if not started then
		started = true
		task.spawn(function()
			while true do
				pcall(refreshAll)
				task.wait(ctxData.Config.Economy.Leaderboards.RefreshSeconds)
			end
		end)
	end

	ctxData.Remotes.Get("TS_LeaderboardRequest").OnServerInvoke = function(player)
		pcall(refreshAll)
		return cached
	end

	return true
end

function LeaderboardService.Submit(board: string, player: Player, value: number)
	if memory[board] == nil then
		memory[board] = {}
	end
	memory[board][player.UserId] = math.floor(math.max(0, value))

	local store = boardStore(board)
	if store then
		pcall(function()
			store:SetAsync(tostring(player.UserId), math.floor(math.max(0, value)))
		end)
	end
end

function LeaderboardService.SubmitProfile(player: Player, profile)
	LeaderboardService.Submit("totalTimeStolen", player, profile.totalTimeStolen or 0)
	LeaderboardService.Submit("bankedTime", player, profile.bankedTime or 0)
end

function LeaderboardService.GetBoards()
	return cached
end

function LeaderboardService.GetLabels()
	return BOARD_LABELS
end

function LeaderboardService.OnProfileReady(player: Player)
	ctxData.Remotes.Get("TS_LeaderboardUpdate"):FireClient(player, cached)
end

function LeaderboardService.Sync(player: Player)
	LeaderboardService.OnProfileReady(player)
end

return LeaderboardService
