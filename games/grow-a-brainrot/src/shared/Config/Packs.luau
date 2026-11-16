-- Seed packs: the progression ladder. Each pack rolls a rarity (weights below),
-- then a brainrot within it, then a mutation (boosted by mutationLuck).
--
-- Balance idea: each tier costs ~6-8x the last while its expected income grows
-- a bit slower, so payback time stretches from seconds (Basic Bag) to ~20+ min
-- (Cosmic). Higher packs are also rarer in stock.
-- pity: after `count` opens without hitting `rarity` or better, the next one is guaranteed.

local Packs = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Packs.list = {
	{ id = "BasicBag", name = "Basic Bag", price = 25, color = rgb(190, 140, 90), mutationLuck = 1,
		rarities = { { "Common", 75 }, { "Uncommon", 22 }, { "Rare", 3 } },
		stockChance = 1, stock = { 8, 15 }, pity = { rarity = "Rare", count = 25 } },
	{ id = "RizzPack", name = "Rizz Pack", price = 250, color = rgb(90, 220, 110), mutationLuck = 1.2,
		rarities = { { "Common", 30 }, { "Uncommon", 50 }, { "Rare", 18 }, { "Epic", 2 } },
		stockChance = 1, stock = { 5, 10 }, pity = { rarity = "Epic", count = 40 } },
	{ id = "SigmaPack", name = "Sigma Pack", price = 2000, color = rgb(70, 150, 255), mutationLuck = 1.5,
		rarities = { { "Uncommon", 35 }, { "Rare", 48 }, { "Epic", 15 }, { "Legendary", 2 } },
		stockChance = 1, stock = { 4, 8 }, pity = { rarity = "Legendary", count = 40 } },
	{ id = "AuraPack", name = "Aura Pack", price = 12000, color = rgb(180, 90, 255), mutationLuck = 2,
		rarities = { { "Uncommon", 5 }, { "Rare", 40 }, { "Epic", 45 }, { "Legendary", 9.5 }, { "Mythic", 0.5 } },
		stockChance = 0.85, stock = { 3, 6 }, pity = { rarity = "Mythic", count = 120 } },
	{ id = "MewingPack", name = "Mewing Pack", price = 60000, color = rgb(255, 110, 190), mutationLuck = 2.5,
		rarities = { { "Rare", 15 }, { "Epic", 50 }, { "Legendary", 32 }, { "Mythic", 3 } },
		stockChance = 0.65, stock = { 2, 5 }, pity = { rarity = "Mythic", count = 45 } },
	{ id = "OhioPack", name = "Ohio Pack", price = 300000, color = rgb(255, 150, 50), mutationLuck = 3,
		rarities = { { "Epic", 35 }, { "Legendary", 52 }, { "Mythic", 12.5 }, { "Secret", 0.5 } },
		stockChance = 0.5, stock = { 2, 4 }, pity = { rarity = "Mythic", count = 12 } },
	{ id = "GigachadPack", name = "Gigachad Pack", price = 1.5e6, color = rgb(255, 210, 60), mutationLuck = 4,
		rarities = { { "Epic", 10 }, { "Legendary", 55 }, { "Mythic", 33 }, { "Secret", 2 } },
		stockChance = 0.35, stock = { 1, 3 }, pity = { rarity = "Secret", count = 60 } },
	{ id = "TralalaPack", name = "Tralala Pack", price = 6e6, color = rgb(60, 220, 230), mutationLuck = 5,
		rarities = { { "Legendary", 45 }, { "Mythic", 50 }, { "Secret", 5 } },
		stockChance = 0.25, stock = { 1, 2 }, pity = { rarity = "Secret", count = 30 } },
	{ id = "SixtySevenPack", name = "67 Pack", price = 2.5e7, color = rgb(255, 60, 60), mutationLuck = 6.7,
		rarities = { { "Legendary", 20 }, { "Mythic", 66 }, { "Secret", 14 } },
		stockChance = 0.15, stock = { 1, 1 }, pity = { rarity = "Secret", count = 10 } },
	{ id = "CosmicPack", name = "Cosmic Brainrot Pack", price = 1e8, color = rgb(120, 60, 255), mutationLuck = 8,
		rarities = { { "Mythic", 60 }, { "Secret", 40 } },
		stockChance = 0.08, stock = { 1, 1 }, pity = { rarity = "Secret", count = 4 } },
}

Packs.byId = {}
for i, pack in Packs.list do
	pack.order = i
	Packs.byId[pack.id] = pack
end

return Packs
