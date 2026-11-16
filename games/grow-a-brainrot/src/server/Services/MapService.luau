-- Builds the shared world at runtime: bright ground, sky, the central pack shop.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(ReplicatedStorage.Shared.Style)

local MapService = {}

MapService.Root = nil
MapService.ShopStand = nil

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	Style.brick(p)
	if props.Shape then
		p.Shape = props.Shape
		props.Shape = nil
	end
	for key, value in props do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function sign(parent, text, size, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.MaxDistance = 250
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = parent
	return gui
end

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(120, 120, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	local cc = Lighting:FindFirstChild("GrowABrainrotCC") or Instance.new("ColorCorrectionEffect")
	cc.Name = "GrowABrainrotCC"
	cc.Saturation = 0.25
	cc.Contrast = 0.05
	cc.Parent = Lighting
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0.2
		atmosphere.Haze = 0
		atmosphere.Color = Color3.fromRGB(200, 230, 255)
	end
end

local function buildShop(root)
	local stand = Instance.new("Model")
	stand.Name = "SeedShop"
	local base = part(stand, { Name = "Counter", Size = Vector3.new(22, 4, 8), CFrame = CFrame.new(0, 2.5, 0), Color = Color3.fromRGB(255, 170, 60) })
	part(stand, { Name = "CounterTop", Size = Vector3.new(23, 0.8, 9), CFrame = CFrame.new(0, 4.9, 0), Color = Color3.fromRGB(255, 240, 220) })
	for _, x in { -10, 10 } do
		part(stand, { Name = "Pole", Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(x, 11, 0), Color = Color3.fromRGB(255, 255, 255) })
	end
	-- striped awning
	local stripes = { Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 255, 255) }
	for i = 0, 7 do
		part(stand, {
			Name = "Awning",
			Size = Vector3.new(3, 0.6, 10),
			CFrame = CFrame.new(-10.5 + i * 3, 17.2, 0) * CFrame.Angles(math.rad(-12), 0, 0),
			Color = stripes[i % 2 + 1],
		})
	end
	-- seed sacks
	local sackColors = { Color3.fromRGB(120, 220, 100), Color3.fromRGB(80, 170, 255), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 210, 60) }
	for i, color in sackColors do
		part(stand, { Name = "Sack", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.6, CFrame = CFrame.new(-7 + (i - 1) * 4.7, 6.4, 0), Color = color })
	end
	sign(base, "PACK SHOP", UDim2.fromOffset(400, 90), Color3.fromRGB(255, 240, 120)).StudsOffset = Vector3.new(0, 18, 0)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Pack Shop"
	prompt.ObjectText = "Seed Packs"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = base

	stand.PrimaryPart = base
	stand.Parent = root
	return stand, prompt
end

function MapService.init()
	setupLighting()
	local root = Instance.new("Folder")
	root.Name = "GrowABrainrotWorld"
	part(root, { Name = "Ground", Size = Vector3.new(420, 1, 340), CFrame = CFrame.new(0, 0, 0), Color = Color3.fromRGB(95, 200, 90) })
	part(root, { Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 60, 60), CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(240, 225, 190) })
	-- road loop around the plaza where wild brainrots walk
	local roadX, roadZ, roadWidth, roadTop = 160, 38, 10, 0.8
	local roadColor = Color3.fromRGB(105, 105, 120)
	part(root, { Name = "Road", Size = Vector3.new(roadX * 2 + roadWidth, 0.6, roadWidth), CFrame = CFrame.new(0, 0.5, roadZ), Color = roadColor })
	part(root, { Name = "Road", Size = Vector3.new(roadX * 2 + roadWidth, 0.6, roadWidth), CFrame = CFrame.new(0, 0.5, -roadZ), Color = roadColor })
	part(root, { Name = "Road", Size = Vector3.new(roadWidth, 0.6, roadZ * 2), CFrame = CFrame.new(roadX, 0.5, 0), Color = roadColor })
	part(root, { Name = "Road", Size = Vector3.new(roadWidth, 0.6, roadZ * 2), CFrame = CFrame.new(-roadX, 0.5, 0), Color = roadColor })
	-- dashed center line
	for x = -roadX + 10, roadX - 10, 20 do
		for _, z in { roadZ, -roadZ } do
			part(root, { Name = "RoadLine", Size = Vector3.new(8, 0.1, 0.8), CFrame = CFrame.new(x, 0.85, z), Color = Color3.fromRGB(255, 220, 80), CanCollide = false })
		end
	end
	MapService.RoadWaypoints = {
		Vector3.new(roadX, roadTop, roadZ),
		Vector3.new(-roadX, roadTop, roadZ),
		Vector3.new(-roadX, roadTop, -roadZ),
		Vector3.new(roadX, roadTop, -roadZ),
	}

	-- Lost & Found booth (brainrots stolen by night monsters)
	local booth = part(root, { Name = "LostFound", Size = Vector3.new(10, 5, 6), CFrame = CFrame.new(-24, 3, 14), Color = Color3.fromRGB(110, 90, 200) })
	part(root, { Name = "LostFoundTop", Size = Vector3.new(11, 0.8, 7), CFrame = CFrame.new(-24, 5.9, 14), Color = Color3.fromRGB(255, 240, 220) })
	sign(booth, "LOST & FOUND", UDim2.fromOffset(300, 60), Color3.fromRGB(200, 190, 255)).StudsOffset = Vector3.new(0, 6, 0)
	local lostPrompt = Instance.new("ProximityPrompt")
	lostPrompt.ActionText = "Recover stolen brainrots"
	lostPrompt.ObjectText = "Lost & Found"
	lostPrompt.MaxActivationDistance = 12
	lostPrompt.RequiresLineOfSight = false
	lostPrompt.Parent = booth
	MapService.LostFoundPrompt = lostPrompt

	local stand, prompt = buildShop(root)
	MapService.ShopStand = stand
	MapService.ShopPrompt = prompt

	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.CFrame = CFrame.new(0, 1.3, 18)
	end

	root.Parent = workspace
	MapService.Root = root
end

return MapService
