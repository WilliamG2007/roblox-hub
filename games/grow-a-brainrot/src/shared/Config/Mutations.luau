-- Mutations, rolled right after the brainrot when a pack opens.
-- chance = base chance before pack/server mutation luck. Normal fills the rest.

local Mutations = {}

Mutations.list = {
	{ id = "Normal", name = "Normal", mult = 1, chance = 0, color = Color3.fromRGB(220, 220, 220) },
	{ id = "Gold", name = "Gold", mult = 3, chance = 0.06, color = Color3.fromRGB(255, 200, 40) },
	{ id = "Diamond", name = "Diamond", mult = 6, chance = 0.025, color = Color3.fromRGB(140, 225, 255) },
	{ id = "Rainbow", name = "Rainbow", mult = 12, chance = 0.008, color = Color3.fromRGB(255, 120, 220) },
	{ id = "Galaxy", name = "Galaxy", mult = 30, chance = 0.002, color = Color3.fromRGB(150, 90, 255) },
	{ id = "SixtySeven", name = "67", mult = 67, chance = 0.00067, color = Color3.fromRGB(60, 150, 255) },
	-- special mutations: chance 0 = never from normal rolls, only from packs/events that grant them
	{ id = "Moonlit", name = "Moonlit", mult = 5, chance = 0, color = Color3.fromRGB(170, 200, 255), special = true },
}

-- mutated chances never add up to more than this (Normal always stays possible)
Mutations.MaxTotalChance = 0.9

Mutations.byId = {}
for i, mutation in Mutations.list do
	mutation.order = i
	Mutations.byId[mutation.id] = mutation
end

return Mutations
