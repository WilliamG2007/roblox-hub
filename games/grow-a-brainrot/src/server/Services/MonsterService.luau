-- Night monsters.
--   Grumblers walk in from the map edge toward a grown brainrot, grab it and
--   run back to the edge. Catch them before they escape and the brainrot goes
--   home; if they escape it goes to the Lost & Found. No brainrots around? They
--   nibble growing plants (slower growth) instead.
--   On boss nights THE 67 stomps in: huge HP, knockback stomps, big rewards.
-- Defense: grown brainrots zap monsters in range automatically; players bonk
-- them with the Giant Spoon. Kills drop Moon Shards. At dawn every monster
-- flees and drops whatever it was carrying (losing stays mild).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Seeds = require(Shared.Seeds)
local Style = require(Shared.Style)
local Remotes = require(Shared.Remotes)

local MonsterService = {}

local NIGHT = GameConfig.Night
local GRUMBLER = GameConfig.Grumbler
local BOSS = GameConfig.Boss67
local SPOON = GameConfig.Spoon
local EDGE_X, EDGE_Z = 195, 155

local services
local fx
local rng = Random.new()
local monsters = {}
local folder

--------------------------------------------------------------------------------
-- Models

local function brick(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	for key, value in props do
		p[key] = value
	end
	Style.brick(p)
	p.Parent = model
	return p
end

local function hpBar(model, root, title, width, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Hp"
	gui.Size = UDim2.fromOffset(width, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.MaxDistance = 250
	gui.LightInfluence = 0
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 22)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.Text = title
	name.TextColor3 = color
	name.TextStrokeTransparency = 0
	name.Parent = gui
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(0, 26)
	back.Size = UDim2.new(1, 0, 0, 14)
	back.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
	back.BorderSizePixel = 0
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
	fill.BorderSizePixel = 0
	fill.Parent = back
	gui.Parent = root
	return fill
end

local function buildGrumbler()
	local model = Instance.new("Model")
	model.Name = "Grumbler"
	local purple, green = Color3.fromRGB(110, 60, 160), Color3.fromRGB(120, 200, 80)
	for _, x in { -0.7, 0.7 } do
		brick(model, { Name = "Leg", Size = Vector3.new(1, 1.6, 1), CFrame = CFrame.new(x, 0.8, 0), Color = purple:Lerp(Color3.new(0, 0, 0), 0.3) })
		brick(model, { Name = "Arm", Size = Vector3.new(0.8, 2.4, 0.8), CFrame = CFrame.new(x * 2.6, 3, -0.3) * CFrame.Angles(math.rad(-30), 0, 0), Color = green })
	end
	local body = brick(model, { Name = "Body", Size = Vector3.new(3, 2.6, 2.2), CFrame = CFrame.new(0, 2.9, 0), Color = purple })
	brick(model, { Name = "Head", Size = Vector3.new(2.6, 2.2, 2.2), CFrame = CFrame.new(0, 5.3, 0), Color = green })
	for _, x in { -0.55, 0.55 } do
		local eye = brick(model, { Name = "Eye", Size = Vector3.new(0.5, 0.5, 0.2), CFrame = CFrame.new(x, 5.5, -1.15), Color = Color3.fromRGB(255, 40, 40) })
		eye.Material = Enum.Material.Neon
	end
	brick(model, { Name = "Mouth", Size = Vector3.new(1.4, 0.3, 0.2), CFrame = CFrame.new(0, 4.8, -1.15), Color = Color3.fromRGB(30, 20, 30) })
	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()
	return model
end

-- a giant blocky "67" with arms, legs and angry red eyes
local function build67()
	local model = Instance.new("Model")
	model.Name = "The67"
	local blue = Color3.fromRGB(60, 150, 255)
	local t = 3 -- stroke thickness
	local function seg(x, y, w, h, angle)
		return brick(model, { Name = "Digit", Size = Vector3.new(w, h, t), CFrame = CFrame.new(x, y, 0) * CFrame.Angles(0, 0, angle or 0), Color = blue })
	end
	local base = 8 -- legs height
	-- "6" (left)
	local x6 = -6
	seg(x6 - 4, base + 9, t, 18) -- left vertical
	seg(x6, base + 16.5, 11, t) -- top
	seg(x6, base + 9, 11, t) -- middle
	seg(x6, base + 1.5, 11, t) -- bottom
	seg(x6 + 4, base + 5.25, t, 7.5) -- right lower
	-- "7" (right)
	local x7 = 7
	seg(x7, base + 16.5, 11, t) -- top
	local core = seg(x7 + 0.5, base + 8, t, 16.5, math.rad(-18)) -- diagonal
	-- eyes
	for _, x in { x6, x7 } do
		local eye = brick(model, { Name = "Eye", Size = Vector3.new(3, 3, 1), CFrame = CFrame.new(x, base + 13, -t / 2 - 0.4), Color = Color3.fromRGB(255, 30, 30) })
		eye.Material = Enum.Material.Neon
	end
	-- arms with big white gloves
	for _, side in { -1, 1 } do
		brick(model, { Name = "Arm", Size = Vector3.new(7, 1.5, 1.5), CFrame = CFrame.new(side * 15, base + 10, 0) * CFrame.Angles(0, 0, side * math.rad(25)), Color = blue })
		brick(model, { Name = "Glove", Size = Vector3.new(3.5, 3.5, 3.5), CFrame = CFrame.new(side * 19, base + 12, -1), Color = Color3.fromRGB(240, 240, 245) })
		brick(model, { Name = "Leg", Size = Vector3.new(2, base, 2), CFrame = CFrame.new(side * 6, base / 2, 0), Color = blue })
		brick(model, { Name = "Foot", Size = Vector3.new(3, 1.5, 5), CFrame = CFrame.new(side * 6, 0.75, -1), Color = Color3.fromRGB(240, 240, 245) })
	end
	model.PrimaryPart = core
	model.WorldPivot = CFrame.new()
	return model
end

--------------------------------------------------------------------------------
-- Helpers

local function edgePoint()
	local side = rng:NextInteger(1, 4)
	if side == 1 then
		return Vector3.new(rng:NextNumber(-EDGE_X, EDGE_X), 0.5, EDGE_Z)
	elseif side == 2 then
		return Vector3.new(rng:NextNumber(-EDGE_X, EDGE_X), 0.5, -EDGE_Z)
	elseif side == 3 then
		return Vector3.new(EDGE_X, 0.5, rng:NextNumber(-EDGE_Z, EDGE_Z))
	end
	return Vector3.new(-EDGE_X, 0.5, rng:NextNumber(-EDGE_Z, EDGE_Z))
end

local function nearestEdge(pos: Vector3)
	local options = {
		Vector3.new(pos.X, 0.5, EDGE_Z), Vector3.new(pos.X, 0.5, -EDGE_Z),
		Vector3.new(EDGE_X, 0.5, pos.Z), Vector3.new(-EDGE_X, 0.5, pos.Z),
	}
	local best, bestDist = options[1], math.huge
	for _, option in options do
		local d = (option - pos).Magnitude
		if d < bestDist then
			best, bestDist = option, d
		end
	end
	return best
end

local function flat(v: Vector3)
	return Vector3.new(v.X, 0, v.Z)
end

local function pickTarget(monster)
	local brainrots = services.GardenService.getBrainrots()
	-- don't pile every monster onto the same brainrot
	local claimed = {}
	for _, other in monsters do
		if other ~= monster and other.target and other.target.kind == "brainrot" then
			claimed[other.target.player.UserId .. ":" .. other.target.index] = true
		end
	end
	local free = {}
	for _, b in brainrots do
		if not claimed[b.player.UserId .. ":" .. b.index] then
			table.insert(free, b)
		end
	end
	local pool = if #free > 0 then free else brainrots
	if #pool > 0 then
		local b = pool[rng:NextInteger(1, #pool)]
		return { kind = "brainrot", player = b.player, index = b.index, position = b.position }
	end
	local growing = services.GardenService.getGrowing()
	if #growing > 0 then
		local g = growing[rng:NextInteger(1, #growing)]
		return { kind = "growing", player = g.player, index = g.index, position = g.position }
	end
	-- nothing to bother: wander to the plaza
	return { kind = "roam", position = Vector3.new(rng:NextNumber(-40, 40), 0.5, rng:NextNumber(-20, 20)) }
end

local function targetStillValid(target)
	if target.kind ~= "brainrot" then
		return true
	end
	for _, b in services.GardenService.getBrainrots() do
		if b.player == target.player and b.index == target.index then
			return true
		end
	end
	return false
end

local function despawn(monster, burstColor)
	local i = table.find(monsters, monster)
	if i then
		table.remove(monsters, i)
	end
	if monster.model.Parent then
		fx:FireAllClients("Burst", monster.model:GetPivot().Position, burstColor or Color3.fromRGB(150, 90, 220))
		monster.model:Destroy()
	end
end

local function dropCarried(monster, message)
	local carrying = monster.carrying
	if not carrying then
		return
	end
	monster.carrying = nil
	services.GardenService.returnHome(carrying.player, carrying.index)
	if message and carrying.player.Parent then
		fx:FireClient(carrying.player, "Toast", message, Color3.fromRGB(150, 255, 150))
	end
end

local function giveShards(player, amount, position)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	data.shards += amount
	services.SyncService.mark(player)
	fx:FireClient(player, "Shards", amount, position)
end

--------------------------------------------------------------------------------
-- Combat

local function die(monster, killer)
	local pos = monster.model:GetPivot().Position
	dropCarried(monster, "You rescued your brainrot!")
	if monster.kind == "Boss" then
		fx:FireAllClients("Announce", "THE 67 HAS FALLEN!", Color3.fromRGB(60, 150, 255))
		for player, damage in monster.damageBy do
			if player.Parent and damage >= monster.maxHp * 0.05 then
				giveShards(player, BOSS.shards, pos)
				if rng:NextNumber() < BOSS.lil67Chance then
					local data = services.DataService.get(player)
					if data then
						local key = Seeds.key("Lil67", "Normal")
						data.seeds[key] = (data.seeds[key] or 0) + 1
						services.SyncService.mark(player)
						services.FameService.record(player.DisplayName .. " got a LIL 67 seed from THE 67!", Rarities.byName.Secret.color)
					end
				end
			end
		end
		despawn(monster, Color3.fromRGB(60, 150, 255))
	else
		if killer and killer.Parent then
			giveShards(killer, rng:NextInteger(GRUMBLER.shards[1], GRUMBLER.shards[2]), pos)
		end
		despawn(monster)
	end
end

function MonsterService.damage(monster, amount: number, byPlayer: Player?)
	if monster.hp <= 0 then
		return
	end
	monster.hp -= amount
	if byPlayer then
		monster.damageBy[byPlayer] = (monster.damageBy[byPlayer] or 0) + amount
	end
	monster.hpFill.Size = UDim2.fromScale(math.clamp(monster.hp / monster.maxHp, 0, 1), 1)
	if monster.hp <= 0 then
		die(monster, byPlayer)
	end
end

local function defenseTick(dt)
	if #monsters == 0 then
		return
	end
	local zaps = {}
	for _, b in services.GardenService.getBrainrots() do
		local nearest, nearestDist = nil, GameConfig.DefenseRange
		for _, monster in monsters do
			local d = (flat(monster.model:GetPivot().Position) - flat(b.position)).Magnitude
			if d < nearestDist then
				nearest, nearestDist = monster, d
			end
		end
		if nearest then
			local power = (GameConfig.Power[b.rarity] or 5) * (1 + 0.15 * (b.mutationOrder - 1))
			MonsterService.damage(nearest, power * dt, b.player)
			if #zaps < 40 then
				table.insert(zaps, { b.position, nearest.model:GetPivot().Position + Vector3.new(0, 3, 0), Rarities.byName[b.rarity].color })
			end
		end
	end
	if #zaps > 0 then
		fx:FireAllClients("Zaps", zaps)
	end
end

--------------------------------------------------------------------------------
-- Spawning + movement

function MonsterService.spawn(kind: string)
	local night = math.max(1, services.DayNightService.nightNumber())
	local scale = 1 + NIGHT.HpGrowthPerNight * (night - 1)
	local model, hp, speed, title, offset, width
	if kind == "Boss" then
		model = build67()
		hp = (BOSS.hp + BOSS.hpPerPlayer * #Players:GetPlayers()) * scale
		speed, title, offset, width = BOSS.speed, "THE 67", 30, 360
	else
		model = buildGrumbler()
		hp = GRUMBLER.hp * scale
		speed, title, offset, width = GRUMBLER.speed, "Grumbler", 7.5, 120
	end
	local monster = {
		kind = kind,
		model = model,
		hp = hp,
		maxHp = hp,
		speed = speed,
		damageBy = {},
		nextStomp = os.clock() + BOSS.stompEvery,
		retargetAt = 0,
	}
	monster.hpFill = hpBar(model, model.PrimaryPart, title, width, offset, if kind == "Boss" then Color3.fromRGB(120, 190, 255) else Color3.fromRGB(200, 150, 255))
	model:PivotTo(CFrame.new(edgePoint()))
	model.Parent = folder
	table.insert(monsters, monster)
	return monster
end

local function stomp(monster)
	local pos = monster.model:GetPivot().Position
	fx:FireAllClients("Stomp", pos)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local offset = flat(root.Position - pos)
			if offset.Magnitude < 28 then
				local away = if offset.Magnitude > 0.1 then offset.Unit else Vector3.new(0, 0, 1)
				local attachment = Instance.new("Attachment")
				attachment.Parent = root
				local push = Instance.new("LinearVelocity")
				push.Attachment0 = attachment
				push.MaxForce = math.huge
				push.VectorVelocity = away * 70 + Vector3.new(0, 45, 0)
				push.Parent = root
				task.delay(0.15, function()
					push:Destroy()
					attachment:Destroy()
				end)
			end
		end
	end
end

local function step(monster, dt)
	local pos = monster.model:GetPivot().Position
	local now = os.clock()

	if not monster.carrying and (not monster.target or now >= monster.retargetAt) then
		if not monster.target or not targetStillValid(monster.target) then
			monster.target = pickTarget(monster)
		end
		monster.retargetAt = now + 1
	end

	local destination
	if monster.carrying then
		destination = monster.escapeTo
	else
		destination = monster.target.position
	end
	local offset = flat(destination - pos)
	local distance = offset.Magnitude

	if distance < 3 then
		if monster.carrying then
			-- escaped with the brainrot
			local carrying = monster.carrying
			monster.carrying = nil
			services.GardenService.lose(carrying.player, carrying.index)
			despawn(monster)
			return
		end
		local target = monster.target
		if target.kind == "brainrot" then
			local carried = services.GardenService.carry(target.player, target.index)
			if carried then
				monster.carrying = { player = target.player, index = target.index, model = carried }
				monster.escapeTo = nearestEdge(pos)
				fx:FireClient(target.player, "Toast", "A monster grabbed your brainrot! Stop it!", Color3.fromRGB(255, 120, 120))
			end
		elseif target.kind == "growing" then
			services.GardenService.slowGrowth(target.player, target.index, 0.2)
		end
		monster.target = nil
		return
	end

	local move = offset.Unit * math.min(distance, monster.speed * dt * (if monster.carrying then 0.75 else 1))
	local newPos = Vector3.new(pos.X + move.X, 0.5, pos.Z + move.Z)
	local bob = math.abs(math.sin(now * (if monster.kind == "Boss" then 4 else 9))) * (if monster.kind == "Boss" then 1.5 else 0.6)
	local cf = CFrame.lookAt(newPos, newPos + offset) * CFrame.new(0, bob, 0)
	monster.model:PivotTo(cf)

	if monster.carrying then
		local carried = monster.carrying.model
		if carried.Parent then
			carried:PivotTo(cf * CFrame.new(0, if monster.kind == "Boss" then 28 else 7, 0))
		else
			monster.carrying = nil -- owner left; nothing to carry
		end
	end

	if monster.kind == "Boss" and now >= monster.nextStomp then
		monster.nextStomp = now + BOSS.stompEvery
		stomp(monster)
	end
end

--------------------------------------------------------------------------------
-- Giant Spoon tool

local function makeSpoon()
	local tool = Instance.new("Tool")
	tool.Name = "Giant Spoon"
	tool.ToolTip = "Bonk night monsters!"
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.5, 4)
	handle.Color = Color3.fromRGB(200, 205, 215)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool
	local bowl = Instance.new("Part")
	bowl.Name = "Bowl"
	bowl.Shape = Enum.PartType.Ball
	bowl.Size = Vector3.new(1.8, 1.8, 1.8)
	bowl.Color = handle.Color
	bowl.Material = Enum.Material.Metal
	bowl.CanCollide = false
	bowl.Massless = true
	bowl.CFrame = handle.CFrame * CFrame.new(0, 0, -2.6)
	bowl.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = bowl
	weld.Parent = handle
	tool.Grip = CFrame.new(0, 0, 1.5)
	return tool
end

local function giveSpoon(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if backpack and not backpack:FindFirstChild("Giant Spoon") and not (player.Character and player.Character:FindFirstChild("Giant Spoon")) then
		local tool = makeSpoon()
		local lastSwing = 0
		tool.Activated:Connect(function()
			local character = tool.Parent
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root or os.clock() - lastSwing < SPOON.cooldown then
				return
			end
			lastSwing = os.clock()
			-- swing
			tool.Grip = CFrame.new(0, 0, 1.5) * CFrame.Angles(math.rad(-70), 0, 0)
			task.delay(0.15, function()
				tool.Grip = CFrame.new(0, 0, 1.5)
			end)
			-- hit the closest monster in reach (THE 67 is huge, so it's easier to reach)
			local best, bestScore = nil, math.huge
			for _, monster in monsters do
				local extra = if monster.kind == "Boss" then 10 else 0
				local d = (flat(monster.model:GetPivot().Position) - flat(root.Position)).Magnitude
				if d < SPOON.range + extra and d - extra < bestScore then
					best, bestScore = monster, d - extra
				end
			end
			if best then
				fx:FireAllClients("Bonk", best.model.PrimaryPart.Position)
				MonsterService.damage(best, SPOON.damage, player)
			end
		end)
		tool.Parent = backpack
	end
end

--------------------------------------------------------------------------------

function MonsterService.clearAll(message: string?)
	for _, monster in table.clone(monsters) do
		dropCarried(monster, nil)
		despawn(monster)
	end
	if message then
		fx:FireAllClients("Toast", message, Color3.fromRGB(255, 230, 150))
	end
end

function MonsterService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function MonsterService.start()
	folder = Instance.new("Folder")
	folder.Name = "Monsters"
	folder.Parent = workspace

	RunService.Heartbeat:Connect(function(dt)
		for _, monster in table.clone(monsters) do
			if monster.model.Parent then
				step(monster, dt)
			end
		end
	end)

	task.spawn(function()
		while true do
			local dt = task.wait(0.5)
			defenseTick(dt)
		end
	end)

	services.DayNightService.NightStarted:Connect(function(night, isBoss)
		task.spawn(function()
			if isBoss then
				task.delay(15, function()
					if services.DayNightService.isNight() then
						fx:FireAllClients("Announce", "THE 67 IS COMING!!!", Color3.fromRGB(60, 150, 255))
						MonsterService.spawn("Boss")
					end
				end)
			end
			while services.DayNightService.isNight() and services.DayNightService.nightNumber() == night do
				local size = math.min(NIGHT.WaveSize.max, NIGHT.WaveSize.base + NIGHT.WaveSize.perPlayer * #Players:GetPlayers())
				for _ = 1, size do
					if #monsters < NIGHT.MaxMonsters then
						MonsterService.spawn("Grumbler")
					end
				end
				task.wait(NIGHT.WaveEvery)
			end
		end)
	end)

	services.DayNightService.DayStarted:Connect(function()
		if #monsters > 0 then
			MonsterService.clearAll("Dawn! The monsters ran away and dropped everything they stole.")
		end
	end)

	local function onPlayer(player)
		player.CharacterAdded:Connect(function()
			giveSpoon(player)
		end)
		if player.Character then
			giveSpoon(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
end

return MonsterService
