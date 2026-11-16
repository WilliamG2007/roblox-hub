-- Builds the 3D model for a brainrot.
-- If ReplicatedStorage.Assets.Brainrots.<id> exists (real art), that is cloned.
-- Otherwise a chunky placeholder is generated from the roster colors/shape.
-- Models are built facing -Z with their pivot at the bottom center.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brainrots = require(script.Parent.Config.Brainrots)

local BrainrotModels = {}

local SHAPES = {
	tall = Vector3.new(3, 4.5, 3),
	wide = Vector3.new(4.6, 2.8, 3.6),
	long = Vector3.new(3, 3, 5),
	blob = Vector3.new(3.8, 3.8, 3.8),
}

local function part(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
		props.Shape = nil
	end
	for key, value in props do
		p[key] = value
	end
	p.Parent = model
	return p
end

local function placeholder(def)
	local model = Instance.new("Model")
	local size = SHAPES[def.shape] or SHAPES.blob
	local feet = 0.8
	local bodyShape = if def.shape == "blob" then Enum.PartType.Ball else Enum.PartType.Block
	local body = part(model, {
		Name = "Body",
		Shape = bodyShape,
		Size = if bodyShape == Enum.PartType.Ball then Vector3.one * size.X else size,
		CFrame = CFrame.new(0, feet + size.Y / 2, 0),
		Color = def.colors[1],
	})
	local top = feet + size.Y

	-- accent "hat" stripe
	part(model, {
		Name = "Accent",
		Size = Vector3.new(size.X * 0.7, 0.7, size.Z * 0.7),
		CFrame = CFrame.new(0, top + 0.2, 0),
		Color = def.colors[2],
	})

	-- feet
	for _, x in { -size.X * 0.25, size.X * 0.25 } do
		part(model, {
			Name = "Foot",
			Size = Vector3.new(0.9, feet, 1.2),
			CFrame = CFrame.new(x, feet / 2, -0.2),
			Color = def.colors[2]:Lerp(Color3.new(0, 0, 0), 0.3),
		})
	end

	-- googly eyes on the front (-Z)
	local front = -size.Z / 2
	local eyeY = feet + size.Y * 0.68
	for i, x in { -size.X * 0.2, size.X * 0.2 } do
		local eyeSize = if i == 1 then 1.1 else 1.3 -- slightly mismatched, on purpose
		part(model, {
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * eyeSize,
			CFrame = CFrame.new(x, eyeY, front - 0.15),
			Color = Color3.new(1, 1, 1),
		})
		part(model, {
			Name = "Pupil",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * eyeSize * 0.45,
			CFrame = CFrame.new(x + (if i == 1 then 0.1 else -0.1), eyeY - 0.1, front - 0.15 - eyeSize * 0.4),
			Color = Color3.new(0, 0, 0),
		})
	end

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new(0, 0, 0)
	return model
end

local function customArt(id)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Brainrots")
	return folder and folder:FindFirstChild(id)
end

function BrainrotModels.build(id: string, scale: number?): Model
	local def = Brainrots.byId[id]
	assert(def, "unknown brainrot " .. tostring(id))
	local art = customArt(id)
	local model = if art then art:Clone() else placeholder(def)
	model.Name = id
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Anchored = true
			inst.CanCollide = false
		end
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	return model
end

return BrainrotModels
