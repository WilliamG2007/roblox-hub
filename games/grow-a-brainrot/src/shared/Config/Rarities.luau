-- Rarity tiers (order = how rare). Which tiers a pack can give lives in Config/Packs.

local Rarities = {}

Rarities.list = {
	{ name = "Common", color = Color3.fromRGB(215, 215, 225) },
	{ name = "Uncommon", color = Color3.fromRGB(90, 225, 110) },
	{ name = "Rare", color = Color3.fromRGB(70, 160, 255) },
	{ name = "Epic", color = Color3.fromRGB(185, 95, 255) },
	{ name = "Legendary", color = Color3.fromRGB(255, 200, 40) },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 120) },
	{ name = "Secret", color = Color3.fromRGB(255, 255, 255) },
}

Rarities.byName = {}
for i, rarity in Rarities.list do
	rarity.order = i
	Rarities.byName[rarity.name] = rarity
end

return Rarities
