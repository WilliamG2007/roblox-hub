-- Builds the 3D model for a brainrot (optionally mutated).
-- If ReplicatedStorage.Assets.Brainrots.<id> exists (real art), that is cloned.
-- Otherwise a chunky brick-style placeholder is generated from the roster colors/shape.
-- Models face -Z with their pivot at the bottom center.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brainrots = require(script.Parent.Config.Brainrots)
local Mutations = require(script.Parent.Config.Mutations)
local Style = require(script.Parent.Style)

local BrainrotModels = {}

local SHAPES = {
	tall = Vector3.new(3, 4.5, 3),
	wide = Vector3.new(4.6, 2.8, 3.6),
	long = Vector3.new(3, 3, 5),
	blob = Vector3.new(3.8, 3.8, 3.8),
}

local FACE_PARTS = { Eye = true, Pupil = true }

local function part(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	if props.Shape then
		p.Shape = props.Shape
		props.Shape = nil
	end
	for key, value in props do
		p[key] = value
	end
	Style.brick(p)
	p.Parent = model
	return p
end

local function placeholder(def)
	local model = Instance.new("Model")
	local size = SHAPES[def.shape] or SHAPES.blob
	local feet = 0.8
	local body = part(model, {
		Name = "Body",
		Size = size,
		CFrame = CFrame.new(0, feet + size.Y / 2, 0),
		Color = def.colors[1],
	})
	local top = feet + size.Y

	part(model, {
		Name = "Accent",
		Size = Vector3.new(size.X * 0.7, 0.8, size.Z * 0.7),
		CFrame = CFrame.new(0, top + 0.4, 0),
		Color = def.colors[2],
	})
	for _, x in { -size.X * 0.25, size.X * 0.25 } do
		part(model, {
			Name = "Foot",
			Size = Vector3.new(1, feet, 1.2),
			CFrame = CFrame.new(x, feet / 2, -0.2),
			Color = def.colors[2]:Lerp(Color3.new(0, 0, 0), 0.3),
		})
	end

	-- googly eyes on the front (-Z), slightly mismatched on purpose
	local front = -size.Z / 2
	local eyeY = feet + size.Y * 0.68
	for i, x in { -size.X * 0.2, size.X * 0.2 } do
		local eyeSize = if i == 1 then 1.1 else 1.3
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

local function applyMutation(model, mutationId)
	local mutation = Mutations.byId[mutationId]
	if not mutation or mutationId == "Normal" then
		return
	end
	model:SetAttribute("Mutation", mutationId)
	local i = 0
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and not FACE_PARTS[p.Name] then
			i += 1
			if mutationId == "Gold" then
				p.Color = Color3.fromRGB(255, 200, 40)
				p.Material = Enum.Material.Foil
			elseif mutationId == "Diamond" then
				p.Color = Color3.fromRGB(160, 230, 255)
				p.Material = Enum.Material.Ice
			elseif mutationId == "Galaxy" then
				p.Color = if i % 2 == 0 then Color3.fromRGB(70, 30, 140) else Color3.fromRGB(120, 60, 220)
				p.Material = Enum.Material.Neon
			elseif mutationId == "Moonlit" then
				p.Color = Color3.fromRGB(150, 175, 255)
				p.Material = Enum.Material.Glass
			elseif mutationId == "SixtySeven" then
				p.Color = if i % 2 == 0 then Color3.fromRGB(255, 60, 60) else Color3.fromRGB(60, 150, 255)
			end
		end
	end
	if mutationId == "Rainbow" then
		CollectionService:AddTag(model, "RainbowMutation") -- client animates the colors
	end
	local root = model.PrimaryPart
	if root then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "MutationSparkles"
		sparkles.Color = ColorSequence.new(mutation.color)
		sparkles.LightEmission = 1
		sparkles.Rate = 3 + mutation.order * 2
		sparkles.Lifetime = NumberRange.new(0.8, 1.6)
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.35, 0)
		sparkles.Parent = root
	end
end

function BrainrotModels.build(id: string, scale: number?, mutation: string?): Model
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
	applyMutation(model, mutation)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	return model
end

return BrainrotModels
