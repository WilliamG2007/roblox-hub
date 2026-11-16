-- Tiny UI toolkit: theme + helpers so every screen looks the same.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Kit = {}

Kit.Theme = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamBold,
	Text = Color3.new(1, 1, 1),
	Panel = Color3.fromRGB(30, 26, 60),
	PanelLight = Color3.fromRGB(50, 44, 95),
	Accent = Color3.fromRGB(255, 200, 60),
	Good = Color3.fromRGB(90, 230, 110),
	Bad = Color3.fromRGB(255, 100, 110),
	Cash = Color3.fromRGB(120, 255, 140),
}

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
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Kit.label(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Kit.Theme.Title
	props.TextColor3 = props.TextColor3 or Kit.Theme.Text
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.4
	return Kit.new("TextLabel", props)
end

function Kit.button(props)
	props.Font = props.Font or Kit.Theme.Title
	props.TextColor3 = props.TextColor3 or Kit.Theme.Text
	props.AutoButtonColor = true
	local button = Kit.new("TextButton", props)
	Kit.corner(button, 10)
	Kit.stroke(button, Color3.new(0, 0, 0), 2.5)
	button.Activated:Connect(function()
		Kit.bounce(button)
	end)
	return button
end

function Kit.bounce(gui: GuiObject)
	local scale = gui:FindFirstChild("BounceScale") or Kit.new("UIScale", { Name = "BounceScale", Parent = gui })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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
function Kit.autoScale(frame: GuiObject)
	local s = Kit.new("UIScale", { Name = "AutoScale", Parent = frame })
	table.insert(scaled, s)
	local camera = workspace.CurrentCamera
	s.Scale = math.clamp(camera.ViewportSize.Y / 900, 0.55, 1.2)
	return frame
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local y = workspace.CurrentCamera.ViewportSize.Y
	for _, s in scaled do
		s.Scale = math.clamp(y / 900, 0.55, 1.2)
	end
end)

function Kit.sound(volume: number?, pitch: number?)
	local sound = Kit.new("Sound", {
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		Volume = volume or 0.4,
		PlaybackSpeed = pitch or 1,
		Parent = workspace.CurrentCamera,
	})
	sound:Play()
	task.delay(3, function()
		sound:Destroy()
	end)
end

return Kit
