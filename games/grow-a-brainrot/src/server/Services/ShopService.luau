-- Pack shop. Stock re-rolls every RestockInterval seconds, seeded by the time
-- window so every server shows the same stock. Each player has their own
-- remaining quantities per restock.
--
-- Opening a pack (server-authoritative): roll rarity (pack odds x server luck,
-- or forced by pity) -> roll brainrot in that rarity -> roll mutation (pack x
-- server mutation luck). The seed goes to the inventory; the client just plays
-- the reveal animation for the result it's sent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Packs = require(Shared.Config.Packs)
local Odds = require(Shared.Odds)
local Seeds = require(Shared.Seeds)
local Remotes = require(Shared.Remotes)

local ShopService = {}

local services
local fx
local rng = Random.new()
local currentWindow = -1
local forcedSalt = 0
local currentStock = {}

local ANNOUNCE_RARITY = Rarities.byName.Legendary.order
local ANNOUNCE_MUTATION = Mutations.byId.Rainbow.order
local GLOBAL_MUTATION = Mutations.byId.SixtySeven.order

local function stockId()
	return currentWindow .. ":" .. forcedSalt
end

local function rollStock(seed)
	local stockRng = Random.new(seed)
	local stock = {}
	for _, pack in Packs.list do
		local roll = stockRng:NextNumber()
		local qty = stockRng:NextInteger(pack.stock[1], pack.stock[2])
		if roll < pack.stockChance then
			table.insert(stock, { id = pack.id, qty = qty })
		end
	end
	return stock
end

local function markAll()
	for _, player in Players:GetPlayers() do
		services.SyncService.mark(player)
	end
end

local function refreshWindow()
	local window = math.floor(workspace:GetServerTimeNow() / GameConfig.RestockInterval)
	if window ~= currentWindow then
		local first = currentWindow == -1
		currentWindow = window
		forcedSalt = 0
		currentStock = rollStock(window * 7919 + 13)
		if not first then
			fx:FireAllClients("Restock")
		end
		markAll()
	end
end

local function playerShop(player)
	local data = services.DataService.get(player)
	if not data then
		return nil
	end
	if data.shop.stockId ~= stockId() then
		data.shop = { stockId = stockId(), bought = {} }
	end
	return data.shop
end

local function rollOne(data, pack)
	-- rarity (pity can force it)
	local pityRarity = Rarities.byName[pack.pity.rarity]
	local pity = data.pity[pack.id] or 0
	local rarityName
	if pity + 1 >= pack.pity.count then
		rarityName = pack.pity.rarity
	else
		rarityName = Odds.pick(Odds.rarities(pack, services.LuckService.getLuck()), rng).rarity
	end
	if Rarities.byName[rarityName].order >= pityRarity.order then
		data.pity[pack.id] = 0
	else
		data.pity[pack.id] = pity + 1
	end

	local id = Odds.pick(Odds.brainrots(rarityName), rng).id
	local mutationLuck = pack.mutationLuck * services.LuckService.getMutationLuck()
	local mutation = Odds.pick(Odds.mutations(mutationLuck, pack.bonusMutation), rng).id
	return { id = id, mutation = mutation, pity = pity + 1 >= pack.pity.count }
end

local function announce(player, pack, result)
	local def = Brainrots.byId[result.id]
	local rarity = Rarities.byName[def.rarity]
	local mutation = Mutations.byId[result.mutation]
	if rarity.order < ANNOUNCE_RARITY and mutation.order < ANNOUNCE_MUTATION then
		return
	end
	local mutationText = if result.mutation ~= "Normal" then string.upper(mutation.name) .. " " else ""
	local text = string.format("%s pulled a %s%s %s from a %s!", player.DisplayName, mutationText, string.upper(def.rarity), def.name, pack.name)
	local color = if result.mutation ~= "Normal" then mutation.color else rarity.color
	services.FameService.record(text, color)
	if def.rarity == "Secret" or mutation.order >= GLOBAL_MUTATION then
		services.FameService.broadcast(text, color)
	end
end

-- Opens `count` packs for a player and plays the reveal. Used by buying and by admin gifts.
function ShopService.openPacks(player, pack, count: number)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	local results = {}
	local autoSold = 0
	for _ = 1, count do
		local result = rollOne(data, pack)
		if services.InventoryService.shouldAutoSell(data, result.id, result.mutation) then
			result.autoSold = services.InventoryService.seedValue(result.id, result.mutation)
			autoSold += result.autoSold
		else
			local key = Seeds.key(result.id, result.mutation)
			data.seeds[key] = (data.seeds[key] or 0) + 1
		end
		table.insert(results, result)
	end
	if autoSold > 0 then
		services.EconomyService.add(player, autoSold)
	end
	fx:FireClient(player, "PackOpened", pack.id, results)
	-- announce after the reveal has had time to play
	task.delay(if count == 1 then 4.5 else 3, function()
		for _, result in results do
			announce(player, pack, result)
		end
	end)
	services.SyncService.mark(player)
end

function ShopService.buy(player, packId, count)
	if type(packId) ~= "string" then
		return
	end
	local pack = Packs.byId[packId]
	local shop = playerShop(player)
	if not pack or not shop then
		return
	end
	count = math.clamp(math.floor(tonumber(count) or 1), 1, GameConfig.MaxOpenAtOnce)
	local item
	for _, stocked in currentStock do
		if stocked.id == packId then
			item = stocked
		end
	end
	local bought = shop.bought[packId] or 0
	if not item then
		return
	end
	count = math.min(count, item.qty - bought)
	if count < 1 then
		return
	end
	local cost = pack.price * count
	if pack.currency == "shards" then
		local data = services.DataService.get(player)
		if data.shards < cost then
			fx:FireClient(player, "Toast", "Not enough Moon Shards! Defeat monsters at night to earn them.", Color3.fromRGB(170, 190, 255))
			return
		end
		data.shards -= cost
	elseif not services.EconomyService.spend(player, cost) then
		fx:FireClient(player, "Toast", "Not enough cash!", Color3.fromRGB(255, 120, 120))
		return
	end
	shop.bought[packId] = bought + count
	ShopService.openPacks(player, pack, count)
end

function ShopService.forceRestock()
	forcedSalt += 1
	currentStock = rollStock(rng:NextInteger(1, 2 ^ 30))
	fx:FireAllClients("Restock")
	markAll()
end

-- Admin: puts a pack into the current stock (or raises its quantity).
function ShopService.addToStock(packId: string, qty: number)
	for _, item in currentStock do
		if item.id == packId then
			item.qty += qty
			markAll()
			return
		end
	end
	table.insert(currentStock, { id = packId, qty = qty })
	table.sort(currentStock, function(a, b)
		return Packs.byId[a.id].order < Packs.byId[b.id].order
	end)
	markAll()
end

function ShopService.snapshot(player)
	local shop = playerShop(player)
	local data = services.DataService.get(player)
	local items = {}
	for _, item in currentStock do
		local bought = if shop then shop.bought[item.id] or 0 else 0
		table.insert(items, { id = item.id, qty = item.qty, left = math.max(0, item.qty - bought) })
	end
	return {
		stockId = stockId(),
		endsAt = (currentWindow + 1) * GameConfig.RestockInterval,
		items = items,
		pity = if data then data.pity else {},
	}
end

function ShopService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function ShopService.start()
	refreshWindow()
	Remotes.get("BuyPack").OnServerEvent:Connect(ShopService.buy)
	services.MapService.ShopPrompt.Triggered:Connect(function(player)
		fx:FireClient(player, "OpenShop")
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			refreshWindow()
		end
	end)
end

return ShopService
