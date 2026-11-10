local Players = game:GetService("Players")

local EventService = {}

local ctxData
local current = nil

local function weekdayNumber(): number
	local wday = tonumber(os.date("!%w")) or 0 -- 0 = Sunday
	if wday == 0 then
		return 7
	end
	return wday
end

local function findActive()
	local today = weekdayNumber()
	for _, event in ctxData.Config.Social.Events do
		for _, day in event.days do
			if day == today then
				return event
			end
		end
	end
	return nil
end

local function payload()
	if not current then
		return { event = nil }
	end
	return {
		event = {
			id = current.id,
			name = current.name,
			description = current.description,
		},
	}
end

local function broadcast()
	local remote = ctxData.Remotes.Get("TS_EventUpdate")
	for _, player in Players:GetPlayers() do
		remote:FireClient(player, payload())
	end
end

function EventService.Start(ctx)
	ctxData = ctx
	current = findActive()

	task.spawn(function()
		while true do
			local active = findActive()
			if (active and not current) or (current and not active) or (active and current and active.id ~= current.id) then
				current = active
				broadcast()
				local announcement = ctxData.Remotes.Get("TS_Announcement")
				for _, player in Players:GetPlayers() do
					if current then
						announcement:FireClient(player, {
							text = ("EVENT ACTIVE: %s — %s"):format(current.name, current.description),
						})
					end
				end
			end
			task.wait(60)
		end
	end)

	return true
end

function EventService.GetActive()
	return current
end

function EventService.GetNpcMultiplier(zoneId: string): number
	if not current then
		return 1
	end
	if current.zone == zoneId and current.zoneNpcMultiplier then
		return current.zoneNpcMultiplier
	end
	if current.npcMultiplier then
		return current.npcMultiplier
	end
	return 1
end

function EventService.GetPvpMultiplier(): number
	if not current then
		return 1
	end
	return current.pvpMultiplier or 1
end

function EventService.OnProfileReady(player: Player)
	ctxData.Remotes.Get("TS_EventUpdate"):FireClient(player, payload())
end

function EventService.Sync(player: Player)
	EventService.OnProfileReady(player)
end

return EventService
