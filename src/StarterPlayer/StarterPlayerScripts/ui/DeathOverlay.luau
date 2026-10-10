local DeathOverlay = {}

local api
local frame

function DeathOverlay.Create(createApi)
	api = createApi

	frame = Instance.new("Frame")
	frame.Name = "DeathOverlay"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = 100
	frame.Visible = false
	frame.Parent = api.Root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.3, 0)
	label.Position = UDim2.new(0, 0, 0.35, 0)
	label.BackgroundTransparency = 1
	label.Text = "TIME'S UP"
	label.TextColor3 = Color3.fromRGB(255, 70, 60)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0.1, 0)
	subtitle.Position = UDim2.new(0, 0, 0.68, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Returning to the sanctuary..."
	subtitle.TextColor3 = Color3.fromRGB(220, 220, 240)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextScaled = true
	subtitle.Parent = frame

	return DeathOverlay
end

function DeathOverlay.Show()
	if not frame then
		return
	end
	frame.Visible = true

	local t = 0
	while t < 1 do
		t += 0.1
		frame.BackgroundTransparency = 1 - t
		task.wait(0.06)
	end
	frame.BackgroundTransparency = 0

	task.wait(3)

	t = 0
	while t < 1 do
		t += 0.1
		frame.BackgroundTransparency = t
		task.wait(0.06)
	end
	frame.BackgroundTransparency = 1
	frame.Visible = false
end

return DeathOverlay