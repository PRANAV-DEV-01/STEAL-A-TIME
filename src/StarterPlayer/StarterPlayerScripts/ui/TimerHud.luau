local TimerHud = {}

local api
local timeLabel
local zoneLabel

local function colorForTime(time: number)
	if time > 30 then
		return Color3.fromRGB(80, 255, 120)
	elseif time > 15 then
		return Color3.fromRGB(255, 220, 80)
	elseif time > 5 then
		return Color3.fromRGB(255, 140, 40)
	else
		return Color3.fromRGB(255, 70, 60)
	end
end

function TimerHud.Create(createApi)
	api = createApi

	local frame = Instance.new("Frame")
	frame.Name = "TimerHud"
	frame.Size = UDim2.new(0, 220, 0, 80)
	frame.Position = UDim2.new(0.5, -110, 0, 10)
	frame.BackgroundTransparency = 0.5
	frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	frame.BorderSizePixel = 0
	frame.Parent = api.Root

	timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "Time"
	timeLabel.Size = UDim2.new(1, 0, 0.7, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "--"
	timeLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextScaled = true
	timeLabel.Parent = frame

	zoneLabel = Instance.new("TextLabel")
	zoneLabel.Name = "Zone"
	zoneLabel.Size = UDim2.new(1, 0, 0.3, 0)
	zoneLabel.Position = UDim2.new(0, 0, 0.7, 0)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.Text = "TIME SANCTUARY"
	zoneLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
	zoneLabel.Font = Enum.Font.GothamMedium
	zoneLabel.TextScaled = true
	zoneLabel.Parent = frame

	return TimerHud
end

function TimerHud.Apply(timeValue: any, zoneId: any)
	local value = type(timeValue) == "number" and timeValue or 0
	timeLabel.Text = tostring(math.floor(value))
	timeLabel.TextColor3 = colorForTime(value)

	if type(zoneId) == "string" then
		local zone = api.Config.Zones.ForId(zoneId)
		if zone then
			if zone.isHub then
				zoneLabel.Text = "TIME SANCTUARY"
				zoneLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
			else
				zoneLabel.Text = zone.name .. "  (DANGER " .. tostring(zone.dangerLevel) .. ")"
				zoneLabel.TextColor3 = Color3.fromRGB(255, 140, 60)
			end
		end
	end
end

return TimerHud