-- Builds the whole map: lighting, ground, plaza, pack shop, Lost & Found,
-- Wall of Fame, road, garden plots, statues, scenery.
--
-- BAKE IT INTO THE PLACE (so you can see and edit the map in Studio):
--   Studio > View > Command Bar, paste and press Enter:
--     require(game.ServerScriptService.Server.World.WorldBuilder:Clone()).bake()
--   then File > Save. The game uses Workspace.GrowABrainrotWorld if it exists
--   and only builds a fresh one when it's missing.
--   Rebuild over an existing bake (wipes manual edits inside it!):
--     require(game.ServerScriptService.Server.World.WorldBuilder:Clone()).bake(true)
--
-- Gameplay code finds things by name, so keep these if you edit the map:
--   ShopPrompt, LostFoundPrompt, WallOfFame, Plots/Plot<n>/(Tile<i>, CollectPad, SignPost),
--   and the RoadX / RoadZ / RoadTop attributes on GrowABrainrotWorld.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Style = require(Shared.Style)
local GameConfig = require(Shared.Config.Game)
local BrainrotModels = require(Shared.BrainrotModels)

local WorldBuilder = {}

local P = Style.Palette
local ROOT_NAME = "GrowABrainrotWorld"
local OUTLINE = Color3.fromRGB(25, 18, 45)
local rng

--------------------------------------------------------------------------------
-- text helpers

local function strokeLabel(label, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = thickness
	stroke.Parent = label
end

local function billboard(parent, name, text, size, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = size
	gui.StudsOffset = offset
	gui.MaxDistance = 220
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	strokeLabel(label, 3)
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
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	strokeLabel(label, 6)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.14, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = label
	label.Parent = gui
	gui.Parent = part
	return gui
end

local function prompt(parent, name, action, object, distance)
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = distance or 14
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

--------------------------------------------------------------------------------
-- lighting

function WorldBuilder.lighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.8
	Lighting.Ambient = Color3.fromRGB(135, 125, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 155, 180)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.45

	local function ensure(className, name)
		local inst = Lighting:FindFirstChild(name) or Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
		return inst
	end
	local cc = ensure("ColorCorrectionEffect", "GrowABrainrotCC")
	cc.Saturation = 0.3
	cc.Contrast = 0.1
	cc.Brightness = 0.03
	cc.TintColor = Color3.new(1, 1, 1)
	local bloom = ensure("BloomEffect", "GrowABrainrotBloom")
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 1.35
	local rays = ensure("SunRaysEffect", "GrowABrainrotRays")
	rays.Intensity = 0.05
	rays.Spread = 0.6
	local atmosphere = ensure("Atmosphere", "GrowABrainrotAtmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(215, 235, 255)
	atmosphere.Decay = Color3.fromRGB(255, 175, 200) -- pastel pink/peach haze on the horizon
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.2
	for _, child in Lighting:GetChildren() do
		if (child:IsA("BloomEffect") and child ~= bloom) or (child:IsA("Atmosphere") and child ~= atmosphere) then
			child:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- scenery pieces

local function tree(parent, position: Vector3, scale: number, palette)
	local model = Instance.new("Model")
	model.Name = "Tree"
	local trunkH = 6.5 * scale
	Style.cylinder(model, trunkH, 1.6 * scale, CFrame.new(position), P.WoodDark)
	local top = position + Vector3.new(0, trunkH, 0)
	local canopy = palette[rng:NextInteger(1, #palette)]
	-- faceted low-poly canopy: a few randomly rotated cubes
	local blobs = { { 0, 2, 0, 7.5 }, { 2.4, 0.6, 1, 5 }, { -2.2, 1, -1.2, 4.8 }, { 0.3, 5, 0.2, 4.4 } }
	for i, b in blobs do
		Style.part(model, {
			Name = "Leaves",
			Size = Vector3.one * b[4] * scale,
			CFrame = CFrame.new(top + Vector3.new(b[1], b[2], b[3]) * scale) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
			Color = canopy:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.07),
		})
	end
	model.Parent = parent
end

-- string of diamond pennant flags between two points, sagging in the middle
local BUNTING_COLORS = { P.Pink, P.Gold, P.Turquoise, P.Lime, P.Purple, P.Orange }
local function bunting(parent, a: Vector3, b: Vector3, sag: number)
	local model = Instance.new("Model")
	model.Name = "Bunting"
	local count = math.max(2, math.floor((b - a).Magnitude / 3.2))
	local side = (b - a).Unit:Cross(Vector3.yAxis)
	local function at(t)
		return a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
	end
	local prev = a
	for i = 1, count do
		local p = at(i / count)
		Style.part(model, { Name = "String", Size = Vector3.new(0.15, 0.15, (p - prev).Magnitude), CFrame = CFrame.lookAt((prev + p) / 2, p), Color = P.White, CanCollide = false, CastShadow = false })
		local flagPos = at((i - 0.5) / count) - Vector3.new(0, 1.1, 0)
		Style.part(model, {
			Name = "Flag",
			Size = Vector3.new(1.6, 1.6, 0.15),
			CFrame = CFrame.lookAt(flagPos, flagPos + side) * CFrame.Angles(0, 0, math.rad(45)),
			Color = BUNTING_COLORS[(i - 1) % #BUNTING_COLORS + 1],
			CanCollide = false,
			CastShadow = false,
		})
		prev = p
	end
	model.Parent = parent
end

local BALLOON_COLORS = { P.Pink, P.Turquoise, P.Gold, P.Purple, P.Orange, P.Lime }
local function balloon(parent, anchor: Vector3, height: number)
	local color = BALLOON_COLORS[rng:NextInteger(1, #BALLOON_COLORS)]
	local top = anchor + Vector3.new(rng:NextNumber(-1, 1), height, rng:NextNumber(-1, 1))
	Style.part(parent, { Name = "BalloonString", Size = Vector3.new(0.1, 0.1, (top - anchor).Magnitude), CFrame = CFrame.lookAt((anchor + top) / 2, top), Color = P.White, CanCollide = false, CastShadow = false })
	local b = Style.ball(parent, 3.2, CFrame.new(top + Vector3.new(0, 1.5, 0)), color, { Name = "Balloon", Reflectance = 0.15, CanCollide = false })
	local knot = Style.ball(parent, 0.6, CFrame.new(top), color, { CanCollide = false, CastShadow = false })
	local phase = rng:NextNumber(0, 6)
	Style.float(b, 0.4, 1.3, phase)
	Style.float(knot, 0.4, 1.3, phase)
end

local POLE = Color3.fromRGB(70, 45, 110)
local function lamppost(parent, position: Vector3)
	Style.cylinder(parent, 9, 0.7, CFrame.new(position), POLE)
	Style.cylinder(parent, 0.6, 1.6, CFrame.new(position + Vector3.new(0, 9, 0)), POLE)
	local bulb = Style.ball(parent, 1.8, CFrame.new(position + Vector3.new(0, 10.4, 0)), Color3.fromRGB(255, 240, 200), { Material = Enum.Material.Neon, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 170)
	light.Range = 22
	light.Brightness = 1.2
	light.Parent = bulb
end

-- white picket fence along a straight line (posts + two long rails)
local function fence(parent, a: Vector3, b: Vector3)
	local dir = b - a
	local length = dir.Magnitude
	local cf = CFrame.lookAt(a:Lerp(b, 0.5), b)
	for _, y in { 1.4, 2.8 } do
		Style.part(parent, { Name = "Rail", Size = Vector3.new(0.4, 0.4, length), CFrame = cf + Vector3.new(0, y, 0), Color = P.White })
	end
	for i = 0, math.floor(length / 6) do
		local pos = a + dir.Unit * (i * 6)
		Style.part(parent, { Name = "Picket", Size = Vector3.new(0.8, 3.6, 0.5), CFrame = CFrame.lookAt(pos, pos + dir) + Vector3.new(0, 2.3, 0), Color = P.White })
	end
end

local FLOWER_COLORS = { P.Pink, P.Gold, P.Turquoise, P.Purple, P.White, P.Orange }
local function flower(parent, position: Vector3)
	local color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	Style.cylinder(parent, 1.4, 0.3, CFrame.new(position), P.GrassDark, { CanCollide = false })
	local head = position + Vector3.new(0, 1.6, 0)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		Style.ball(parent, 0.75, CFrame.new(head + Vector3.new(math.cos(a) * 0.42, 0, math.sin(a) * 0.42)), color, { CanCollide = false, CastShadow = false })
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
		Size = Vector3.new(2.4, 2.4, 2.4),
		CFrame = CFrame.new(position) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
		Color = color,
		Material = Enum.Material.Glass,
		Transparency = 0.1,
		Reflectance = 0.25,
		CanCollide = false,
		CastShadow = false,
	})
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.4
	light.Parent = g
	Style.spin(g, 60)
	Style.float(g, 0.8, 1.2)
end

-- signpost with a board of text on it
local function signpost(parent, position: Vector3, facing: Vector3, text: string, color: Color3)
	local cf = CFrame.lookAt(position, position + facing)
	Style.cylinder(parent, 7, 0.9, cf, P.WoodDark)
	local board = Style.roundedBox(parent, Vector3.new(10, 4, 0.8), cf * CFrame.new(0, 7.5, 0), color, 1.2)
	surfaceText(board, Enum.NormalId.Front, text, P.White)
	surfaceText(board, Enum.NormalId.Back, text, P.White)
end

-- giant golden brainrot statue on a stud pedestal (landmarks + brainrot identity)
local function statue(parent, position: Vector3, brainrotId: string, mutation: string, color: Color3, title: string)
	local folder = Instance.new("Model")
	folder.Name = "Statue_" .. brainrotId
	Style.roundedBox(folder, Vector3.new(14, 2, 14), CFrame.new(position + Vector3.new(0, 1, 0)), color, 3)
	Style.roundedBox(folder, Vector3.new(11, 3, 11), CFrame.new(position + Vector3.new(0, 3.5, 0)), P.Cream, 2.5)
	Style.studs(folder, CFrame.new(position + Vector3.new(0, 5, 0)), 4, 4, 2.2, color)
	local model = BrainrotModels.build(brainrotId, 3.2, mutation)
	model:PivotTo(CFrame.lookAt(position + Vector3.new(0, 5.4, 0), Vector3.new(0, position.Y + 5.4, 0)))
	for _, p in model:GetDescendants() do
		if p:IsA("ParticleEmitter") then
			p.Rate = 6
		end
	end
	model.Parent = folder
	local plaque = Style.part(folder, { Name = "Plaque", Size = Vector3.new(9, 2, 0.4), CFrame = CFrame.lookAt(position + Vector3.new(0, 3.5, 0), Vector3.new(0, position.Y + 3.5, 0)) * CFrame.new(0, 0, -5.7), Color = color })
	surfaceText(plaque, Enum.NormalId.Front, title, P.White)
	folder.Parent = parent
end

--------------------------------------------------------------------------------
-- big pieces

local function buildPlaza(root)
	Style.cylinder(root, 0.5, 72, CFrame.new(0, 0.3, 0), P.Pink)
	Style.cylinder(root, 0.6, 67, CFrame.new(0, 0.4, 0), Color3.fromRGB(255, 214, 196)) -- peach
	Style.cylinder(root, 0.62, 44, CFrame.new(0, 0.42, 0), P.Turquoise:Lerp(Color3.new(1, 1, 1), 0.55))
	Style.cylinder(root, 0.64, 30, CFrame.new(0, 0.44, 0), P.Path)
	-- ring of chunky studs around the edge
	local studColors = { P.Pink, P.Turquoise, P.Gold, P.Lime, P.Purple, P.Orange }
	for i = 0, 47 do
		local a = i / 48 * math.pi * 2
		Style.cylinder(root, 0.5, 1.5, CFrame.new(math.cos(a) * 32, 1.0, math.sin(a) * 32), studColors[i % #studColors + 1], { CanCollide = false })
	end
	local gemColors = { P.Pink, P.Turquoise, P.Gold, P.Purple }
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local base = Vector3.new(math.cos(a) * 28, 0.9, math.sin(a) * 28)
		Style.cylinder(root, 2.5, 3, CFrame.new(base), P.White)
		Style.cylinder(root, 0.6, 3.8, CFrame.new(base + Vector3.new(0, 2.5, 0)), gemColors[i + 1])
		gem(root, base + Vector3.new(0, 6, 0), gemColors[i + 1])
	end
	-- festival poles around the plaza with flags strung between them and balloons tied on
	local poles = {}
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + math.pi / 8
		local pos = Vector3.new(math.cos(a) * 33.5, 1, math.sin(a) * 33.5)
		local height = if i % 2 == 0 then 17 else 14
		Style.cylinder(root, height, 1, CFrame.new(pos), POLE)
		Style.ball(root, 1.8, CFrame.new(pos + Vector3.new(0, height + 0.6, 0)), P.Gold)
		table.insert(poles, pos + Vector3.new(0, height - 0.5, 0))
		balloon(root, pos + Vector3.new(0, height, 0), 4)
	end
	for i = 1, #poles do
		bunting(root, poles[i], poles[i % #poles + 1], 2.5)
	end
end

local function buildShop(root)
	local stand = Instance.new("Model")
	stand.Name = "PackShop"
	local counter = Style.roundedBox(stand, Vector3.new(24, 4.5, 8), CFrame.new(0, 3.1, 0), P.Pink, 2)
	Style.roundedBox(stand, Vector3.new(25, 0.8, 9), CFrame.new(0, 5.7, 0), P.Cream, 2.4)
	Style.studs(stand, CFrame.new(-10.5, 6.1, 0), 1, 3, 2, P.Gold)
	Style.studs(stand, CFrame.new(10.5, 6.1, 0), 1, 3, 2, P.Gold)
	Style.part(stand, { Size = Vector3.new(20, 0.9, 0.2), CFrame = CFrame.new(0, 2.2, -4.05), Color = P.White, CanCollide = false })
	for _, x in { -11, 11 } do
		Style.cylinder(stand, 13, 1.1, CFrame.new(x, 1, 2.5), P.Turquoise)
		Style.ball(stand, 1.8, CFrame.new(x, 14.3, 2.5), P.Gold)
	end
	local stripes = { P.Pink, P.White }
	for i = 0, 7 do
		Style.part(stand, {
			Name = "Awning",
			Size = Vector3.new(3.1, 0.7, 11),
			CFrame = CFrame.new(-10.85 + i * 3.1, 15.5, 0) * CFrame.Angles(math.rad(-14), 0, 0),
			Color = stripes[i % 2 + 1],
		})
		Style.ball(stand, 0.9, CFrame.new(-10.85 + i * 3.1, 13.9, -5.2), if i % 2 == 0 then P.Gold else P.Turquoise, {
			Material = Enum.Material.Neon, CanCollide = false, CastShadow = false,
		})
	end
	local packColors = { Color3.fromRGB(190, 140, 90), Color3.fromRGB(90, 220, 110), Color3.fromRGB(70, 150, 255), Color3.fromRGB(180, 90, 255), Color3.fromRGB(255, 210, 60) }
	for i, color in packColors do
		local box = Style.roundedBox(stand, Vector3.new(2.6, 3.2, 1.8), CFrame.new(-7.5 + (i - 1) * 3.75, 7.7, 0.5) * CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0), color, 0.6)
		box.Parent.Name = "PackBox"
	end
	local board = Style.roundedBox(stand, Vector3.new(19, 4.8, 1), CFrame.new(0, 21, 0), P.Gold, 1.8)
	surfaceText(board, Enum.NormalId.Front, "PACK SHOP", P.White)
	surfaceText(board, Enum.NormalId.Back, "PACK SHOP", P.White)
	for _, piece in board.Parent:GetChildren() do
		Style.float(piece, 0.6, 1.2, 0)
	end
	prompt(counter, "ShopPrompt", "Open Pack Shop", "Seed Packs", 16)
	stand.Parent = root
end

local function buildLostFound(root)
	local model = Instance.new("Model")
	model.Name = "LostFound"
	local booth = Style.roundedBox(model, Vector3.new(10, 5, 6), CFrame.new(-24, 3.2, 14), P.Purple, 1.5)
	Style.roundedBox(model, Vector3.new(11.5, 0.8, 7.5), CFrame.new(-24, 6.1, 14), P.Cream, 1.8)
	Style.studs(model, CFrame.new(-24, 6.5, 14), 4, 2, 2, P.Turquoise)
	billboard(booth, "Sign", "LOST & FOUND", UDim2.fromOffset(300, 60), Vector3.new(0, 6, 0), Color3.fromRGB(225, 210, 255))
	local p = prompt(booth, "LostFoundPrompt", "Recover stolen brainrots", "Lost & Found", 12)
	p.HoldDuration = 0.3
	model.Parent = root
end

local function buildWallOfFame(root)
	local model = Instance.new("Model")
	model.Name = "WallOfFameStand"
	local cf = CFrame.new(0, 14, -16) * CFrame.Angles(0, math.pi, 0) -- front faces the spawn
	Style.roundedBox(model, Vector3.new(36, 20, 0.8), cf * CFrame.new(0, 0, 0.6), P.Gold, 2.5)
	local board = Style.roundedBox(model, Vector3.new(34, 18, 1), cf, Color3.fromRGB(55, 40, 110), 2)
	board.Name = "WallOfFame"
	for _, x in { -12, 12 } do
		Style.cylinder(model, 5, 1.4, cf * CFrame.new(x, -14, 0.6), P.WoodDark)
	end
	for i, x in { -15, 15 } do
		local star = Style.part(model, { Size = Vector3.new(2.6, 2.6, 0.8), CFrame = cf * CFrame.new(x, 11.5, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = P.Gold, Material = Enum.Material.Neon, CanCollide = false })
		Style.float(star, 0.5, 1.6, i)
	end
	model.Parent = root
end

local function buildRoad(root)
	local roadX, roadZ, width = 160, 38, 10
	local roadColor = Color3.fromRGB(150, 140, 215) -- lavender road
	local function segment(size, cf)
		Style.part(root, { Name = "Road", Size = size, CFrame = cf, Color = roadColor })
	end
	segment(Vector3.new(roadX * 2 + width, 0.6, width), CFrame.new(0, 0.5, roadZ))
	segment(Vector3.new(roadX * 2 + width, 0.6, width), CFrame.new(0, 0.5, -roadZ))
	segment(Vector3.new(width, 0.6, roadZ * 2), CFrame.new(roadX, 0.5, 0))
	segment(Vector3.new(width, 0.6, roadZ * 2), CFrame.new(-roadX, 0.5, 0))
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
	for x = -roadX + 10, roadX - 10, 20 do
		for _, z in { roadZ, -roadZ } do
			Style.part(root, { Name = "RoadLine", Size = Vector3.new(8, 0.1, 0.8), CFrame = CFrame.new(x, 0.85, z), Color = P.Gold, CanCollide = false })
		end
	end
	root:SetAttribute("RoadX", roadX)
	root:SetAttribute("RoadZ", roadZ)
	root:SetAttribute("RoadTop", 0.8)
	for x = -140, 140, 40 do
		lamppost(root, Vector3.new(x, 0.5, roadZ - width / 2 - 3))
		lamppost(root, Vector3.new(x, 0.5, -roadZ + width / 2 + 3))
	end
	signpost(root, Vector3.new(100, 0.5, 46), Vector3.new(0, 0, -1), "WILD BRAINROT CROSSING", P.Orange)
	signpost(root, Vector3.new(-100, 0.5, -46), Vector3.new(0, 0, 1), "SLOW: BRAINROTS AHEAD", P.Pink)
end

local PLOT_COLORS = {
	Color3.fromRGB(255, 95, 160), Color3.fromRGB(60, 210, 230), Color3.fromRGB(255, 205, 50), Color3.fromRGB(170, 110, 255),
	Color3.fromRGB(120, 230, 80), Color3.fromRGB(255, 145, 60), Color3.fromRGB(240, 110, 230), Color3.fromRGB(80, 160, 255),
}

local function buildPlot(index, position, parent)
	local cols, rows, T = GameConfig.PlotCols, GameConfig.PlotRows, GameConfig.TileSize
	local width, depth = cols * T + 8, rows * T + 8
	local color = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 0)) -- local -Z faces the plaza

	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	plot.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	Style.roundedBox(plot, Vector3.new(width + 3, 1.2, depth + 3), base * CFrame.new(0, -0.1, 0), color, 3)
	local floor = Style.roundedBox(plot, Vector3.new(width, 1, depth), base * CFrame.new(0, 0.15, 0), P.GrassLight, 2.5)
	floor.Name = "Floor"
	Style.studs(plot, base * CFrame.new(0, 0.5, -(depth / 2 + 0.75)), 10, 1, 1.5, color:Lerp(Color3.new(1, 1, 1), 0.3))

	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local corner = base * CFrame.new(sx * (width / 2 + 0.2), 0.5, sz * (depth / 2 + 0.2))
			Style.cylinder(plot, 3, 1.5, corner, color)
			Style.cylinder(plot, 0.5, 2.2, corner * CFrame.new(0, 3, 0), P.White)
			local orb = Style.ball(plot, 1.8, corner * CFrame.new(0, 4.8, 0), color:Lerp(Color3.new(1, 1, 1), 0.35), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			Style.float(orb, 0.35, 2, index + sx + sz * 0.5)
		end
	end

	for r = 1, rows do
		for c = 1, cols do
			local i = (r - 1) * cols + c
			local x = (c - (cols + 1) / 2) * T
			local z = ((rows + 1) / 2 - r) * T
			Style.part(plot, { Name = "TileRim", Size = Vector3.new(T - 0.6, 0.3, T - 0.6), CFrame = base * CFrame.new(x, 0.75, z), Color = P.DirtDark, CanQuery = false })
			local tile = Style.part(plot, { Name = "Tile" .. i, Size = Vector3.new(T - 1.8, 0.35, T - 1.8), CFrame = base * CFrame.new(x, 0.85, z), Color = P.Dirt, Reflectance = 0 })
			tile:SetAttribute("TileIndex", i)
		end
	end

	local padCFrame = base * CFrame.new(0, 0.6, -depth / 2 - 6)
	Style.cylinder(plot, 0.35, 11, padCFrame * CFrame.new(0, -0.35, 0), P.White)
	local pad = Style.part(plot, {
		Name = "CollectPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 9, 9),
		CFrame = padCFrame * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(90, 255, 120),
		Material = Enum.Material.Neon,
	})
	local coin = Style.part(plot, { Name = "Coin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 3, 3), CFrame = padCFrame * CFrame.new(0, 4.5, 0), Color = P.Gold, Reflectance = 0.15, CanCollide = false, CastShadow = false })
	Style.spin(coin, 90)
	Style.float(coin, 0.4, 2)
	billboard(pad, "Stored", "COLLECT $0", UDim2.fromOffset(250, 50), Vector3.new(0, 7.5, 0), Color3.fromRGB(150, 255, 160))

	local signCFrame = base * CFrame.new(0, 0, depth / 2 + 2.5)
	for _, x in { -6, 6 } do
		Style.cylinder(plot, 6, 0.9, signCFrame * CFrame.new(x, 0.5, 0), P.WoodDark)
	end
	local signPost = Style.roundedBox(plot, Vector3.new(16, 4.5, 1), signCFrame * CFrame.new(0, 6, 0), color, 1.5)
	signPost.Name = "SignPost"
	billboard(signPost, "Owner", "Empty Garden", UDim2.fromOffset(320, 70), Vector3.new(0, 4.5, 0), Color3.new(1, 1, 1))
	local claim = prompt(floor, "ClaimPrompt", "Claim this garden", "Empty Garden", 30)
	claim.HoldDuration = 0.5
	claim.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
	billboard(floor, "ClaimSign", "CLAIM ME!", UDim2.fromOffset(260, 70), Vector3.new(0, 9, 0), P.Gold)

	plot:SetAttribute("Index", index)
	plot:SetAttribute("Owner", 0)
	plot:SetAttribute("OwnerName", "")
	plot:SetAttribute("Spawn", base * CFrame.new(0, 3.5, -depth / 2 - 14) * CFrame.Angles(0, math.pi, 0))
	plot.PrimaryPart = floor
	plot.Parent = parent
end

local function buildPlots(root)
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	local i = 0
	for _, z in { -80, 80 } do
		for _, x in { -120, -40, 40, 120 } do
			i += 1
			if i <= GameConfig.MaxPlots then
				buildPlot(i, Vector3.new(x, 0.5, z), folder)
			end
		end
	end
	folder.Parent = root
end

local function buildScenery(root)
	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = root

	for _ = 1, 26 do
		local pos = Vector3.new(rng:NextNumber(-200, 200), 0.52, rng:NextNumber(-165, 165))
		if math.abs(pos.Z) > 48 or math.abs(pos.X) > 175 then
			Style.cylinder(scenery, 0.05, rng:NextNumber(10, 26), CFrame.new(pos), P.GrassLight, { CanCollide = false, CastShadow = false })
		end
	end

	local leafy = { P.Grass, P.Lime, P.Mint }
	local candy = { P.Bubblegum, Color3.fromRGB(255, 180, 110), P.Lavender, P.Turquoise }
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

	for i = 0, 35 do
		local a = i / 36 * math.pi * 2
		local r = 35.5 + rng:NextNumber(-0.5, 0.5)
		local pos = Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)
		if math.abs(pos.Z) < 31 then
			flower(scenery, pos)
		end
	end

	fence(scenery, Vector3.new(-212, 0.5, -172), Vector3.new(212, 0.5, -172))
	fence(scenery, Vector3.new(-212, 0.5, 172), Vector3.new(212, 0.5, 172))
	fence(scenery, Vector3.new(-212, 0.5, -172), Vector3.new(-212, 0.5, 172))
	fence(scenery, Vector3.new(212, 0.5, -172), Vector3.new(212, 0.5, 172))
	-- balloon bunches between the gardens
	for _, x in { -80, 0, 80 } do
		for _, z in { -60, 60 } do
			for _ = 1, 3 do
				balloon(scenery, Vector3.new(x + rng:NextNumber(-1.5, 1.5), 0.5, z + rng:NextNumber(-1.5, 1.5)), rng:NextNumber(7, 10))
			end
		end
	end

	local hillColors = { P.Grass, P.Lime, P.GrassDark }
	for i = 0, 21 do
		local a = i / 22 * math.pi * 2
		local pos = Vector3.new(math.cos(a) * 250, -8, math.sin(a) * 205)
		Style.ball(scenery, rng:NextNumber(55, 80), CFrame.new(pos), hillColors[i % 3 + 1], { CastShadow = false })
	end

	for _ = 1, 10 do
		cloud(scenery, Vector3.new(rng:NextNumber(-260, 260), rng:NextNumber(90, 130), rng:NextNumber(-200, 200)), rng:NextNumber(0.8, 1.5))
	end

	-- giant golden landmarks in the open lawns either side of the plaza
	statue(scenery, Vector3.new(-75, 0.5, 0), "TungTungTungSahur", "Gold", P.Pink, "TUNG TUNG TUNG")
	statue(scenery, Vector3.new(75, 0.5, 0), "TraleroTralala", "Diamond", P.Turquoise, "TRALALERO")
end

--------------------------------------------------------------------------------

function WorldBuilder.build()
	rng = Random.new(67)
	WorldBuilder.lighting()
	local root = Instance.new("Folder")
	root.Name = ROOT_NAME

	Style.part(root, { Name = "Ground", Size = Vector3.new(440, 1, 360), CFrame = CFrame.new(0, 0, 0), Color = P.Grass })
	buildPlaza(root)
	buildRoad(root)
	buildLostFound(root)
	buildShop(root)
	buildWallOfFame(root)
	buildPlots(root)
	buildScenery(root)

	-- the template baseplate becomes plain grass beyond the map
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = P.GrassDark
		baseplate.Material = Enum.Material.SmoothPlastic
		local texture = baseplate:FindFirstChildOfClass("Texture")
		if texture then
			texture:Destroy()
		end
	end
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
	return root
end

-- Run from Studio's command bar in edit mode (see the top of this file).
function WorldBuilder.bake(force: boolean?)
	local existing = workspace:FindFirstChild(ROOT_NAME)
	if existing and not force then
		warn("[WorldBuilder] The map is already baked. Use .bake(true) to rebuild it (this deletes edits inside " .. ROOT_NAME .. ").")
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local root = WorldBuilder.build()
	print("[WorldBuilder] Map baked into Workspace." .. ROOT_NAME .. ". Save the place (File > Save) to keep it.")
	return root
end

return WorldBuilder
