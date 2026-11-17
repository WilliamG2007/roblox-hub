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

--------------------------------------------------------------------------------
-- Signature models for the most famous brainrots (hand-built from shapes).
-- Each builds facing -Z with feet at y = 0 and returns its main part.

local function block(model, name, size, cframe, color)
	return part(model, name, Enum.PartType.Block, size, cframe, color)
end

local WHITE = Color3.fromRGB(250, 250, 255)
local DARK = Color3.fromRGB(40, 30, 35)
local SIGNATURES = {}

-- a wooden log with a bat
function SIGNATURES.TungTungTungSahur(model)
	local wood, dark = Color3.fromRGB(205, 155, 100), Color3.fromRGB(140, 95, 55)
	local body = tube(model, "Body", 4.6, 2.5, CFrame.new(0, 3.2, 0), wood, "Y")
	ball(model, "Top", 2.5, CFrame.new(0, 5.5, 0), wood)
	for _, y in { 1.8, 4.2 } do
		tube(model, "Ring", 0.25, 2.62, CFrame.new(0, y, 0), dark, "Y")
	end
	for _, x in { -0.55, 0.55 } do
		tube(model, "Leg", 1.1, 0.5, CFrame.new(x, 0.55, 0), dark, "Y")
		block(model, "Arm", Vector3.new(0.4, 2, 0.4), CFrame.new(x * 3, 3.6, -0.2) * CFrame.Angles(0, 0, math.rad(if x < 0 then 25 else -35)), dark)
	end
	-- the bat
	tube(model, "Bat", 3.6, 0.55, CFrame.new(2.6, 4.6, -0.5) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(160, 110, 60), "Y")
	face(model, -1.25, 4.4, 2.2)
	return body
end

-- a blue shark in three sneakers
function SIGNATURES.TraleroTralala(model)
	local blue, belly = Color3.fromRGB(80, 150, 225), Color3.fromRGB(235, 240, 250)
	local y = 2.6
	local body = tube(model, "Body", 3.4, 2.4, CFrame.new(0, y, 0.3), blue, "Z")
	ball(model, "Head", 2.4, CFrame.new(0, y, -1.4), blue)
	ball(model, "Back", 2, CFrame.new(0, y, 2), blue)
	ball(model, "Belly", 2, CFrame.new(0, y - 0.5, -0.2), belly)
	block(model, "Fin", Vector3.new(0.3, 1.6, 1.4), CFrame.new(0, y + 1.6, 0.3) * CFrame.Angles(math.rad(-25), 0, 0), blue)
	for _, s in { -1, 1 } do
		block(model, "Tail", Vector3.new(0.3, 1.6, 0.8), CFrame.new(0, y + s * 0.7, 3.2) * CFrame.Angles(math.rad(s * 35), 0, 0), blue)
	end
	-- teeth
	for i = -2, 2 do
		block(model, "Tooth", Vector3.new(0.22, 0.25, 0.1), CFrame.new(i * 0.28, y - 0.55, -2.55), WHITE)
	end
	-- three legs in sneakers
	for _, pos in { Vector3.new(-0.7, 0, -0.6), Vector3.new(0.7, 0, -0.6), Vector3.new(0, 0, 1.4) } do
		tube(model, "Leg", 1.4, 0.4, CFrame.new(pos.X, 0.9, pos.Z), blue, "Y")
		block(model, "Sneaker", Vector3.new(0.8, 0.5, 1.3), CFrame.new(pos.X, 0.25, pos.Z - 0.2), WHITE)
		block(model, "Swoosh", Vector3.new(0.82, 0.15, 0.7), CFrame.new(pos.X, 0.3, pos.Z - 0.1) * CFrame.Angles(math.rad(15), 0, 0), Color3.fromRGB(40, 120, 255))
	end
	face(model, -2.45, y + 0.35, 1.8)
	return body
end

-- a crocodile head on a bomber plane
function SIGNATURES.BombardiroCrocodilo(model)
	local green, grey = Color3.fromRGB(80, 150, 70), Color3.fromRGB(160, 165, 175)
	local y = 2.6
	local body = tube(model, "Fuselage", 4, 1.8, CFrame.new(0, y, 1), grey, "Z")
	ball(model, "Head", 2.2, CFrame.new(0, y + 0.2, -1.4), green)
	tube(model, "Snout", 1.8, 1.3, CFrame.new(0, y - 0.1, -2.6), green, "Z")
	for i = -2, 2 do
		block(model, "Tooth", Vector3.new(0.2, 0.25, 0.1), CFrame.new(i * 0.22, y - 0.75, -3.1), WHITE)
	end
	block(model, "Wing", Vector3.new(7, 0.25, 1.6), CFrame.new(0, y, 0.8), grey)
	block(model, "TailFin", Vector3.new(0.25, 1.4, 1), CFrame.new(0, y + 1.1, 2.8), grey)
	block(model, "TailWing", Vector3.new(2.6, 0.2, 0.8), CFrame.new(0, y + 0.3, 2.8), grey)
	for _, x in { -2.2, 2.2 } do
		tube(model, "Bomb", 1.2, 0.5, CFrame.new(x, y - 0.5, 0.8), DARK, "Z")
	end
	for _, x in { -0.6, 0.6 } do
		tube(model, "Strut", 1.2, 0.2, CFrame.new(x, y - 1.4, 0.4), grey, "Y")
		ball(model, "Wheel", 0.8, CFrame.new(x, 0.4, 0.4), DARK)
	end
	face(model, -2.4, y + 0.75, 1.6)
	return body
end

-- a cappuccino cup with a pink tutu
function SIGNATURES.BallerinaCappuccina(model)
	local pink, cream, coffee = Color3.fromRGB(255, 160, 205), WHITE, Color3.fromRGB(150, 100, 65)
	for _, s in { -1, 1 } do
		tube(model, "Leg", 2.4, 0.35, CFrame.new(s * 0.35, 1.2, 0) * CFrame.Angles(0, 0, math.rad(s * 8)), Color3.fromRGB(255, 220, 200), "Y")
		ball(model, "Shoe", 0.5, CFrame.new(s * 0.5, 0.2, -0.1), pink)
	end
	tube(model, "Tutu", 0.6, 3.6, CFrame.new(0, 2.5, 0), pink, "Y")
	local body = tube(model, "Cup", 2.2, 2.2, CFrame.new(0, 3.9, 0), cream, "Y")
	tube(model, "Coffee", 0.15, 2, CFrame.new(0, 5.02, 0), coffee, "Y")
	ball(model, "Foam", 0.9, CFrame.new(0.2, 5.1, 0.1), cream)
	block(model, "Handle", Vector3.new(0.35, 1.1, 0.35), CFrame.new(1.35, 3.9, 0), cream)
	for _, s in { -1, 1 } do
		block(model, "Arm", Vector3.new(0.3, 1.8, 0.3), CFrame.new(s * 1.3, 5.3, 0) * CFrame.Angles(0, 0, math.rad(s * -30)), Color3.fromRGB(255, 220, 200))
	end
	face(model, -1.1, 4.1, 1.8)
	return body
end

-- a cactus elephant in sandals
function SIGNATURES.LiriliLarila(model)
	local cactus, grey = Color3.fromRGB(110, 185, 85), Color3.fromRGB(165, 165, 180)
	for _, s in { -1, 1 } do
		block(model, "Sandal", Vector3.new(0.9, 0.25, 1.4), CFrame.new(s * 0.6, 0.12, -0.1), Color3.fromRGB(150, 100, 60))
	end
	local body = tube(model, "Body", 2.6, 2.2, CFrame.new(0, 2, 0), cactus, "Y")
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		block(model, "Spike", Vector3.new(0.12, 0.5, 0.12), CFrame.new(math.cos(a) * 1.15, 1.4 + (i % 2) * 1.1, math.sin(a) * 1.15) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(250, 245, 200))
	end
	ball(model, "Head", 2.6, CFrame.new(0, 4.2, 0), grey)
	for _, s in { -1, 1 } do
		ball(model, "Ear", 1.6, CFrame.new(s * 1.3, 4.4, 0.3), grey:Lerp(Color3.fromRGB(255, 170, 190), 0.3))
	end
	tube(model, "Trunk", 1.6, 0.55, CFrame.new(0, 3.5, -1.4) * CFrame.Angles(math.rad(25), 0, 0), grey, "Y")
	face(model, -1.25, 4.6, 2)
	return body
end

-- a banana with a chimp inside
function SIGNATURES.ChimpanziniBananini(model)
	local yellow, brown, skin = Color3.fromRGB(255, 225, 60), Color3.fromRGB(115, 75, 45), Color3.fromRGB(230, 190, 150)
	local body = tube(model, "Peel", 2.4, 2.2, CFrame.new(0, 1.6, 0), yellow, "Y")
	for _, s in { -1, 1 } do
		block(model, "PeelFlap", Vector3.new(0.3, 1.8, 1.2), CFrame.new(s * 1.1, 3.1, 0) * CFrame.Angles(0, 0, math.rad(s * -30)), yellow)
	end
	ball(model, "Head", 2.3, CFrame.new(0, 3.8, 0), brown)
	ball(model, "Muzzle", 1.5, CFrame.new(0, 3.5, -0.75), skin)
	for _, s in { -1, 1 } do
		ball(model, "Ear", 0.8, CFrame.new(s * 1.15, 4, 0), skin)
	end
	face(model, -1.05, 4.15, 1.8)
	return body
end

-- a coffee cup ninja with katanas
function SIGNATURES.CappuccinoAssassino(model)
	local cup, coffee = Color3.fromRGB(150, 100, 65), Color3.fromRGB(90, 55, 35)
	for _, s in { -1, 1 } do
		tube(model, "Leg", 1, 0.4, CFrame.new(s * 0.5, 0.5, 0), DARK, "Y")
	end
	local body = tube(model, "Cup", 2.6, 2.4, CFrame.new(0, 2.3, 0), cup, "Y")
	tube(model, "Coffee", 0.15, 2.2, CFrame.new(0, 3.65, 0), coffee, "Y")
	tube(model, "Mask", 0.55, 2.5, CFrame.new(0, 2.85, 0), DARK, "Y")
	for _, s in { -1, 1 } do
		block(model, "Katana", Vector3.new(0.18, 3.6, 0.35), CFrame.new(s * 0.5, 3.2, 1.3) * CFrame.Angles(0, 0, math.rad(s * 30)), Color3.fromRGB(215, 220, 230))
	end
	face(model, -1.22, 2.85, 2)
	return body
end

-- a tiny walking "67"
function SIGNATURES.Lil67(model)
	local blue = Color3.fromRGB(60, 150, 255)
	local t = 0.7
	local function seg(x, y, w, h)
		return block(model, "Digit", Vector3.new(w, h, t), CFrame.new(x, y, 0), blue)
	end
	local base = 1.2
	seg(-1.9, base + 2, t, 4)
	seg(-1.2, base + 3.65, 2, t)
	seg(-1.2, base + 2, 2, t)
	seg(-1.2, base + 0.35, 2, t)
	seg(-0.55, base + 1.2, t, 1.7)
	local body = seg(1.2, base + 3.65, 2, t)
	block(model, "Digit", Vector3.new(t, 3.7, t), CFrame.new(1.3, base + 1.8, 0) * CFrame.Angles(0, 0, math.rad(-18)), blue)
	for _, x in { -1.2, 1.2 } do
		block(model, "Eye", Vector3.new(0.6, 0.6, 0.2), CFrame.new(x, base + 2.9, -0.45), Color3.fromRGB(255, 40, 40)).Material = Enum.Material.Neon
		tube(model, "Leg", base, 0.35, CFrame.new(x, base / 2, 0), blue, "Y")
		ball(model, "Foot", 0.7, CFrame.new(x, 0.3, -0.2), WHITE)
	end
	return body
end

-- a strawberry with an elephant trunk
function SIGNATURES.StrawberryElephant(model)
	local red, leaf, grey = Color3.fromRGB(235, 55, 75), Color3.fromRGB(90, 190, 80), Color3.fromRGB(170, 165, 185)
	for _, x in { -0.8, 0.8 } do
		tube(model, "Leg", 1, 0.8, CFrame.new(x, 0.5, 0), grey, "Y")
	end
	local body = ball(model, "Berry", 3.6, CFrame.new(0, 2.7, 0), red)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		ball(model, "Seed", 0.25, CFrame.new(math.cos(a) * 1.75, 2.4 + (i % 3) * 0.5, math.sin(a) * 1.75), Color3.fromRGB(255, 230, 120), 0)
	end
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		block(model, "Leaf", Vector3.new(0.3, 0.2, 1.4), CFrame.new(math.cos(a) * 0.6, 4.5, math.sin(a) * 0.6) * CFrame.Angles(0, -a, math.rad(20)), leaf)
	end
	for _, s in { -1, 1 } do
		ball(model, "Ear", 1.5, CFrame.new(s * 1.7, 3.2, 0.2), grey)
	end
	tube(model, "Trunk", 1.8, 0.6, CFrame.new(0, 1.9, -1.9) * CFrame.Angles(math.rad(20), 0, 0), grey, "Y")
	face(model, -1.65, 3.2, 2.6)
	return body
end

-- a tree with a monkey face and huge feet
function SIGNATURES.BrrBrrPatapim(model)
	local bark, leaf, skin = Color3.fromRGB(130, 95, 60), Color3.fromRGB(90, 175, 70), Color3.fromRGB(225, 185, 145)
	for _, s in { -1, 1 } do
		block(model, "Foot", Vector3.new(1.3, 0.5, 2), CFrame.new(s * 0.8, 0.25, -0.3), skin)
		tube(model, "Leg", 1.6, 0.7, CFrame.new(s * 0.6, 1.2, 0), bark, "Y")
	end
	local body = tube(model, "Trunk", 1.6, 1.8, CFrame.new(0, 2.6, 0), bark, "Y")
	ball(model, "Leaves", 3.6, CFrame.new(0, 4.6, 0.2), leaf)
	ball(model, "Leaves2", 2.4, CFrame.new(1.2, 5.4, 0.4), leaf:Lerp(Color3.new(1, 1, 1), 0.1))
	ball(model, "FacePatch", 2, CFrame.new(0, 4.3, -1.1), skin)
	ball(model, "Nose", 0.8, CFrame.new(0, 4, -2), skin:Lerp(Color3.new(0, 0, 0), 0.15))
	face(model, -2.05, 4.55, 1.6)
	return body
end

local function signatureModel(def)
	local signature = SIGNATURES[def.id]
	if not signature then
		return nil
	end
	local model = Instance.new("Model")
	local main = signature(model)
	model.PrimaryPart = main
	model.WorldPivot = CFrame.new(0, 0, 0)
	return model
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
	local model = if art then art:Clone() else (signatureModel(def) or placeholder(def))
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
