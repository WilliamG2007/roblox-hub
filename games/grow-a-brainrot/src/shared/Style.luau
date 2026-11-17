-- Visual style: one palette + builders for the game's look.
-- Bubbly rounded plastic shapes, slightly glossy, with real studs used as an
-- accent (corners, ledges, tops) rather than on every surface.

local CollectionService = game:GetService("CollectionService")

local Style = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- bright, toy-like brainrot palette (shared by the world and, via Kit, the UI)
Style.Palette = {
	Grass = rgb(110, 215, 85),
	GrassLight = rgb(150, 235, 105),
	GrassDark = rgb(80, 185, 75),
	Lime = rgb(170, 240, 60),
	Dirt = rgb(160, 102, 64),
	DirtDark = rgb(115, 72, 46),
	Cream = rgb(255, 242, 212),
	CreamDark = rgb(240, 215, 175),
	Path = rgb(255, 230, 185),
	Road = rgb(150, 140, 215),
	Wood = rgb(190, 128, 80),
	WoodDark = rgb(142, 92, 56),
	White = rgb(252, 252, 255),
	Gold = rgb(255, 205, 45),
	Pink = rgb(255, 90, 170),
	Bubblegum = rgb(255, 160, 210),
	Turquoise = rgb(45, 215, 210),
	Sky = rgb(90, 190, 255),
	Purple = rgb(160, 95, 255),
	Lavender = rgb(195, 165, 255),
	Orange = rgb(255, 150, 45),
	Mint = rgb(110, 235, 190),
}

-- glossy plastic (the default look for everything)
function Style.plastic(part: BasePart, gloss: number?)
	part.Material = Enum.Material.SmoothPlastic
	part.Reflectance = gloss or 0.04
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- classic studded brick (use on purpose, not everywhere)
function Style.brick(part: BasePart)
	part.Material = Enum.Material.Plastic
	part.Reflectance = 0
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Inlet
	return part
end

-- Generic anchored part. props.Shape is applied first (it can resize the part).
function Style.part(parent: Instance?, props: { [string]: any })
	local p = Instance.new("Part")
	p.Anchored = true
	Style.plastic(p)
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Shape" then
			p[key] = value
		end
	end
	p.Parent = parent
	return p
end

function Style.ball(parent, diameter: number, cframe: CFrame, color: Color3, props: { [string]: any }?)
	local p = Style.part(parent, { Shape = Enum.PartType.Ball, Size = Vector3.one * diameter, CFrame = cframe, Color = color })
	for key, value in props or {} do
		p[key] = value
	end
	return p
end

-- vertical cylinder standing on `bottom`
function Style.cylinder(parent, height: number, diameter: number, bottom: CFrame, color: Color3, props: { [string]: any }?)
	local p = Style.part(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = bottom * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
	})
	for key, value in props or {} do
		p[key] = value
	end
	return p
end

-- Rounded-corner box: two crossed blocks + four corner cylinders.
-- Returns the main (center) part plus the folder holding all pieces.
function Style.roundedBox(parent, size: Vector3, cframe: CFrame, color: Color3, radius: number?, props: { [string]: any }?)
	local r = math.min(radius or 1.5, size.X / 2, size.Z / 2)
	local model = Instance.new("Model")
	model.Name = (props and props.Name) or "RoundedBox"
	local main = Style.part(model, { Name = "Main", Size = Vector3.new(size.X - r * 2, size.Y, size.Z), CFrame = cframe, Color = color })
	Style.part(model, { Name = "Side", Size = Vector3.new(size.X, size.Y, size.Z - r * 2), CFrame = cframe, Color = color })
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Style.part(model, {
				Name = "Corner",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(size.Y, r * 2, r * 2),
				CFrame = cframe * CFrame.new(x * (size.X / 2 - r), 0, z * (size.Z / 2 - r)) * CFrame.Angles(0, 0, math.pi / 2),
				Color = color,
			})
		end
	end
	for _, p in model:GetChildren() do
		for key, value in props or {} do
			if key ~= "Name" then
				p[key] = value
			end
		end
	end
	model.PrimaryPart = main
	model.Parent = parent
	return main, model
end

-- A small grid of real studs on top of a surface (accent detail).
-- `top` is a CFrame on the surface (Y up); count = studs per side.
function Style.studs(parent, top: CFrame, countX: number, countZ: number, spacing: number, color: Color3)
	local folder = Instance.new("Model")
	folder.Name = "Studs"
	for ix = 1, countX do
		for iz = 1, countZ do
			local x = (ix - (countX + 1) / 2) * spacing
			local z = (iz - (countZ + 1) / 2) * spacing
			Style.cylinder(folder, 0.45, spacing * 0.62, top * CFrame.new(x, 0, z), color, { CanCollide = false, CastShadow = false })
		end
	end
	folder.Parent = parent
	return folder
end

-- Client-side decoration animations (see client DecorController).
-- phase: give every piece of one object the same phase so they bob together
function Style.float(part: BasePart, amplitude: number?, speed: number?, phase: number?)
	part:SetAttribute("FloatAmp", amplitude or 0.6)
	part:SetAttribute("FloatSpeed", speed or 1.5)
	if phase then
		part:SetAttribute("FloatPhase", phase)
	end
	CollectionService:AddTag(part, "Decor")
	return part
end

function Style.spin(part: BasePart, degreesPerSecond: number?)
	part:SetAttribute("SpinSpeed", degreesPerSecond or 45)
	CollectionService:AddTag(part, "Decor")
	return part
end

return Style
