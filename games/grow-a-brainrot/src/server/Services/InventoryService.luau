-- Backpack actions: sell seeds you don't want (one, all of a kind, or every
-- Normal seed of a rarity) and auto-sell settings for pack pulls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Mutations = require(Shared.Config.Mutations)
local Seeds = require(Shared.Seeds)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local InventoryService = {}

local services
local fx

function InventoryService.seedValue(id: string, mutationId: string): number
	local def = Brainrots.byId[id]
	local mutation = Mutations.byId[mutationId] or Mutations.byId.Normal
	return if def then def.income * mutation.mult * GameConfig.SeedSellSeconds else 0
end

-- true if a freshly pulled seed should be auto-sold instead of kept
function InventoryService.shouldAutoSell(data, id: string, mutationId: string): boolean
	local def = Brainrots.byId[id]
	return def ~= nil and mutationId == "Normal" and data.autoSell[def.rarity] == true
end

local function sell(player, key: string, count: number): number
	local data = services.DataService.get(player)
	local have = data and data.seeds[key] or 0
	count = math.min(count, have)
	if count < 1 then
		return 0
	end
	local id, mutationId = Seeds.parse(key)
	local value = InventoryService.seedValue(id, mutationId) * count
	data.seeds[key] = have - count
	if data.seeds[key] <= 0 then
		data.seeds[key] = nil
	end
	services.EconomyService.add(player, value)
	return value
end

local actions = {}

function actions.Sell(player, key, count)
	if type(key) ~= "string" then
		return
	end
	local value = sell(player, key, math.clamp(math.floor(tonumber(count) or 1), 1, 1e6))
	if value > 0 then
		fx:FireClient(player, "Toast", "Sold for " .. Format.cash(value), Color3.fromRGB(150, 255, 150))
	end
end

function actions.SellRarity(player, rarityName)
	local data = services.DataService.get(player)
	if not data or type(rarityName) ~= "string" then
		return
	end
	local total = 0
	for key, count in table.clone(data.seeds) do
		local id, mutationId = Seeds.parse(key)
		local def = Brainrots.byId[id]
		if def and def.rarity == rarityName and mutationId == "Normal" then
			total += sell(player, key, count)
		end
	end
	if total > 0 then
		fx:FireClient(player, "Toast", string.format("Sold all Normal %s seeds for %s", rarityName, Format.cash(total)), Color3.fromRGB(150, 255, 150))
	end
end

function actions.AutoSell(player, rarityName, enabled)
	local data = services.DataService.get(player)
	if not data or not table.find(GameConfig.AutoSellRarities, rarityName) then
		return
	end
	data.autoSell[rarityName] = if enabled then true else nil
	services.SyncService.mark(player)
end

function InventoryService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function InventoryService.start()
	Remotes.get("Inventory").OnServerEvent:Connect(function(player, action, ...)
		local handler = type(action) == "string" and actions[action]
		if handler then
			handler(player, ...)
		end
	end)
end

return InventoryService
