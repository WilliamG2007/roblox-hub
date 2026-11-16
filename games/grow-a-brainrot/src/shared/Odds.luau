-- All the probability math, shared so the odds the shop SHOWS are exactly the
-- odds the server ROLLS (Roblox requires accurate odds for paid random items).

local Brainrots = require(script.Parent.Config.Brainrots)
local Rarities = require(script.Parent.Config.Rarities)
local Mutations = require(script.Parent.Config.Mutations)

local Odds = {}

-- Rarity chances for a pack. Luck boosts higher tiers: the top tier's weight is
-- multiplied by `luck`, the lowest by 1, and tiers in between proportionally.
function Odds.rarities(pack, luck: number?)
	luck = luck or 1
	local entries = {}
	for _, pair in pack.rarities do
		table.insert(entries, { rarity = pair[1], weight = pair[2] })
	end
	table.sort(entries, function(a, b)
		return Rarities.byName[a.rarity].order < Rarities.byName[b.rarity].order
	end)
	local n = #entries
	local total = 0
	for i, entry in entries do
		local k = if n > 1 then (i - 1) / (n - 1) else 0
		entry.weight *= luck ^ k
		total += entry.weight
	end
	for _, entry in entries do
		entry.chance = entry.weight / total
	end
	return entries
end

-- Chance of each brainrot inside one rarity tier.
function Odds.brainrots(rarityName: string)
	local group = Brainrots.byRarity[rarityName] or {}
	local total = 0
	for _, def in group do
		total += def.weight
	end
	local entries = {}
	for _, def in group do
		table.insert(entries, { id = def.id, chance = def.weight / total })
	end
	return entries
end

-- Mutation chances given a combined mutation luck multiplier.
function Odds.mutations(mutationLuck: number?)
	mutationLuck = mutationLuck or 1
	local entries = {}
	local mutated = 0
	for _, mutation in Mutations.list do
		if mutation.id ~= "Normal" then
			local chance = mutation.chance * mutationLuck
			mutated += chance
			table.insert(entries, { id = mutation.id, chance = chance })
		end
	end
	if mutated > Mutations.MaxTotalChance then
		local scale = Mutations.MaxTotalChance / mutated
		for _, entry in entries do
			entry.chance *= scale
		end
		mutated = Mutations.MaxTotalChance
	end
	table.insert(entries, 1, { id = "Normal", chance = 1 - mutated })
	return entries
end

-- Picks one entry from a list of { chance = ... } using a Random object.
function Odds.pick(entries, rng: Random)
	local roll = rng:NextNumber()
	local acc = 0
	for _, entry in entries do
		acc += entry.chance
		if roll < acc then
			return entry
		end
	end
	return entries[#entries]
end

return Odds
