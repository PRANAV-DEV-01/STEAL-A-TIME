local TutorialHud = {}

local api
local frame
local title
local body
local progress

local STEPS = {
	"Welcome to TIME SANCTUARY. Time never decays here.",
	"Use a glowing travel pad to enter a danger zone.",
	"Your timer is ticking! Steal time from a golden pillar or another player.",
	"Return to the sanctuary — step on a travel pad back to the hub.",
	"Bank your time at the TIME BANK pad so thieves cannot take it.",
	"Buy an upgrade at the UPGRADE SHOP. You are ready!",
}

function TutorialHud.Create(createApi)
	api = createApi

	frame = Instance.new("Frame")
	frame.Name = "TutorialHud"
	frame.Size = UDim2.new(0, 310, 0, 112)
	frame.Position = UDim2.new(0, 10, 0, 96)
	frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = api.Root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(64, 200, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = frame

	title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 24)
	title.Position = UDim2.new(0, 8, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "TUTORIAL"
	title.TextColor3 = Color3.fromRGB(64, 200, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -16, 0, 58)
	body.Position = UDim2.new(0, 8, 0, 32)
	body.BackgroundTransparency = 1
	body.Text = ""
	body.TextColor3 = Color3.fromRGB(235, 240, 248)
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 14
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = frame

	progress = Instance.new("TextLabel")
	progress.Size = UDim2.new(1, -16, 0, 18)
	progress.Position = UDim2.new(0, 8, 1, -24)
	progress.BackgroundTransparency = 1
	progress.Text = ""
	progress.TextColor3 = Color3.fromRGB(160, 180, 200)
	progress.Font = Enum.Font.GothamMedium
	progress.TextSize = 13
	progress.TextXAlignment = Enum.TextXAlignment.Left
	progress.Parent = frame

	return TutorialHud
end

function TutorialHud.Apply(payload)
	if type(payload) ~= "table" or not frame then
		return
	end
	local step = math.clamp(tonumber(payload.step) or 0, 0, #STEPS)
	local total = tonumber(payload.total) or #STEPS
	local show = payload.show == true and step < total

	frame.Visible = show
	if not show then
		return
	end

	title.Text = ("TUTORIAL  %d/%d"):format(step + 1, total)
	body.Text = STEPS[step + 1] or ""
	local dots = {}
	for index = 1, total do
		table.insert(dots, index <= step and "*" or "-")
	end
	progress.Text = table.concat(dots, "  ")
end

return TutorialHud
