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

-- parts that keep their colors when a mutation recolors the brainrot
local FACE_PARTS = { Eye = true, Pupil = true, Shine = true, Mouth = true, Cheek = true }

local FEET = 0.7

local function part(model, name, shape, size, cframe, color, gloss)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Shape = shape
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	Style.plastic(p, gloss or 0.06)
	p.Parent = model
	return p
end

local function ball(model, name, d, cframe, color, gloss)
	return part(model, name, Enum.PartType.Ball, Vector3.one * d, cframe, color, gloss)
end

-- cylinder along the given axis ("X" | "Y" | "Z")
local function tube(model, name, length, d, cframe, color, axis)
	local rot = if axis == "Y" then CFrame.Angles(0, 0, math.pi / 2) elseif axis == "Z" then CFrame.Angles(0, math.pi / 2, 0) else CFrame.new()
	return part(model, name, Enum.PartType.Cylinder, Vector3.new(length, d, d), cframe * rot, color)
end

-- Body shapes. Each returns: main body part, front z, eye height, top y, width.
local BODIES = {}

function BODIES.tall(model, c)
	local d, h = 2.8, 2.6 -- capsule: tube + two balls
	local y0 = FEET + d / 2
	local body = tube(model, "Body", h, d, CFrame.new(0, y0 + h / 2, 0), c, "Y")
	ball(model, "BodyTop", d, CFrame.new(0, y0 + h, 0), c)
	ball(model, "BodyBottom", d, CFrame.new(0, y0, 0), c)
	return body, -d / 2, y0 + h * 0.8, y0 + h + d / 2, d
end

function BODIES.wide(model, c)
	local d, w = 3, 1.8 -- bean: two balls + tube along X
	local y = FEET + d / 2
	local body = tube(model, "Body", w, d, CFrame.new(0, y, 0), c, "X")
	ball(model, "BodyLeft", d, CFrame.new(-w / 2, y, 0), c)
	ball(model, "BodyRight", d, CFrame.new(w / 2, y, 0), c)
	return body, -d / 2, y + 0.4, y + d / 2, w + d
end

function BODIES.long(model, c)
	local d, l = 2.7, 2.6 -- capsule lying along Z
	local y = FEET + d / 2
	local body = tube(model, "Body", l, d, CFrame.new(0, y, 0), c, "Z")
	ball(model, "BodyFront", d, CFrame.new(0, y, -l / 2), c)
	ball(model, "BodyBack", d, CFrame.new(0, y, l / 2), c)
	return body, -l / 2 - d / 2, y + 0.3, y + d / 2, d
end

function BODIES.blob(model, c)
	local d = 3.8
	local y = FEET + d / 2
	local body = ball(model, "Body", d, CFrame.new(0, y, 0), c)
	return body, -d / 2, y + 0.45, y + d / 2, d
end

-- Accessories in the accent color, different per shape so silhouettes vary.
local ACCESSORIES = {}

function ACCESSORIES.tall(model, a, top)
	ball(model, "Hat", 2.2, CFrame.new(0, top - 0.3, 0), a) -- beanie
	ball(model, "Pompom", 0.9, CFrame.new(0, top + 0.9, 0), Color3.new(1, 1, 1))
	return top + 1.3
end

function ACCESSORIES.wide(model, a, top, width)
	for _, x in { -1, 1 } do
		ball(model, "Ear", 1.2, CFrame.new(x * width * 0.3, top - 0.1, 0.2), a)
	end
	return top + 0.5
end

function ACCESSORIES.long(model, a, top, _, front)
	ball(model, "Tail", 1.1, CFrame.new(0, top - 1, -front + 0.3), a)
	part(model, "Fin", Enum.PartType.Block, Vector3.new(0.3, 1.4, 1.6), CFrame.new(0, top + 0.4, 0.3) * CFrame.Angles(math.rad(-20), 0, 0), a)
	return top + 1.1
end

function ACCESSORIES.blob(model, a, top)
	tube(model, "Antenna", 1.4, 0.25, CFrame.new(0, top + 0.6, 0), a, "Y")
	ball(model, "AntennaBall", 0.8, CFrame.new(0, top + 1.4, 0), a)
	return top + 1.8
end

local function face(model, front, eyeY, width)
	local spread = math.min(width * 0.2, 0.75)
	for i, x in { -spread, spread } do
		local eye = if i == 1 then 1.05 else 1.25 -- slightly mismatched, on purpose
		local z = front + 0.15
		ball(model, "Eye", eye, CFrame.new(x, eyeY, z), Color3.new(1, 1, 1), 0.1)
		ball(model, "Pupil", eye * 0.5, CFrame.new(x + (if i == 1 then 0.08 else -0.08), eyeY - 0.08, z - eye * 0.36), Color3.fromRGB(20, 15, 30), 0.2)
		ball(model, "Shine", eye * 0.18, CFrame.new(x + 0.12, eyeY + 0.12, z - eye * 0.5), Color3.new(1, 1, 1), 0)
		ball(model, "Cheek", 0.55, CFrame.new(x * 1.7, eyeY - 0.7, front + 0.25), Color3.fromRGB(255, 140, 170), 0).Transparency = 0.25
	end
	part(model, "Mouth", Enum.PartType.Block, Vector3.new(0.7, 0.18, 0.15), CFrame.new(0, eyeY - 0.75, front + 0.05), Color3.fromRGB(60, 25, 40))
end

local function placeholder(def)
	local model = Instance.new("Model")
	local shape = if BODIES[def.shape] then def.shape else "blob"
	local main, accent = def.colors[1], def.colors[2]
	local body, front, eyeY, top, width = BODIES[shape](model, main)
	local hatTop = ACCESSORIES[shape](model, accent, top, width, front)
	face(model, front, eyeY, width)
	-- little feet
	for _, x in { -0.65, 0.65 } do
		ball(model, "Foot", 1.1, CFrame.new(x, FEET * 0.55, -0.3), accent:Lerp(Color3.new(0, 0, 0), 0.25))
	end
	-- the brick nod: one stud on top
	tube(model, "Stud", 0.35, 0.7, CFrame.new(0, hatTop, 0), accent:Lerp(Color3.new(1, 1, 1), 0.3), "Y")

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
