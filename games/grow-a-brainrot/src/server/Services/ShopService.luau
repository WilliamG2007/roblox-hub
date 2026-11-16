-- Seed shop. Stock re-rolls every RestockInterval seconds; the roll is seeded by
-- the time window, so every server shows the same stock. Each player has their
-- own remaining quantities per restock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ShopService = {}

local services
local fx
local currentWindow = -1
local currentStock = {}

local function windowAt(now)
	return math.floor(now / GameConfig.RestockInterval)
end

local function rollStock(window)
	local rng = Random.new(window * 7919 + 13)
	local stock = {}
	for _, def in Brainrots.list do
		local rarity = Rarities.byName[def.rarity]
		local roll = rng:NextNumber()
		local qty = rng:NextInteger(rarity.stock[1], math.max(rarity.stock[1], rarity.stock[2]))
		if def.inShop ~= false and roll < rarity.shopChance and qty > 0 then
			table.insert(stock, { id = def.id, qty = qty })
		end
	end
	return stock
end

local function refreshWindow()
	local window = windowAt(workspace:GetServerTimeNow())
	if window ~= currentWindow then
		local first = currentWindow == -1
		currentWindow = window
		currentStock = rollStock(window)
		if not first then
			fx:FireAllClients("Restock")
		end
		return true
	end
	return false
end

local function playerShop(player)
	local data = services.DataService.get(player)
	if not data then
		return nil
	end
	if data.shop.window ~= currentWindow then
		data.shop = { window = currentWindow, bought = {} }
	end
	return data.shop
end

function ShopService.snapshot(player)
	local shop = playerShop(player)
	local items = {}
	for _, item in currentStock do
		local bought = if shop then shop.bought[item.id] or 0 else 0
		table.insert(items, { id = item.id, qty = item.qty, left = math.max(0, item.qty - bought) })
	end
	return {
		window = currentWindow,
		endsAt = (currentWindow + 1) * GameConfig.RestockInterval,
		items = items,
	}
end

function ShopService.buy(player, id)
	if type(id) ~= "string" then
		return
	end
	local def = Brainrots.byId[id]
	local shop = playerShop(player)
	if not def or not shop then
		return
	end
	local item
	for _, stocked in currentStock do
		if stocked.id == id then
			item = stocked
		end
	end
	local bought = shop.bought[id] or 0
	if not item or bought >= item.qty then
		return
	end
	if not services.EconomyService.spend(player, def.cost) then
		fx:FireClient(player, "Toast", "Not enough cash!", Color3.fromRGB(255, 120, 120))
		return
	end
	shop.bought[id] = bought + 1
	local data = services.DataService.get(player)
	data.seeds[id] = (data.seeds[id] or 0) + 1
	fx:FireClient(player, "Bought", id)
	services.SyncService.mark(player)
end

function ShopService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function ShopService.start()
	refreshWindow()
	Remotes.get("Buy").OnServerEvent:Connect(ShopService.buy)
	services.MapService.ShopPrompt.Triggered:Connect(function(player)
		fx:FireClient(player, "OpenShop")
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if refreshWindow() then
				for _, player in game:GetService("Players"):GetPlayers() do
					services.SyncService.mark(player)
				end
			end
		end
	end)
end

return ShopService
