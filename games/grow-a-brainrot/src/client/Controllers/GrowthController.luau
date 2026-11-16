-- Draws growing plants on every tile (client-only): a sprout that becomes a
-- wiggling pod, plus a progress bar. Driven entirely by tile attributes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Format = require(Shared.Format)
local Kit = require(script.Parent.Parent.UI.Kit)

local GrowthController = {}

local sprouts = {} -- [tilePart] = { model, stem, pod, bar, fill, label, plantedAt, growTime }
local folder

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
		props.Shape = nil
	end
	for key, value in props do
		p[key] = value
	end
	return p
end

local function removeSprout(tile)
	local sprout = sprouts[tile]
	if sprout then
		sprout.model:Destroy()
		sprouts[tile] = nil
	end
end

local function addSprout(tile)
	removeSprout(tile)
	local def = Brainrots.byId[tile:GetAttribute("PlantId")]
	if not def then
		return
	end
	local rarity = Rarities.byName[def.rarity]
	local model = Instance.new("Model")
	model.Name = "Sprout"
	local top = tile.CFrame * CFrame.new(0, tile.Size.Y / 2, 0)
	local mound = part({ Name = "Mound", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = top * CFrame.new(0, -0.6, 0), Color = Color3.fromRGB(95, 60, 35) })
	mound.Parent = model
	local stem = part({ Name = "Stem", Size = Vector3.new(0.4, 1, 0.4), Color = Color3.fromRGB(80, 200, 70) })
	stem.Parent = model
	local pod = part({ Name = "Pod", Shape = Enum.PartType.Ball, Size = Vector3.one, Color = def.colors[1], Material = Enum.Material.SmoothPlastic })
	pod.Parent = model

	local bar = Kit.new("BillboardGui", { Size = UDim2.fromOffset(120, 34), StudsOffsetWorldSpace = Vector3.new(0, 6, 0), MaxDistance = 90, LightInfluence = 0, Adornee = mound, Parent = model })
	local back = Kit.new("Frame", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Color3.fromRGB(30, 30, 40), Parent = bar })
	Kit.corner(back, 7)
	local fill = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = rarity.color, Parent = back })
	Kit.corner(fill, 7)
	local label = Kit.label({ Size = UDim2.new(1, 0, 0, 18), Text = "", TextScaled = true, TextStrokeTransparency = 0, Parent = bar })

	model.Parent = folder
	sprouts[tile] = {
		model = model,
		stem = stem,
		pod = pod,
		fill = fill,
		label = label,
		top = top,
		plantedAt = tile:GetAttribute("PlantedAt"),
		growTime = tile:GetAttribute("GrowTime"),
	}
end

local function watchTile(tile)
	local function update()
		if tile:GetAttribute("State") == "growing" then
			addSprout(tile)
		else
			removeSprout(tile)
		end
	end
	tile:GetAttributeChangedSignal("State"):Connect(update)
	tile:GetAttributeChangedSignal("PlantedAt"):Connect(update)
	update()
end

function GrowthController.start()
	folder = Instance.new("Folder")
	folder.Name = "Sprouts"
	folder.Parent = workspace

	local world = workspace:WaitForChild("GrowABrainrotWorld")
	local plots = world:WaitForChild("Plots")
	local function watchPlot(plot)
		for _, child in plot:GetChildren() do
			if child:GetAttribute("TileIndex") then
				watchTile(child)
			end
		end
	end
	for _, plot in plots:GetChildren() do
		watchPlot(plot)
	end
	plots.ChildAdded:Connect(function(plot)
		task.wait() -- let its tiles replicate
		watchPlot(plot)
	end)

	local textTimer = 0
	RunService.RenderStepped:Connect(function(dt)
		local now = workspace:GetServerTimeNow()
		local t = os.clock()
		textTimer += dt
		local updateText = textTimer > 0.2
		if updateText then
			textTimer = 0
		end
		for _, s in sprouts do
			local progress = math.clamp((now - s.plantedAt) / s.growTime, 0, 1)
			local height = 0.6 + progress * 2.4
			s.stem.Size = Vector3.new(0.4, height, 0.4)
			s.stem.CFrame = s.top * CFrame.new(0, height / 2, 0)
			-- pod grows and wiggles harder as it gets close to popping
			local podSize = 0.6 + progress * 2.2
			local wiggle = if progress > 0.75 then math.sin(t * (10 + progress * 20)) * 0.25 * progress else math.sin(t * 2) * 0.05
			s.pod.Size = Vector3.one * podSize
			s.pod.CFrame = s.top * CFrame.new(0, height + podSize / 2 - 0.2, 0) * CFrame.Angles(0, 0, wiggle)
			s.fill.Size = UDim2.fromScale(progress, 1)
			if updateText then
				local left = s.plantedAt + s.growTime - now
				s.label.Text = if left > 0 then string.format("%d%%  ·  %s", math.floor(progress * 100), Format.time(left)) else "POP!"
			end
		end
	end)
end

return GrowthController
