local DashButton = {}

local api
local dashButton
local stealthButton
local dashIn = 0
local stealthIn = 0

local function render()
	if not dashButton then
		return
	end
	local dashReady = dashIn <= 0
	dashButton.Text = dashReady and "DASH" or ("DASH %ds"):format(math.ceil(dashIn))
	dashButton.BackgroundColor3 = dashReady and Color3.fromRGB(64, 200, 255) or Color3.fromRGB(60, 70, 85)
	dashButton.TextColor3 = dashReady and Color3.fromRGB(12, 16, 22) or Color3.fromRGB(170, 180, 195)

	local stealthReady = stealthIn <= 0
	stealthButton.Text = stealthReady and "STEALTH" or ("STEALTH %ds"):format(math.ceil(stealthIn))
	stealthButton.BackgroundColor3 = stealthReady and Color3.fromRGB(150, 120, 255) or Color3.fromRGB(60, 70, 85)
	stealthButton.TextColor3 = stealthReady and Color3.fromRGB(12, 16, 22) or Color3.fromRGB(170, 180, 195)
end

function DashButton.Create(createApi)
	api = createApi

	local holder = Instance.new("Frame")
	holder.Name = "AbilityBar"
	holder.Size = UDim2.new(0, 240, 0, 48)
	holder.Position = UDim2.new(1, -250, 1, -156)
	holder.BackgroundTransparency = 1
	holder.Parent = api.Root

	dashButton = Instance.new("TextButton")
	dashButton.Size = UDim2.new(0, 116, 0, 48)
	dashButton.BackgroundColor3 = Color3.fromRGB(64, 200, 255)
	dashButton.BorderSizePixel = 0
	dashButton.Text = "DASH"
	dashButton.TextColor3 = Color3.fromRGB(12, 16, 22)
	dashButton.Font = Enum.Font.GothamBold
	dashButton.TextSize = 15
	dashButton.Parent = holder
	local c1 = Instance.new("UICorner")
	c1.CornerRadius = UDim.new(0, 8)
	c1.Parent = dashButton
	dashButton.Activated:Connect(function()
		if dashIn <= 0 then
			api.Remotes.Get("TS_DashRequest"):FireServer()
		end
	end)

	stealthButton = Instance.new("TextButton")
	stealthButton.Size = UDim2.new(0, 116, 0, 48)
	stealthButton.Position = UDim2.new(1, -116, 0, 0)
	stealthButton.BackgroundColor3 = Color3.fromRGB(150, 120, 255)
	stealthButton.BorderSizePixel = 0
	stealthButton.Text = "STEALTH"
	stealthButton.TextColor3 = Color3.fromRGB(12, 16, 22)
	stealthButton.Font = Enum.Font.GothamBold
	stealthButton.TextSize = 15
	stealthButton.Parent = holder
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, 8)
	c2.Parent = stealthButton
	stealthButton.Activated:Connect(function()
		if stealthIn <= 0 then
			api.Remotes.Get("TS_StealthRequest"):FireServer()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.2)
			dashIn = math.max(0, dashIn - 0.2)
			stealthIn = math.max(0, stealthIn - 0.2)
			render()
		end
	end)

	render()
	return DashButton
end

function DashButton.Apply(payload)
	if type(payload) ~= "table" then
		return
	end
	if type(payload.dashReadyIn) == "number" then
		dashIn = payload.dashReadyIn
	end
	if type(payload.stealthReadyIn) == "number" then
		stealthIn = payload.stealthReadyIn
	end
	render()
end

return DashButton
