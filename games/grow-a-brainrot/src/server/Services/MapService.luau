-- Builds the shared world at runtime: lighting, ground, plaza, pack shop,
-- Lost & Found, road, trees, flowers, hills, clouds and floating decorations.
-- Gameplay anchors other services use: Root, ShopPrompt, LostFoundPrompt, RoadWaypoints.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Style = require(ReplicatedStorage.Shared.Style)

local MapService = {}

local P = Style.Palette
local rng = Random.new(67)

MapService.Root = nil

local function sign(parent, text, size, color, offset)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = offset or Vector3.new(0, 6, 0)
	gui.MaxDistance = 260
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(25, 18, 45)
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = parent
	return gui
end

local function surfaceText(part, face, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(25, 18, 45)
	stroke.Thickness = 6
	stroke.Parent = label
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = label
	label.Parent = gui
	gui.Parent = part
	return gui
end

--------------------------------------------------------------------------------

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(125, 120, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4

	local function ensure(className, name)
		local inst = Lighting:FindFirstChild(name) or Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
		return inst
	end
	local cc = ensure("ColorCorrectionEffect", "GrowABrainrotCC")
	cc.Saturation = 0.22
	cc.Contrast = 0.08
	cc.Brightness = 0.02
	local bloom = ensure("BloomEffect", "GrowABrainrotBloom")
	bloom.Intensity = 0.5
	bloom.Size = 28
	bloom.Threshold = 1.4
	local rays = ensure("SunRaysEffect", "GrowABrainrotRays")
	rays.Intensity = 0.04
	rays.Spread = 0.6
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or ensure("Atmosphere", "GrowABrainrotAtmosphere")
	atmosphere.Density = 0.26
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 230, 255)
	atmosphere.Decay = Color3.fromRGB(150, 180, 255)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1
	-- other atmospheres/blooms from the template would double up
	for _, child in Lighting:GetChildren() do
		if (child:IsA("BloomEffect") and child ~= bloom) or (child:IsA("Atmosphere") and child ~= atmosphere) then
			child:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- Scenery

local function tree(parent, position: Vector3, scale: number, palette)
	local model = Instance.new("Model")
	model.Name = "Tree"
	local trunkH = 7 * scale
	Style.cylinder(model, trunkH, 1.8 * scale, CFrame.new(position), P.WoodDark)
	local top = position + Vector3.new(0, trunkH, 0)
	local canopy = palette[rng:NextInteger(1, #palette)]
	Style.ball(model, 8 * scale, CFrame.new(top + Vector3.new(0, 1.5 * scale, 0)), canopy, { Reflectance = 0.06 })
	Style.ball(model, 5.5 * scale, CFrame.new(top + Vector3.new(2.6 * scale, 0.2, 1 * scale)), canopy:Lerp(Color3.new(1, 1, 1), 0.12), { Reflectance = 0.06 })
	Style.ball(model, 5 * scale, CFrame.new(top + Vector3.new(-2.4 * scale, 0.6, -1.2 * scale)), canopy:Lerp(Color3.new(0, 0, 0), 0.08), { Reflectance = 0.06 })
	Style.ball(model, 4.4 * scale, CFrame.new(top + Vector3.new(0.4, 4.6 * scale, 0)), canopy:Lerp(Color3.new(1, 1, 1), 0.2), { Reflectance = 0.06 })
	model.Parent = parent
end

local FLOWER_COLORS = { P.Pink, P.Gold, P.Sky, P.Purple, P.White, P.Orange }
local function flower(parent, position: Vector3)
	local color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	Style.cylinder(parent, 1.4, 0.3, CFrame.new(position), P.GrassDark, { CanCollide = false })
	local head = position + Vector3.new(0, 1.6, 0)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		Style.ball(parent, 0.7, CFrame.new(head + Vector3.new(math.cos(a) * 0.4, 0, math.sin(a) * 0.4)), color, { CanCollide = false, CastShadow = false })
	end
	Style.ball(parent, 0.5, CFrame.new(head + Vector3.new(0, 0.1, 0)), P.Gold, { CanCollide = false, CastShadow = false })
end

local function cloud(parent, position: Vector3, scale: number)
	local model = Instance.new("Model")
	model.Name = "Cloud"
	local puffs = { { 0, 0, 0, 12 }, { 7, -1, 1, 9 }, { -7, -1.5, -1, 9 }, { 3, 3, -1, 8 }, { -3, 2, 2, 7 } }
	for _, puff in puffs do
		Style.ball(model, puff[4] * scale, CFrame.new(position + Vector3.new(puff[1], puff[2], puff[3]) * scale), P.White, {
			CanCollide = false, CanQuery = false, CastShadow = false, Reflectance = 0,
		})
	end
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	model:SetAttribute("DriftSpeed", rng:NextNumber(1.5, 3.5))
	CollectionService:AddTag(model, "Cloud")
	model.Parent = parent
end

local function gem(parent, position: Vector3, color: Color3)
	local g = Style.part(parent, {
		Name = "Gem",
		Size = Vector3.new(2.2, 2.2, 2.2),
		CFrame = CFrame.new(position) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
		Color = color,
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Reflectance = 0.2,
		CanCollide = false,
		CastShadow = false,
	})
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 10
	light.Brightness = 1.2
	light.Parent = g
	Style.spin(g, 60)
	Style.float(g, 0.8, 1.2)
	return g
end

--------------------------------------------------------------------------------
-- Buildings

local function buildPlaza(root)
	-- layered round platform: dark ring, cream base, light inner circle
	Style.cylinder(root, 0.5, 70, CFrame.new(0, 0.3, 0), P.Orange)
	Style.cylinder(root, 0.6, 66, CFrame.new(0, 0.4, 0), P.Cream)
	Style.cylinder(root, 0.62, 30, CFrame.new(0, 0.42, 0), P.Path)
	-- ring of studs around the edge (pastel, alternating)
	local studColors = { P.Pink, P.Sky, P.Gold, P.Mint }
	for i = 0, 47 do
		local a = i / 48 * math.pi * 2
		Style.cylinder(root, 0.4, 1.3, CFrame.new(math.cos(a) * 31.5, 1.0, math.sin(a) * 31.5), studColors[i % 4 + 1], { CanCollide = false })
	end
	-- floating gems around the plaza
	local gemColors = { P.Pink, P.Sky, P.Gold, P.Purple }
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local base = Vector3.new(math.cos(a) * 28, 0.9, math.sin(a) * 28)
		Style.cylinder(root, 2.5, 3, CFrame.new(base), P.White)
		Style.cylinder(root, 0.5, 3.6, CFrame.new(base + Vector3.new(0, 2.5, 0)), gemColors[i + 1])
		gem(root, base + Vector3.new(0, 6, 0), gemColors[i + 1])
	end
end

local function buildShop(root)
	local stand = Instance.new("Model")
	stand.Name = "PackShop"
	local counter = Style.roundedBox(stand, Vector3.new(24, 4.5, 8), CFrame.new(0, 3.1, 0), P.Pink, 2)
	Style.roundedBox(stand, Vector3.new(25, 0.8, 9), CFrame.new(0, 5.7, 0), P.Cream, 2.4)
	Style.studs(stand, CFrame.new(-10.5, 6.1, 0), 1, 3, 2, P.Gold)
	Style.studs(stand, CFrame.new(10.5, 6.1, 0), 1, 3, 2, P.Gold)
	-- stripe band on the counter front
	Style.part(stand, { Size = Vector3.new(20, 0.8, 0.2), CFrame = CFrame.new(0, 2.2, -4.05), Color = P.White, CanCollide = false })
	-- poles + striped awning with light bulbs
	for _, x in { -11, 11 } do
		Style.cylinder(stand, 13, 1, CFrame.new(x, 1, 2.5), P.White)
		Style.ball(stand, 1.6, CFrame.new(x, 14.3, 2.5), P.Gold)
	end
	local stripes = { P.Pink, P.White }
	for i = 0, 7 do
		Style.part(stand, {
			Name = "Awning",
			Size = Vector3.new(3.1, 0.6, 11),
			CFrame = CFrame.new(-10.85 + i * 3.1, 15.5, 0) * CFrame.Angles(math.rad(-14), 0, 0),
			Color = stripes[i % 2 + 1],
		})
		Style.ball(stand, 0.8, CFrame.new(-10.85 + i * 3.1, 13.9, -5.2), if i % 2 == 0 then P.Gold else P.Sky, {
			Material = Enum.Material.Neon, CanCollide = false, CastShadow = false,
		})
	end
	-- pack boxes on the counter (the products!)
	local packColors = { Color3.fromRGB(190, 140, 90), Color3.fromRGB(90, 220, 110), Color3.fromRGB(70, 150, 255), Color3.fromRGB(180, 90, 255), Color3.fromRGB(255, 210, 60) }
	for i, color in packColors do
		local box = Style.roundedBox(stand, Vector3.new(2.6, 3.2, 1.8), CFrame.new(-7.5 + (i - 1) * 3.75, 7.7, 0.5) * CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0), color, 0.6)
		box.Name = "PackBox"
	end
	-- big floating sign
	local board = Style.roundedBox(stand, Vector3.new(18, 4.5, 1), CFrame.new(0, 21, 0), P.Gold, 1.6)
	surfaceText(board, Enum.NormalId.Front, "PACK SHOP", P.White)
	surfaceText(board, Enum.NormalId.Back, "PACK SHOP", P.White)
	for _, piece in board.Parent:GetChildren() do
		Style.float(piece, 0.6, 1.2, 0)
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Pack Shop"
	prompt.ObjectText = "Seed Packs"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	stand.Parent = root
	return prompt
end

local function buildLostFound(root)
	local booth = Style.roundedBox(root, Vector3.new(10, 5, 6), CFrame.new(-24, 3.2, 14), P.Purple, 1.5)
	Style.roundedBox(root, Vector3.new(11.5, 0.8, 7.5), CFrame.new(-24, 6.1, 14), P.Cream, 1.8)
	Style.studs(root, CFrame.new(-24, 6.5, 14), 4, 2, 2, P.Sky)
	sign(booth, "LOST & FOUND", UDim2.fromOffset(300, 60), Color3.fromRGB(215, 200, 255), Vector3.new(0, 6, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Recover stolen brainrots"
	prompt.ObjectText = "Lost & Found"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = booth
	return prompt
end

local function buildRoad(root)
	local roadX, roadZ, width, top = 160, 38, 10, 0.8
	local function segment(size, cf)
		Style.part(root, { Name = "Road", Size = size, CFrame = cf, Color = P.Road })
	end
	segment(Vector3.new(roadX * 2 + width, 0.6, width), CFrame.new(0, 0.5, roadZ))
	segment(Vector3.new(roadX * 2 + width, 0.6, width), CFrame.new(0, 0.5, -roadZ))
	segment(Vector3.new(width, 0.6, roadZ * 2), CFrame.new(roadX, 0.5, 0))
	segment(Vector3.new(width, 0.6, roadZ * 2), CFrame.new(-roadX, 0.5, 0))
	-- cream curbs
	for _, z in { roadZ, -roadZ } do
		for _, side in { -1, 1 } do
			Style.part(root, { Name = "Curb", Size = Vector3.new(roadX * 2 + width + 2, 0.9, 1), CFrame = CFrame.new(0, 0.6, z + side * (width / 2 + 0.5)), Color = P.Cream })
		end
	end
	for _, x in { roadX, -roadX } do
		for _, side in { -1, 1 } do
			Style.part(root, { Name = "Curb", Size = Vector3.new(1, 0.9, roadZ * 2 - width - 2), CFrame = CFrame.new(x + side * (width / 2 + 0.5), 0.6, 0), Color = P.Cream })
		end
	end
	-- dashed center line
	for x = -roadX + 10, roadX - 10, 20 do
		for _, z in { roadZ, -roadZ } do
			Style.part(root, { Name = "RoadLine", Size = Vector3.new(8, 0.1, 0.8), CFrame = CFrame.new(x, 0.85, z), Color = P.Gold, CanCollide = false })
		end
	end
	MapService.RoadWaypoints = {
		Vector3.new(roadX, top, roadZ),
		Vector3.new(-roadX, top, roadZ),
		Vector3.new(-roadX, top, -roadZ),
		Vector3.new(roadX, top, -roadZ),
	}
end

local function buildScenery(root)
	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = root

	-- soft lighter grass patches
	for _ = 1, 26 do
		local pos = Vector3.new(rng:NextNumber(-200, 200), 0.52, rng:NextNumber(-165, 165))
		if math.abs(pos.Z) > 48 or math.abs(pos.X) > 175 then
			Style.cylinder(scenery, 0.05, rng:NextNumber(10, 26), CFrame.new(pos), P.GrassLight, { CanCollide = false, CastShadow = false })
		end
	end

	-- trees between the gardens and around the map edge
	local leafy = { P.Grass, P.GrassDark, Color3.fromRGB(150, 215, 80) }
	local candy = { P.Pink, Color3.fromRGB(255, 170, 90), P.Purple }
	for _, x in { -160, -80, 0, 80, 160 } do
		for _, z in { -82, 82 } do
			tree(scenery, Vector3.new(x, 0.5, z), rng:NextNumber(0.9, 1.15), if (x / 80) % 2 == 0 then leafy else candy)
		end
	end
	for i = 0, 15 do
		local x = -195 + i * 26
		tree(scenery, Vector3.new(x + rng:NextNumber(-4, 4), 0.5, 140 + rng:NextNumber(-6, 6)), rng:NextNumber(1, 1.4), if i % 3 == 0 then candy else leafy)
		tree(scenery, Vector3.new(x + rng:NextNumber(-4, 4), 0.5, -140 + rng:NextNumber(-6, 6)), rng:NextNumber(1, 1.4), if i % 3 == 1 then candy else leafy)
	end

	-- flower beds hugging the plaza
	for i = 0, 35 do
		local a = i / 36 * math.pi * 2
		local r = 34.5 + rng:NextNumber(-0.6, 0.6)
		local pos = Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)
		if math.abs(pos.Z) < 31 then -- keep out of the road
			flower(scenery, pos)
		end
	end

	-- rolling hills at the map edge
	for i = 0, 21 do
		local a = i / 22 * math.pi * 2
		local pos = Vector3.new(math.cos(a) * 250, -8, math.sin(a) * 205)
		Style.ball(scenery, rng:NextNumber(55, 80), CFrame.new(pos), if i % 2 == 0 then P.Grass else P.GrassDark, { CastShadow = false })
	end

	-- drifting clouds
	for i = 1, 10 do
		cloud(scenery, Vector3.new(rng:NextNumber(-260, 260), rng:NextNumber(90, 130), rng:NextNumber(-200, 200)), rng:NextNumber(0.8, 1.5))
	end
end

--------------------------------------------------------------------------------

function MapService.init()
	setupLighting()
	local root = Instance.new("Folder")
	root.Name = "GrowABrainrotWorld"

	Style.part(root, { Name = "Ground", Size = Vector3.new(440, 1, 360), CFrame = CFrame.new(0, 0, 0), Color = P.Grass })
	buildPlaza(root)
	buildRoad(root)
	MapService.LostFoundPrompt = buildLostFound(root)
	MapService.ShopPrompt = buildShop(root)
	buildScenery(root)

	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.CFrame = CFrame.new(0, 1.3, 18)
		spawn.Transparency = 1
		spawn.CanCollide = false
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
	end

	root.Parent = workspace
	MapService.Root = root
end

return MapService
