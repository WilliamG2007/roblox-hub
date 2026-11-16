-- UI toolkit: one visual language for every screen.
-- Bubbly, glossy, thick outlines, big readable type, satisfying motion + sound.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Sfx = require(script.Parent.Sfx)

local Kit = {}

Kit.Theme = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamBold,
	Text = Color3.new(1, 1, 1),
	Outline = Color3.fromRGB(25, 18, 45),
	Panel = Color3.fromRGB(38, 30, 78),
	PanelDark = Color3.fromRGB(24, 18, 52),
	PanelLight = Color3.fromRGB(62, 52, 120),
	Accent = Color3.fromRGB(255, 205, 60),
	Good = Color3.fromRGB(80, 220, 100),
	Bad = Color3.fromRGB(255, 90, 105),
	Disabled = Color3.fromRGB(95, 92, 110),
	Cash = Color3.fromRGB(120, 255, 140),
	Shards = Color3.fromRGB(165, 195, 255),
	-- screen accents
	Pink = Color3.fromRGB(255, 105, 170),
	Blue = Color3.fromRGB(80, 160, 255),
	Purple = Color3.fromRGB(160, 100, 255),
	Orange = Color3.fromRGB(255, 150, 50),
	Red = Color3.fromRGB(235, 70, 80),
}

local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

function Kit.stroke(parent, color: Color3?, thickness: number?)
	return Kit.new("UIStroke", {
		Color = color or Kit.Theme.Outline,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

-- glossy look: lighter top, darker bottom (multiplies the background color)
function Kit.gloss(parent, strength: number?)
	local s = strength or 0.25
	return Kit.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1 - s * 0.3, 1 - s * 0.3, 1 - s * 0.3)),
			ColorSequenceKeypoint.new(1, Color3.new(1 - s, 1 - s, 1 - s)),
		}),
		Parent = parent,
	})
end

-- text with a thick dark outline (reads on any background)
function Kit.label(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Kit.Theme.Title
	props.TextColor3 = props.TextColor3 or Kit.Theme.Text
	local outline = props.Outline
	props.Outline = nil
	props.TextStrokeTransparency = 1
	local label = Kit.new("TextLabel", props)
	if outline ~= false then
		Kit.new("UIStroke", {
			Color = Kit.Theme.Outline,
			Thickness = if (props.TextSize or 20) >= 28 then 2.5 else 1.8,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
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

-- Bubbly button: hover grows it, press squishes it, release bounces back.
-- opts.sound: click sound name (default "ui_click", false for none)
function Kit.button(props, opts: { sound: any? }?)
	props.Font = props.Font or Kit.Theme.Title
	props.TextColor3 = props.TextColor3 or Kit.Theme.Text
	props.AutoButtonColor = false
	props.BackgroundColor3 = props.BackgroundColor3 or Kit.Theme.Good
	props.TextStrokeColor3 = Kit.Theme.Outline
	props.TextStrokeTransparency = 0.15
	local button = Kit.new("TextButton", props)
	Kit.corner(button, 12)
	Kit.stroke(button, Kit.Theme.Outline, 3) -- the button's only UIStroke (other code looks it up)
	Kit.gloss(button)
	local scale = animScale(button)
	local hovering = false
	button.MouseEnter:Connect(function()
		hovering = true
		TweenService:Create(scale, QUICK, { Scale = 1.06 }):Play()
		Sfx.play("ui_hover")
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		TweenService:Create(scale, QUICK, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, QUICK, { Scale = 0.9 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, BOUNCE, { Scale = if hovering then 1.06 else 1 }):Play()
	end)
	local sound = if opts and opts.sound ~= nil then opts.sound else "ui_click"
	button.Activated:Connect(function()
		if sound then
			Sfx.play(sound)
		end
	end)
	return button
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

-- Fades a label (text + its outline stroke) or frame out over `seconds`.
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

-- Soft drop shadow behind a frame (as a sibling, so it can sit underneath).
function Kit.shadow(target: GuiObject, offset: number?)
	local shadow = Kit.new("Frame", {
		Name = target.Name .. "Shadow",
		AnchorPoint = target.AnchorPoint,
		Position = target.Position + UDim2.fromOffset(0, offset or 8),
		Size = target.Size,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		ZIndex = target.ZIndex - 1,
		Parent = target.Parent,
	})
	Kit.corner(shadow, 20)
	return shadow
end

-- A pill showing an icon + value (currency displays).
function Kit.pill(props: { Parent: Instance, Position: UDim2, Size: UDim2, Color: Color3, Icon: string, AnchorPoint: Vector2? })
	local pill = Kit.new("Frame", {
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = Kit.Theme.PanelDark,
		BackgroundTransparency = 0.1,
		Parent = props.Parent,
	})
	Kit.corner(pill, 999)
	Kit.stroke(pill, Kit.Theme.Outline, 3)
	local h = props.Size.Y.Offset
	local icon = Kit.new("Frame", { Position = UDim2.fromOffset(-4, -4), Size = UDim2.fromOffset(h + 8, h + 8), BackgroundColor3 = props.Color, Parent = pill })
	Kit.corner(icon, 999)
	Kit.stroke(icon, Kit.Theme.Outline, 3)
	Kit.gloss(icon, 0.35)
	Kit.label({ Size = UDim2.fromScale(1, 1), Text = props.Icon, TextScaled = true, Parent = icon })
	local value = Kit.label({ Name = "Value", Position = UDim2.fromOffset(h + 12, 0), Size = UDim2.new(1, -h - 20, 1, 0), Text = "0", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = props.Color, Parent = pill })
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = value })
	return pill, value, icon
end

-- Standard window: shadow, gradient body, colored header with title + close,
-- slide/fade in and out. Content goes in window.frame (header is the top 60px).
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
	local shadow = Kit.new("Frame", { Position = UDim2.fromOffset(0, 10), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Parent = holder })
	Kit.corner(shadow, 22)

	local frame = Kit.new("CanvasGroup", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Kit.Theme.Panel, Parent = holder })
	Kit.corner(frame, 22)
	Kit.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 140, 200)), Parent = frame })
	local outline = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = holder })
	Kit.corner(outline, 22)
	Kit.stroke(outline, Kit.Theme.Outline, 4)

	local header = Kit.new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = opts.accent, Parent = frame })
	Kit.gloss(header, 0.3)
	Kit.new("Frame", { Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Kit.Theme.Outline, BorderSizePixel = 0, Parent = header })
	Kit.label({ Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -90, 1, -14), Text = opts.title, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = header })

	local closeHolder = Kit.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -6), Size = UDim2.fromOffset(50, 50), BackgroundTransparency = 1, ZIndex = 60, Parent = holder })
	local close = Kit.button({ Size = UDim2.fromScale(1, 1), Text = "X", TextSize = 28, BackgroundColor3 = Kit.Theme.Red, ZIndex = 60, Parent = closeHolder }, { sound = false })

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
		frame.Position = UDim2.fromOffset(0, 30)
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }):Play()
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
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1, Position = UDim2.fromOffset(0, 20) }):Play()
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
