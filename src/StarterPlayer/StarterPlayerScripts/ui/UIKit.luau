local UIKit = {}

local PALETTE = {
	bg = Color3.fromRGB(15, 18, 24),
	panel = Color3.fromRGB(22, 27, 36),
	row = Color3.fromRGB(32, 39, 52),
	accent = Color3.fromRGB(64, 200, 255),
	text = Color3.fromRGB(235, 240, 248),
	muted = Color3.fromRGB(150, 165, 185),
	good = Color3.fromRGB(80, 230, 140),
	bad = Color3.fromRGB(255, 90, 80),
	gold = Color3.fromRGB(255, 205, 90),
}

UIKit.Palette = PALETTE

function UIKit.Corner(instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

function UIKit.Stroke(instance, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or PALETTE.accent
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = 0.45
	stroke.Parent = instance
	return stroke
end

function UIKit.Padding(instance, amount: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	padding.Parent = instance
	return padding
end

function UIKit.Label(parent: Instance, text: string, height: number?, color: Color3?)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height or 22)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or PALETTE.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

function UIKit.Button(parent: Instance, text: string, color: Color3?, onClick: (() -> ())?)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 120, 0, 44)
	button.BackgroundColor3 = color or PALETTE.accent
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(12, 16, 22)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.AutoButtonColor = true
	UIKit.Corner(button, 8)
	button.Parent = parent
	if onClick then
		button.Activated:Connect(onClick)
	end
	return button
end

function UIKit.TextBox(parent: Instance, placeholder: string)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 150, 0, 44)
	box.BackgroundColor3 = PALETTE.row
	box.BorderSizePixel = 0
	box.Text = ""
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = PALETTE.muted
	box.TextColor3 = PALETTE.text
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 16
	box.ClearTextOnFocus = false
	UIKit.Corner(box, 8)
	box.Parent = parent
	return box
end

function UIKit.Scroll(parent: Instance, height: number?)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -(height or 0))
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = PALETTE.accent
	UIKit.Padding(scroll, 6)
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	return scroll
end

function UIKit.Row(parent: Instance, height: number?, order: number?)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, height or 48)
	row.BackgroundColor3 = PALETTE.row
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel = 0
	row.LayoutOrder = order or 1
	UIKit.Corner(row, 8)
	row.Parent = parent
	return row
end

function UIKit.RowLabel(row: Instance, text: string, color: Color3?)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -140, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or PALETTE.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = row
	return label
end

function UIKit.RowButton(row: Instance, text: string, color: Color3?, onClick: (() -> ())?)
	local button = UIKit.Button(row, text, color, onClick)
	button.Size = UDim2.new(0, 120, 0, 36)
	button.Position = UDim2.new(1, -130, 0.5, -18)
	button.TextSize = 14
	return button
end

function UIKit.RowButton2(row: Instance, text: string, color: Color3?, onClick: (() -> ())?)
	local button = UIKit.Button(row, text, color, onClick)
	button.Size = UDim2.new(0, 64, 0, 34)
	button.Position = UDim2.new(1, -74, 0.5, -17)
	button.TextSize = 13
	return button
end

return UIKit
