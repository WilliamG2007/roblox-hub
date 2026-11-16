-- The brainrot roster. income = cash/sec at size 1 with no mutation.
-- weight = how likely it is within its rarity when a pack rolls that rarity
-- (default: earlier in the list = more common). colors/shape drive the
-- placeholder model; real art in ReplicatedStorage.Assets.Brainrots.<id> replaces it.

local Brainrots = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Brainrots.list = {
	-- Common
	{ id = "LiriliLarila", name = "Lirilì Larilà", rarity = "Common", growTime = 15, income = 1, colors = { rgb(120, 190, 90), rgb(140, 100, 70) }, shape = "tall" },
	{ id = "BrrBrrPatapim", name = "Brr Brr Patapim", rarity = "Common", growTime = 20, income = 2, colors = { rgb(130, 95, 60), rgb(90, 170, 70) }, shape = "tall" },
	{ id = "TrippiTroppi", name = "Trippi Troppi", rarity = "Common", growTime = 25, income = 3, colors = { rgb(255, 140, 120), rgb(255, 210, 170) }, shape = "long" },
	{ id = "BonecaAmbalabu", name = "Boneca Ambalabu", rarity = "Common", growTime = 30, income = 4, colors = { rgb(70, 160, 80), rgb(40, 40, 45) }, shape = "wide" },

	-- Uncommon
	{ id = "ChimpanziniBananini", name = "Chimpanzini Bananini", rarity = "Uncommon", growTime = 40, income = 10, colors = { rgb(255, 225, 60), rgb(110, 75, 45) }, shape = "tall" },
	{ id = "BombombiniGusini", name = "Bombombini Gusini", rarity = "Uncommon", growTime = 45, income = 13, colors = { rgb(235, 235, 240), rgb(120, 125, 135) }, shape = "long" },
	{ id = "TaTaTaTaSahur", name = "Ta Ta Ta Ta Sahur", rarity = "Uncommon", growTime = 50, income = 15, colors = { rgb(190, 140, 90), rgb(240, 240, 240) }, shape = "tall" },
	{ id = "FrigoCamelo", name = "Frigo Camelo", rarity = "Uncommon", growTime = 60, income = 18, colors = { rgb(240, 245, 250), rgb(200, 160, 110) }, shape = "tall" },

	-- Rare
	{ id = "BallerinaCappuccina", name = "Ballerina Cappuccina", rarity = "Rare", growTime = 75, income = 45, colors = { rgb(255, 180, 210), rgb(150, 100, 70) }, shape = "tall" },
	{ id = "CappuccinoAssassino", name = "Cappuccino Assassino", rarity = "Rare", growTime = 90, income = 60, colors = { rgb(140, 95, 60), rgb(30, 30, 35) }, shape = "blob" },
	{ id = "BobritoBandito", name = "Bobrito Bandito", rarity = "Rare", growTime = 100, income = 70, colors = { rgb(150, 110, 70), rgb(60, 60, 70) }, shape = "wide" },
	{ id = "GlorboFruttodrillo", name = "Glorbo Fruttodrillo", rarity = "Rare", growTime = 120, income = 85, colors = { rgb(60, 170, 70), rgb(240, 70, 80) }, shape = "wide" },

	-- Epic
	{ id = "BombardiroCrocodilo", name = "Bombardiro Crocodilo", rarity = "Epic", growTime = 150, income = 280, colors = { rgb(80, 140, 70), rgb(150, 155, 165) }, shape = "long" },
	{ id = "UdinDinDinDun", name = "Udin Din Din Dun", rarity = "Epic", growTime = 170, income = 350, colors = { rgb(255, 150, 60), rgb(255, 230, 200) }, shape = "blob" },
	{ id = "TricTracBaraboom", name = "Tric Trac Baraboom", rarity = "Epic", growTime = 190, income = 420, colors = { rgb(200, 60, 60), rgb(250, 220, 80) }, shape = "wide" },
	{ id = "OrangutiniAnanassini", name = "Orangutini Ananassini", rarity = "Epic", growTime = 210, income = 480, colors = { rgb(230, 130, 40), rgb(250, 210, 60) }, shape = "tall" },
	{ id = "TrulimeroTrulicina", name = "Trulimero Trulicina", rarity = "Epic", growTime = 240, income = 550, colors = { rgb(90, 150, 230), rgb(255, 150, 80) }, shape = "wide" },

	-- Legendary
	{ id = "TungTungTungSahur", name = "Tung Tung Tung Sahur", rarity = "Legendary", growTime = 300, income = 2000, colors = { rgb(200, 150, 95), rgb(90, 60, 35) }, shape = "tall" },
	{ id = "BrriBrriBicusDicusBombicus", name = "Brri Brri Bicus Dicus Bombicus", rarity = "Legendary", growTime = 330, income = 2600, colors = { rgb(130, 200, 90), rgb(200, 60, 60) }, shape = "blob" },
	{ id = "CocofantoElefanto", name = "Cocofanto Elefanto", rarity = "Legendary", growTime = 360, income = 2900, colors = { rgb(150, 110, 70), rgb(180, 180, 190) }, shape = "wide" },
	{ id = "TraleroTralala", name = "Tralalero Tralala", rarity = "Legendary", growTime = 400, income = 3500, colors = { rgb(90, 150, 220), rgb(240, 240, 250) }, shape = "long" },

	-- Mythic
	{ id = "LaVaccaSaturnoSaturnita", name = "La Vacca Saturno Saturnita", rarity = "Mythic", growTime = 600, income = 15000, colors = { rgb(245, 245, 245), rgb(230, 190, 90) }, shape = "blob" },
	{ id = "GraipussiMedussi", name = "Graipussi Medussi", rarity = "Mythic", growTime = 700, income = 19000, colors = { rgb(140, 60, 170), rgb(120, 220, 120) }, shape = "blob" },
	{ id = "StrawberryElephant", name = "Strawberry Elephant", rarity = "Mythic", growTime = 800, income = 25000, colors = { rgb(240, 60, 80), rgb(110, 200, 90) }, shape = "wide" },

	-- Secret
	{ id = "LosTralaleritos", name = "Los Tralaleritos", rarity = "Secret", growTime = 1000, income = 100000, colors = { rgb(70, 130, 220), rgb(240, 240, 250) }, shape = "long" },
	{ id = "PotHotspot", name = "Pot Hotspot", rarity = "Secret", growTime = 1100, income = 140000, colors = { rgb(60, 60, 70), rgb(80, 220, 255) }, shape = "blob" },
	{ id = "Lil67", name = "Lil 67", rarity = "Secret", growTime = 1200, income = 200000, colors = { rgb(60, 150, 255), rgb(255, 60, 60) }, shape = "tall" },
}

Brainrots.byId = {}
Brainrots.byRarity = {}
for i, def in Brainrots.list do
	def.order = i
	Brainrots.byId[def.id] = def
	Brainrots.byRarity[def.rarity] = Brainrots.byRarity[def.rarity] or {}
	table.insert(Brainrots.byRarity[def.rarity], def)
end
for _, group in Brainrots.byRarity do
	for position, def in group do
		def.weight = def.weight or (#group - position + 1)
	end
end

return Brainrots
