-- The core loop: plant a seed -> it grows -> POP, a brainrot -> it earns cash
-- into a stored pile -> step on the collect pad. Brainrots can also be sold.
--
-- Tile state lives in player data (data.tiles["<i>"]) and is mirrored onto the
-- tile Part as attributes so the client can draw growth visuals:
--   PlantId, Mutation, PlantedAt (server time), GrowTime, State ("growing" | "grown" | nil)
-- The brainrot and its mutation are already decided when the pack opens; the
-- pop only rolls the size.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local BrainrotModels = require(ReplicatedStorage.Shared.BrainrotModels)
local Seeds = require(ReplicatedStorage.Shared.Seeds)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local GardenService = {}

local services
local fx
local sessions = {} -- [Player] = { plot, data, models = { [index] = Model } }

local HUGE_SIZE = 2.3

local function now()
	return workspace:GetServerTimeNow()
end

local function randomSize()
	local r = math.random()
	local size = GameConfig.SizeMin + (GameConfig.SizeMax - GameConfig.SizeMin) * r ^ GameConfig.SizeCurve
	return math.floor(size * 100 + 0.5) / 100
end

local function mutationOf(tile)
	return Mutations.byId[tile.mutation or "Normal"] or Mutations.byId.Normal
end

local function incomeOf(tile)
	return Brainrots.byId[tile.id].income * mutationOf(tile).mult * (tile.size or 1)
end

local function setTileAttributes(tilePart, tile)
	tilePart:SetAttribute("PlantId", tile and tile.id or nil)
	tilePart:SetAttribute("Mutation", tile and tile.mutation or nil)
	tilePart:SetAttribute("PlantedAt", tile and tile.plantedAt or nil)
	tilePart:SetAttribute("GrowTime", tile and tile.growTime or nil)
	tilePart:SetAttribute("State", tile and tile.state or nil)
end

local function makeBillboard(model, def, tile)
	local rarity = Rarities.byName[def.rarity]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(200, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y + 1.5, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui
	local function line(name, text, color, height)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Size = UDim2.new(1, 0, 0, height)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.Text = text
		l.TextColor3 = color
		l.TextStrokeTransparency = 0
		l.Parent = gui
		return l
	end
	local mutation = mutationOf(tile)
	local sizeTag = if tile.size >= 2 then "HUGE " elseif tile.size >= 1.5 then "Big " else ""
	local mutationTag = if mutation.id ~= "Normal" then mutation.name .. " " else ""
	line("Name", mutationTag .. sizeTag .. def.name, if mutation.id ~= "Normal" then mutation.color else rarity.color, 24)
	line("Rate", Format.cash(incomeOf(tile)) .. "/s", Color3.fromRGB(150, 255, 150), 20)
	line("Stored", "", Color3.fromRGB(255, 240, 150), 22)
	gui.Parent = model.PrimaryPart
	return gui
end

local function spawnBrainrot(session, index, tile)
	local def = Brainrots.byId[tile.id]
	local tilePart = services.PlotService.getTile(session.plot, index)
	local model = BrainrotModels.build(tile.id, tile.size, tile.mutation)
	model.Name = "Brainrot" .. index
	model:PivotTo(tilePart.CFrame * CFrame.new(0, tilePart.Size.Y / 2, 0))
	makeBillboard(model, def, tile)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Sell"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if player == session.player then
			GardenService.sell(player, index)
		end
	end)

	model.Parent = session.plot
	session.models[index] = model
end

local function grow(session, index, tile)
	local def = Brainrots.byId[tile.id]
	tile.state = "grown"
	tile.size = randomSize()
	tile.stored = 0
	local data = session.data
	data.stats.grown += 1
	local isNew = not data.index[tile.id]
	data.index[tile.id] = true

	local tilePart = services.PlotService.getTile(session.plot, index)
	setTileAttributes(tilePart, tile)
	spawnBrainrot(session, index, tile)

	fx:FireAllClients("Pop", tilePart.Position, def.rarity, session.player.UserId, tile.mutation or "Normal", tile.size)
	if isNew then
		fx:FireClient(session.player, "Toast", "NEW BRAINROT DISCOVERED: " .. def.name .. "!", Rarities.byName[def.rarity].color)
	end
	if tile.size >= HUGE_SIZE then
		services.FameService.record(string.format("%s grew a HUGE %.1fx %s!", session.player.DisplayName, tile.size, def.name), Rarities.byName[def.rarity].color)
	end
	services.SyncService.mark(session.player)
end

function GardenService.plant(player, index, seedKey)
	local session = sessions[player]
	if not session or type(index) ~= "number" or type(seedKey) ~= "string" then
		return
	end
	index = math.floor(index)
	local id, mutation = Seeds.parse(seedKey)
	local def = Brainrots.byId[id]
	if not def or not Mutations.byId[mutation] or index < 1 or index > services.PlotService.tileCount() then
		return
	end
	local data = session.data
	local key = tostring(index)
	if data.tiles[key] or (data.seeds[seedKey] or 0) < 1 then
		return
	end

	data.seeds[seedKey] -= 1
	if data.seeds[seedKey] <= 0 then
		data.seeds[seedKey] = nil
	end
	local tile = { id = id, mutation = mutation, plantedAt = now(), growTime = def.growTime, state = "growing" }
	data.tiles[key] = tile
	data.stats.planted += 1

	local tilePart = services.PlotService.getTile(session.plot, index)
	setTileAttributes(tilePart, tile)
	fx:FireAllClients("Planted", tilePart.Position)
	services.SyncService.mark(player)
end

function GardenService.sell(player, index)
	local session = sessions[player]
	local key = tostring(index)
	local tile = session and session.data.tiles[key]
	if not tile or tile.state ~= "grown" then
		return
	end
	local def = Brainrots.byId[tile.id]
	local value = incomeOf(tile) * GameConfig.SellIncomeSeconds + (tile.stored or 0)
	session.data.tiles[key] = nil
	local model = session.models[index]
	if model then
		model:Destroy()
		session.models[index] = nil
	end
	local tilePart = services.PlotService.getTile(session.plot, index)
	setTileAttributes(tilePart, nil)
	services.EconomyService.add(player, value)
	fx:FireClient(player, "Cash", value, tilePart.Position, "SOLD")
end

function GardenService.collect(player)
	local session = sessions[player]
	if not session then
		return
	end
	local total = 0
	for _, tile in session.data.tiles do
		if tile.state == "grown" and (tile.stored or 0) > 0 then
			total += tile.stored
			tile.stored = 0
		end
	end
	if total >= 1 then
		services.EconomyService.add(player, total)
		fx:FireClient(player, "Cash", total, session.plot.CollectPad.Position, "COLLECTED")
	end
end

function GardenService.getIncome(player): number
	local session = sessions[player]
	if not session then
		return 0
	end
	local total = 0
	for _, tile in session.data.tiles do
		if tile.state == "grown" then
			total += incomeOf(tile)
		end
	end
	return total
end

function GardenService.loadPlayer(player, data, plot)
	if not plot then
		fx:FireClient(player, "Toast", "This server's gardens are full! Try another server.", Color3.fromRGB(255, 120, 120))
		return
	end
	local session = { player = player, plot = plot, data = data, models = {}, lastCollect = 0 }
	sessions[player] = session

	-- offline earnings for grown brainrots
	local offline = 0
	if data.lastSave > 0 then
		local elapsed = math.clamp(os.time() - data.lastSave, 0, GameConfig.OfflineCapSeconds)
		for _, tile in data.tiles do
			if tile.state == "grown" then
				local earned = incomeOf(tile) * elapsed * GameConfig.OfflineEarnRate
				tile.stored = (tile.stored or 0) + earned
				offline += earned
			end
		end
	end

	for key, tile in data.tiles do
		local index = tonumber(key)
		local tilePart = index and services.PlotService.getTile(plot, index)
		if not tilePart or not Brainrots.byId[tile.id] then
			data.tiles[key] = nil -- drop corrupt or removed entries
		else
			setTileAttributes(tilePart, tile)
			if tile.state == "grown" then
				spawnBrainrot(session, index, tile)
			end
		end
	end

	session.padConnection = plot.CollectPad.Touched:Connect(function(hit)
		local character = hit.Parent
		if Players:GetPlayerFromCharacter(character) == player and os.clock() - session.lastCollect > 1 then
			session.lastCollect = os.clock()
			GardenService.collect(player)
		end
	end)

	if offline >= 1 then
		task.delay(3, function()
			fx:FireClient(player, "Toast", "While you were away, your brainrots made " .. Format.cash(offline) .. "! Step on COLLECT.", Color3.fromRGB(150, 255, 160))
		end)
	end
end

function GardenService.unloadPlayer(player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	if session.padConnection then
		session.padConnection:Disconnect()
	end
	for _, model in session.models do
		model:Destroy()
	end
	for i = 1, services.PlotService.tileCount() do
		setTileAttributes(services.PlotService.getTile(session.plot, i), nil)
	end
end

-- Admin: makes every growing plant ready to pop on the next growth check.
function GardenService.finishGrowing(player)
	local session = sessions[player]
	if not session then
		return
	end
	for _, tile in session.data.tiles do
		if tile.state == "growing" then
			tile.plantedAt = now() - tile.growTime
		end
	end
end

-- Admin: removes every plant and brainrot from a player's garden.
function GardenService.clearGarden(player)
	local session = sessions[player]
	if not session then
		return
	end
	for index, model in session.models do
		model:Destroy()
		session.models[index] = nil
	end
	table.clear(session.data.tiles)
	for i = 1, services.PlotService.tileCount() do
		setTileAttributes(services.PlotService.getTile(session.plot, i), nil)
	end
	services.SyncService.mark(player)
end

function GardenService.hasSession(player)
	return sessions[player] ~= nil
end

function GardenService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function GardenService.start()
	Remotes.get("Plant").OnServerEvent:Connect(GardenService.plant)

	-- growth checks
	task.spawn(function()
		while true do
			task.wait(0.25)
			local t = now()
			for _, session in sessions do
				for key, tile in session.data.tiles do
					if tile.state == "growing" and t >= tile.plantedAt + tile.growTime then
						grow(session, tonumber(key), tile)
					end
				end
			end
		end
	end)

	-- income ticks
	task.spawn(function()
		while true do
			task.wait(1)
			for _, session in sessions do
				local stored = 0
				for key, tile in session.data.tiles do
					if tile.state == "grown" then
						tile.stored = (tile.stored or 0) + incomeOf(tile)
						stored += tile.stored
						local model = session.models[tonumber(key)]
						local info = model and model.PrimaryPart and model.PrimaryPart:FindFirstChild("Info")
						if info then
							info.Stored.Text = Format.cash(tile.stored)
						end
					end
				end
				session.plot.CollectPad.Stored.Text.Text = "COLLECT " .. Format.cash(stored)
			end
		end
	end)
end

return GardenService
