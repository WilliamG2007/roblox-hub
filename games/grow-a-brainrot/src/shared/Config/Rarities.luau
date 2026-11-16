-- Rarity tiers: color, how often they show up in the seed shop, and how many per restock.

local Rarities = {}

Rarities.list = {
	{ name = "Common", color = Color3.fromRGB(215, 215, 225), shopChance = 1, stock = { 3, 6 } },
	{ name = "Uncommon", color = Color3.fromRGB(90, 225, 110), shopChance = 0.65, stock = { 2, 4 } },
	{ name = "Rare", color = Color3.fromRGB(70, 160, 255), shopChance = 0.35, stock = { 1, 3 } },
	{ name = "Epic", color = Color3.fromRGB(185, 95, 255), shopChance = 0.15, stock = { 1, 2 } },
	{ name = "Legendary", color = Color3.fromRGB(255, 200, 40), shopChance = 0.05, stock = { 1, 1 } },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 120), shopChance = 0.015, stock = { 1, 1 } },
	{ name = "Secret", color = Color3.fromRGB(255, 255, 255), shopChance = 0, stock = { 0, 0 } },
}

Rarities.byName = {}
for i, rarity in Rarities.list do
	rarity.order = i
	Rarities.byName[rarity.name] = rarity
end

return Rarities
