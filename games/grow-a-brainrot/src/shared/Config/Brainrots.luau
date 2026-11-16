-- The brainrot roster. Each one is also its own seed in the shop.
-- cost = seed price, growTime = seconds, income = cash/sec at size 1.
-- colors/shape only drive the placeholder model; real art goes in
-- ReplicatedStorage.Assets.Brainrots.<id> and replaces it automatically.

local Brainrots = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Brainrots.list = {
	-- Common
	{ id = "LiriliLarila", name = "Lirilì Larilà", rarity = "Common", cost = 10, growTime = 15, income = 1,
		colors = { rgb(120, 190, 90), rgb(140, 100, 70) }, shape = "tall" },
	{ id = "BrrBrrPatapim", name = "Brr Brr Patapim", rarity = "Common", cost = 25, growTime = 25, income = 2,
		colors = { rgb(130, 95, 60), rgb(90, 170, 70) }, shape = "tall" },
	{ id = "TrippiTroppi", name = "Trippi Troppi", rarity = "Common", cost = 40, growTime = 30, income = 3,
		colors = { rgb(255, 140, 120), rgb(255, 210, 170) }, shape = "long" },
	{ id = "BonecaAmbalabu", name = "Boneca Ambalabu", rarity = "Common", cost = 60, growTime = 40, income = 4,
		colors = { rgb(70, 160, 80), rgb(40, 40, 45) }, shape = "wide" },

	-- Uncommon
	{ id = "ChimpanziniBananini", name = "Chimpanzini Bananini", rarity = "Uncommon", cost = 200, growTime = 60, income = 10,
		colors = { rgb(255, 225, 60), rgb(110, 75, 45) }, shape = "tall" },
	{ id = "BombombiniGusini", name = "Bombombini Gusini", rarity = "Uncommon", cost = 350, growTime = 75, income = 14,
		colors = { rgb(235, 235, 240), rgb(120, 125, 135) }, shape = "long" },
	{ id = "FrigoCamelo", name = "Frigo Camelo", rarity = "Uncommon", cost = 500, growTime = 90, income = 18,
		colors = { rgb(240, 245, 250), rgb(200, 160, 110) }, shape = "tall" },

	-- Rare
	{ id = "BallerinaCappuccina", name = "Ballerina Cappuccina", rarity = "Rare", cost = 1500, growTime = 120, income = 45,
		colors = { rgb(255, 180, 210), rgb(150, 100, 70) }, shape = "tall" },
	{ id = "CappuccinoAssassino", name = "Cappuccino Assassino", rarity = "Rare", cost = 2500, growTime = 150, income = 65,
		colors = { rgb(140, 95, 60), rgb(30, 30, 35) }, shape = "blob" },
	{ id = "GlorboFruttodrillo", name = "Glorbo Fruttodrillo", rarity = "Rare", cost = 4000, growTime = 180, income = 90,
		colors = { rgb(60, 170, 70), rgb(240, 70, 80) }, shape = "wide" },

	-- Epic
	{ id = "BombardiroCrocodilo", name = "Bombardiro Crocodilo", rarity = "Epic", cost = 12000, growTime = 300, income = 260,
		colors = { rgb(80, 140, 70), rgb(150, 155, 165) }, shape = "long" },
	{ id = "UdinDinDinDun", name = "Udin Din Din Dun", rarity = "Epic", cost = 20000, growTime = 360, income = 380,
		colors = { rgb(255, 150, 60), rgb(255, 230, 200) }, shape = "blob" },
	{ id = "TrulimeroTrulicina", name = "Trulimero Trulicina", rarity = "Epic", cost = 30000, growTime = 420, income = 500,
		colors = { rgb(90, 150, 230), rgb(255, 150, 80) }, shape = "wide" },

	-- Legendary
	{ id = "TungTungTungSahur", name = "Tung Tung Tung Sahur", rarity = "Legendary", cost = 100000, growTime = 600, income = 2000,
		colors = { rgb(200, 150, 95), rgb(90, 60, 35) }, shape = "tall" },
	{ id = "TraleroTralala", name = "Tralalero Tralala", rarity = "Legendary", cost = 160000, growTime = 720, income = 3200,
		colors = { rgb(90, 150, 220), rgb(240, 240, 250) }, shape = "long" },

	-- Mythic
	{ id = "LaVaccaSaturnoSaturnita", name = "La Vacca Saturno Saturnita", rarity = "Mythic", cost = 600000, growTime = 1200, income = 15000,
		colors = { rgb(245, 245, 245), rgb(230, 190, 90) }, shape = "blob" },
	{ id = "StrawberryElephant", name = "Strawberry Elephant", rarity = "Mythic", cost = 1000000, growTime = 1500, income = 25000,
		colors = { rgb(240, 60, 80), rgb(110, 200, 90) }, shape = "wide" },

	-- Secret (not sold in the shop; drops from the 67 boss in milestone 3)
	{ id = "Lil67", name = "Lil 67", rarity = "Secret", cost = 5000000, growTime = 1800, income = 120000, inShop = false,
		colors = { rgb(60, 150, 255), rgb(255, 60, 60) }, shape = "tall" },
}

Brainrots.byId = {}
for i, def in Brainrots.list do
	def.order = i
	Brainrots.byId[def.id] = def
end

return Brainrots
