-- UI toolkit: the game's one design system.
-- Look: white/cream panels with thick dark outlines, colored header bars,
-- chunky saturated buttons with a 3D "depth" edge that physically presses down,
-- bold rounded type with outlines, pill-shaped chips and currency displays.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Sfx = require(script.Parent.Sfx)

local Kit = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Kit.Theme = {
	Title = Enum.Font.FredokaOne,
	Heavy = Enum.Font.LuckiestGuy, -- big numbers + logo-style titles
	Body = Enum.Font.GothamBold,
	Text = rgb(255, 255, 255), -- outlined white text (on color)
	TextDark = rgb(55, 40, 85), -- plain text on light panels
	TextMuted = rgb(130, 115, 160),
	Outline = rgb(35, 24, 58),
	Panel = rgb(255, 255, 255),
	PanelBottom = rgb(255, 244, 228), -- panels fade white -> cream
	PanelInset = rgb(243, 236, 252), -- wells/rows inside panels
	PanelDark = rgb(235, 225, 248),
	PanelLight = rgb(250, 247, 255),
	-- action colors
	Good = rgb(70, 215, 95), -- buy / confirm
	Bad = rgb(255, 85, 100), -- can't afford / destructive
	Red = rgb(240, 70, 85), -- close
	Pink = rgb(255, 90, 170), -- special
	Teal = rgb(35, 200, 200),
	Blue = rgb(70, 150, 255), -- secondary
	Purple = rgb(150, 90, 255), -- rare / premium
	Orange = rgb(255, 145, 40),
	Yellow = rgb(255, 205, 45),
	Disabled = rgb(175, 170, 190),
	Accent = rgb(255, 205, 45),
	Cash = rgb(70, 215, 95),
	Shards = rgb(110, 150, 255),
}

local OUTLINE = 3
local RADIUS = 14
local DEPTH = 5
local QUICK = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function Kit.new(className: string, props: { [string]: any })
	local inst = Instance.new(className)
	local parent = props.Parent
	props.Parent = nil
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

function Kit.corner(parent, radius: number?)
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or RADIUS), Parent = parent })
end

function Kit.stroke(parent, color: Color3?, thickness: number?)
	return Kit.new("UIStroke", {
		Color = color or Kit.Theme.Outline,
		Thickness = thickness or OUTLINE,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

-- subtle top-light/bottom-dark shading (multiplies the background color)
function Kit.gloss(parent, strength: number?)
	local s = strength or 0.18
	return Kit.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.55, Color3.new(1 - s * 0.35, 1 - s * 0.35, 1 - s * 0.35)),
			ColorSequenceKeypoint.new(1, Color3.new(1 - s, 1 - s, 1 - s)),
		}),
		Parent = parent,
	})
end

local function darker(color: Color3, amount: number)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end
Kit.darker = darker

-- Text. Default: white with a thick dark outline (the signature look).
-- Outline = false gives plain dark text for reading on light panels.
function Kit.label(props)
	props.BackgroundTransparency = 1
	local outline = props.Outline
	props.Outline = nil
	props.Font = props.Font or Kit.Theme.Title
	props.TextColor3 = props.TextColor3 or (if outline == false then Kit.Theme.TextDark else Kit.Theme.Text)
	props.TextStrokeTransparency = 1
	local label = Kit.new("TextLabel", props)
	if outline ~= false then
		local size = props.TextSize or 20
		Kit.new("UIStroke", {
			Color = Kit.Theme.Outline,
			Thickness = if props.TextScaled then 2.5 elseif size >= 30 then 3 elseif size >= 18 then 2.2 else 1.6,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			LineJoinMode = Enum.LineJoinMode.Round,
			Parent = label,
		})
	end
	return label
end

local function animScale(gui)
	return gui:FindFirstChild("AnimScale") or Kit.new("UIScale", { Name = "AnimScale", Parent = gui })
end

function Kit.bounce(gui: GuiObject)
	local scale = animScale(gui)
	scale.Scale = 0.85
	TweenService:Create(scale, BOUNCE, { Scale = 1 }):Play()
end

-- Chunky 3D button. Returns a TextButton you use as normal: setting its
-- BackgroundColor3 / Text / TextSize / TextColor3 / Font / TextScaled updates
-- the visible face. Put custom children inside Kit.face(button) so they move
-- with the press. opts.sound = click sound name (default "ui_click", false = none).
function Kit.button(props, opts: { sound: any? }?)
	local color = props.BackgroundColor3 or Kit.Theme.Good
	props.BackgroundColor3 = color
	props.BackgroundTransparency = 1
	props.AutoButtonColor = false
	props.TextTransparency = 1
	props.TextStrokeTransparency = 1
	props.Font = props.Font or Kit.Theme.Title
	props.TextColor3 = props.TextColor3 or Kit.Theme.Text
	local button = Kit.new("TextButton", props)
	local z = button.ZIndex

	local depth = Kit.new("Frame", { Name = "Depth", Size = UDim2.fromScale(1, 1), BackgroundColor3 = darker(color, 0.32), ZIndex = z, Parent = button })
	Kit.corner(depth)
	Kit.stroke(depth)
	local face = Kit.new("Frame", { Name = "Face", Size = UDim2.new(1, 0, 1, -DEPTH), BackgroundColor3 = color, ZIndex = z, Parent = button })
	Kit.corner(face)
	local faceStroke = Kit.stroke(face)
	faceStroke.Name = "Outline"
	Kit.gloss(face, 0.12)
	-- shine strip along the top edge
	local shine = Kit.new("Frame", { Name = "Shine", Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, ZIndex = z, Parent = face })
	Kit.corner(shine, 4)
	local text = Kit.label({ Name = "FaceText", Size = UDim2.fromScale(1, 1), Text = button.Text, Font = button.Font, TextSize = button.TextSize, TextScaled = button.TextScaled, TextColor3 = button.TextColor3, ZIndex = z, Parent = face })
	if button.TextScaled then
		Kit.new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = text })
	end

	-- mirror the button's properties onto the face
	local function sync()
		local c = button.BackgroundColor3
		face.BackgroundColor3 = c
		depth.BackgroundColor3 = darker(c, 0.32)
		text.Text = button.Text
		text.TextSize = button.TextSize
		text.TextColor3 = button.TextColor3
		text.Font = button.Font
		text.TextScaled = button.TextScaled
		text.Visible = button.Text ~= ""
	end
	for _, prop in { "BackgroundColor3", "Text", "TextSize", "TextColor3", "Font", "TextScaled" } do
		button:GetPropertyChangedSignal(prop):Connect(sync)
	end
	button:GetPropertyChangedSignal("ZIndex"):Connect(function()
		for _, gui in { depth, face, shine, text } do
			gui.ZIndex = button.ZIndex
		end
	end)
	sync()

	local scale = animScale(button)
	local hovering = false
	local function press(down)
		TweenService:Create(face, QUICK, { Position = UDim2.fromOffset(0, if down then DEPTH - 1 else 0) }):Play()
	end
	button.MouseEnter:Connect(function()
		hovering = true
		TweenService:Create(scale, QUICK, { Scale = 1.05 }):Play()
		Sfx.play("ui_hover")
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		press(false)
		TweenService:Create(scale, QUICK, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		press(true)
		TweenService:Create(scale, QUICK, { Scale = 0.97 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		press(false)
		TweenService:Create(scale, BOUNCE, { Scale = if hovering then 1.05 else 1 }):Play()
	end)
	local sound = if opts and opts.sound ~= nil then opts.sound else "ui_click"
	button.Activated:Connect(function()
		if sound then
			Sfx.play(sound)
		end
	end)
	return button
end

-- the moving front of a Kit.button (parent custom content here)
function Kit.face(button: GuiObject): Frame
	return button:FindFirstChild("Face") or button
end

-- the outline of a Kit.button face (for selection highlights)
function Kit.outline(button: GuiObject): UIStroke?
	local face = button:FindFirstChild("Face")
	return if face then face:FindFirstChild("Outline") :: UIStroke else button:FindFirstChildOfClass("UIStroke")
end

function Kit.screen(name: string, order: number?)
	return Kit.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 0,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
end

-- Scales a frame with screen height so it fits phones and big monitors.
local scaled = {}
local function screenScale()
	return math.clamp(workspace.CurrentCamera.ViewportSize.Y / 900, 0.55, 1.2)
end
function Kit.autoScale(frame: GuiObject)
	local s = Kit.new("UIScale", { Name = "AutoScale", Scale = screenScale(), Parent = frame })
	table.insert(scaled, s)
	return frame
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	for _, s in scaled do
		s.Scale = screenScale()
	end
end)

-- Fades a label (text + outline) or frame out over `seconds`.
function Kit.fadeOut(gui: GuiObject, seconds: number)
	local info = TweenInfo.new(seconds)
	local goal = {}
	if gui:IsA("TextLabel") or gui:IsA("TextButton") then
		goal.TextTransparency = 1
		goal.TextStrokeTransparency = 1
	end
	if gui.BackgroundTransparency < 1 then
		goal.BackgroundTransparency = 1
	end
	TweenService:Create(gui, info, goal):Play()
	for _, child in gui:GetChildren() do
		if child:IsA("UIStroke") then
			TweenService:Create(child, info, { Transparency = 1 }):Play()
		end
	end
end

-- White panel with outline + cream fade (cards, rows, wells).
function Kit.card(props)
	props.BackgroundColor3 = props.BackgroundColor3 or Kit.Theme.Panel
	local card = Kit.new("Frame", props)
	Kit.corner(card)
	Kit.stroke(card)
	Kit.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 246, 232)), Parent = card })
	return card
end

-- Small rounded chip (tags like "+$3/s", "8.0 kg", rarity).
function Kit.chip(props: { Parent: Instance, Text: string, Color: Color3?, TextColor3: Color3?, Position: UDim2?, Size: UDim2?, LayoutOrder: number? })
	local chip = Kit.new("Frame", {
		Position = props.Position or UDim2.new(),
		Size = props.Size or UDim2.fromOffset(0, 26),
		AutomaticSize = if props.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		BackgroundColor3 = props.Color or Kit.Theme.PanelInset,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	Kit.corner(chip, 999)
	Kit.stroke(chip, Kit.Theme.Outline, 2)
	local label = Kit.label({ Name = "Text", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = props.Text, TextSize = 15, Font = Kit.Theme.Title, Outline = props.Color ~= nil, TextColor3 = props.TextColor3, Parent = chip })
	if props.Size then
		label.AutomaticSize = Enum.AutomaticSize.None
		label.Size = UDim2.fromScale(1, 1)
	end
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = chip })
	return chip, label
end

-- Currency pill: white pill, round coin icon overlapping its left edge, big
-- outlined value in the currency color, optional small sub-chip underneath.
function Kit.pill(props: { Parent: Instance, Position: UDim2, Size: UDim2, Color: Color3, Icon: string, AnchorPoint: Vector2? })
	local pill = Kit.new("Frame", {
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = Kit.Theme.Panel,
		Parent = props.Parent,
	})
	Kit.corner(pill, 999)
	Kit.stroke(pill)
	Kit.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 244, 228)), Parent = pill })
	local h = props.Size.Y.Offset
	local icon = Kit.new("Frame", { Position = UDim2.fromOffset(-6, -5), Size = UDim2.fromOffset(h + 10, h + 10), BackgroundColor3 = Kit.Theme.Yellow, Parent = pill })
	Kit.corner(icon, 999)
	Kit.stroke(icon)
	Kit.gloss(icon, 0.25)
	local inner = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.72), BackgroundColor3 = Kit.darker(Kit.Theme.Yellow, 0.08), Parent = icon })
	Kit.corner(inner, 999)
	Kit.label({ Size = UDim2.fromScale(1, 1), Text = props.Icon, TextScaled = true, Font = Kit.Theme.Heavy, Parent = inner })
	local value = Kit.label({ Name = "Value", Position = UDim2.fromOffset(h + 12, 0), Size = UDim2.new(1, -h - 22, 1, 0), Text = "0", TextScaled = true, Font = Kit.Theme.Heavy, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = props.Color, Parent = pill })
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 3), Parent = value })
	return pill, value, icon
end

-- Standard window: white->cream body, thick outline, colored header bar with
-- a big title, red close button, soft shadow, pop/slide in and out.
-- Content goes in window.frame (the header covers the top 60px).
function Kit.window(gui: ScreenGui, opts: { title: string, accent: Color3, size: Vector2, position: UDim2?, anchor: Vector2? })
	local holder = Kit.autoScale(Kit.new("Frame", {
		Name = opts.title .. "Window",
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5),
		Position = opts.position or UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(opts.size.X, opts.size.Y),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	}))
	local shadow = Kit.new("Frame", { Position = UDim2.fromOffset(0, 8), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Kit.Theme.Outline, BackgroundTransparency = 0.7, Parent = holder })
	Kit.corner(shadow, 22)

	local frame = Kit.new("CanvasGroup", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Kit.Theme.Panel, Parent = holder })
	Kit.corner(frame, 22)
	Kit.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 242, 225)), Parent = frame })
	local outline = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = holder })
	Kit.corner(outline, 22)
	Kit.stroke(outline, Kit.Theme.Outline, 4)

	local header = Kit.new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = opts.accent, Parent = frame })
	Kit.gloss(header, 0.15)
	Kit.new("Frame", { Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Kit.Theme.Outline, BorderSizePixel = 0, Parent = header })
	-- playful polka dots on the header
	for i = 1, 6 do
		local dot = Kit.new("Frame", { Position = UDim2.new(0.18 * i - 0.05, 0, 0, (i % 2) * 18 + 6), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Parent = header })
		Kit.corner(dot, 999)
	end
	Kit.label({ Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -90, 1, -14), Text = opts.title, TextScaled = true, Font = Kit.Theme.Heavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = header })

	local closeHolder = Kit.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 8, 0, -8), Size = UDim2.fromOffset(52, 56), BackgroundTransparency = 1, ZIndex = 60, Parent = holder })
	local close = Kit.button({ Size = UDim2.fromScale(1, 1), Text = "X", TextSize = 30, Font = Kit.Theme.Heavy, BackgroundColor3 = Kit.Theme.Red, ZIndex = 60, Parent = closeHolder }, { sound = false })

	local window = { holder = holder, frame = frame, header = header }
	local token = 0

	function window.isOpen()
		return holder.Visible
	end

	function window.open()
		if holder.Visible then
			return
		end
		token += 1
		holder.Visible = true
		frame.GroupTransparency = 1
		frame.Position = UDim2.fromOffset(0, 26)
		TweenService:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }):Play()
		Sfx.play("ui_open")
		if window.onOpen then
			window.onOpen()
		end
	end

	function window.close()
		if not holder.Visible then
			return
		end
		token += 1
		local mine = token
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1, Position = UDim2.fromOffset(0, 18) }):Play()
		Sfx.play("ui_close")
		task.delay(0.15, function()
			if token == mine then
				holder.Visible = false
			end
		end)
		if window.onClose then
			window.onClose()
		end
	end

	function window.toggle()
		if holder.Visible then
			window.close()
		else
			window.open()
		end
	end

	close.Activated:Connect(window.close)
	return window
end

return Kit
