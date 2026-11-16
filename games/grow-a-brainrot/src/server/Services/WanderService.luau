-- Wild brainrots: every few minutes a rare (often mutated) brainrot walks one
-- lap of the road around the plaza. Everyone is alerted; the first player to
-- reach it and buy it gets its seed. Some are FREE: pure race.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local BrainrotModels = require(Shared.BrainrotModels)
local Odds = require(Shared.Odds)
local Seeds = require(Shared.Seeds)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local WanderService = {}

local config = GameConfig.Wanderers
local services
local fx
local rng = Random.new()
local active = {}

local function label(parent, name, text, color, height)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = UDim2.new(1, 0, 0, height)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0
	l.Parent = parent
	return l
end

local function rollWanderer(free: boolean)
	local luck = services.LuckService.getLuck()
	local rarity = Odds.pick(Odds.rarities({ rarities = if free then config.freeRarities else config.rarities }, luck), rng).rarity
	local id = Odds.pick(Odds.brainrots(rarity), rng).id
	local mutation = Odds.pick(Odds.mutations(config.mutationLuck * services.LuckService.getMutationLuck()), rng).id
	return id, mutation
end

function WanderService.spawn(id: string?, mutationId: string?, free: boolean?)
	if free == nil then
		free = rng:NextNumber() < config.FreeChance
	end
	if not id then
		id, mutationId = rollWanderer(free)
	end
	mutationId = mutationId or "Normal"
	local def = Brainrots.byId[id]
	local mutation = Mutations.byId[mutationId]
	local rarity = Rarities.byName[def.rarity]
	local color = if mutationId ~= "Normal" then mutation.color else rarity.color
	local price = if free then 0 else math.floor(def.income * mutation.mult * config.PriceIncomeSeconds)
	local fullName = (if mutationId ~= "Normal" then string.upper(mutation.name) .. " " else "") .. def.name

	local model = BrainrotModels.build(id, config.Scale, mutationId)
	model.Name = "WildBrainrot"
	local root = model.PrimaryPart
	local height = model:GetExtentsSize().Y

	-- find-me beam + glow
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.6
	beam.Size = Vector3.new(80, 2, 2)
	beam.Parent = model
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 3
	light.Parent = root

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 96)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 2, 0)
	gui.MaxDistance = 300
	gui.LightInfluence = 0
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui
	label(gui, "Tag", if free then "FREE! FIRST TO GRAB!" else "WILD BRAINROT", if free then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 220, 80), 26)
	label(gui, "Name", fullName, color, 34)
	label(gui, "Price", if free then string.upper(def.rarity) else Format.cash(price) .. "  ·  " .. string.upper(def.rarity), Color3.new(1, 1, 1), 26)
	gui.Parent = root

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = if free then "Grab it!" else "Buy " .. Format.cash(price)
	prompt.ObjectText = fullName
	prompt.HoldDuration = if free then 1.2 else 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	local wanderer = { model = model, claimed = false }
	table.insert(active, wanderer)

	local function finish()
		local i = table.find(active, wanderer)
		if i then
			table.remove(active, i)
		end
		if model.Parent then
			fx:FireAllClients("Burst", root.Position, color)
			model:Destroy()
		end
	end

	prompt.Triggered:Connect(function(player)
		if wanderer.claimed then
			return
		end
		local data = services.DataService.get(player)
		if not data then
			return
		end
		if price > 0 and not services.EconomyService.spend(player, price) then
			fx:FireClient(player, "Toast", "You need " .. Format.cash(price) .. " to catch this one!", Color3.fromRGB(255, 120, 120))
			return
		end
		wanderer.claimed = true
		local key = Seeds.key(id, mutationId)
		data.seeds[key] = (data.seeds[key] or 0) + 1
		services.SyncService.mark(player)
		fx:FireClient(player, "Toast", "You caught " .. fullName .. "! Its seed is in your hotbar.", color)
		services.FameService.record(string.format("%s caught the wild %s!", player.DisplayName, fullName), color)
		finish()
	end)

	-- walk one lap of the road, starting at a random corner
	local waypoints = services.MapService.RoadWaypoints
	local start = rng:NextInteger(1, #waypoints)
	local route = {}
	for i = 0, #waypoints do
		table.insert(route, waypoints[(start + i - 1) % #waypoints + 1])
	end
	model:PivotTo(CFrame.new(route[1]))
	model.Parent = services.MapService.Root

	fx:FireAllClients("Announce", string.format("A wild %s%s is walking the road!%s", fullName, if free then " (FREE)" else "", if free then " RUN!" else ""), color)

	task.spawn(function()
		local t0 = os.clock()
		for leg = 1, #route - 1 do
			local a, b = route[leg], route[leg + 1]
			local distance = (b - a).Magnitude
			local travelled = 0
			while travelled < distance do
				if wanderer.claimed or not model.Parent then
					return
				end
				travelled += RunService.Heartbeat:Wait() * config.Speed
				local pos = a:Lerp(b, math.min(travelled / distance, 1))
				local bob = math.abs(math.sin((os.clock() - t0) * 6)) * 0.8
				local cf = CFrame.lookAt(pos, pos + (b - a)) * CFrame.new(0, bob, 0)
				model:PivotTo(cf)
				beam.CFrame = CFrame.new(pos + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			end
		end
		if not wanderer.claimed then
			fx:FireAllClients("Toast", "The wild " .. fullName .. " wandered off...", Color3.fromRGB(200, 200, 200))
			finish()
		end
	end)
end

function WanderService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function WanderService.start()
	task.spawn(function()
		while true do
			task.wait(rng:NextInteger(config.MinInterval, config.MaxInterval))
			if #active < config.MaxActive and #Players:GetPlayers() > 0 then
				WanderService.spawn()
			end
		end
	end)
end

return WanderService
