local Feedback = {}

local api
local feedFrame
local nextY = 0

local COLORS = {
	steal = Color3.fromRGB(80, 255, 150),
	warn = Color3.fromRGB(255, 90, 80),
	error = Color3.fromRGB(255, 120, 120),
	danger = Color3.fromRGB(255, 70, 60),
	announcement = Color3.fromRGB(120, 200, 255),
}

function Feedback.Create(createApi)
	api = createApi

	feedFrame = Instance.new("Frame")
	feedFrame.Name = "Feedback"
	feedFrame.Size = UDim2.new(0, 300, 0, 180)
	feedFrame.Position = UDim2.new(0, 10, 1, -190)
	feedFrame.BackgroundTransparency = 1
	feedFrame.Parent = api.Root

	return Feedback
end

function Feedback.Push(text: any, kind: any)
	if not feedFrame then
		return
	end
	local messageKind = type(kind) == "string" and kind or "announcement"
	local color = COLORS[messageKind] or COLORS.announcement

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 280, 0, 24)
	label.Position = UDim2.new(0, 0, 0, nextY)
	label.BackgroundTransparency = 1
	label.Text = tostring(text)
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = feedFrame
	nextY = (nextY + 26) % 156

	task.delay(3, function()
		if not label.Parent then
			return
		end
		label:TweenSize(UDim2.new(0, 280, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.4, true)
		task.delay(0.45, function()
			label:Destroy()
		end)
	end)
end

return Feedback