-- Global tuning knobs. Change balance here, not in services.

return {
	StartingCash = 50,
	StarterSeeds = { ["LiriliLarila|Normal"] = 2 },

	-- garden plots
	MaxPlots = 8,
	PlotCols = 3,
	PlotRows = 4,
	TileSize = 8,

	-- pack shop
	RestockInterval = 300, -- seconds, synced across all servers
	MaxOpenAtOnce = 10,

	-- grown brainrots
	SizeMin = 0.8,
	SizeMax = 2.5,
	SizeCurve = 3, -- higher = big ones are rarer
	SellIncomeSeconds = 40, -- sell value = this many seconds of its income (+ uncollected cash)
	SeedSellSeconds = 10, -- selling a seed from the backpack = this many seconds of its income
	AutoSellRarities = { "Common", "Uncommon", "Rare", "Epic" }, -- rarities players can auto-sell (Normal seeds only)

	-- pack reveal animation (the 2x Roll Speed gamepass halves these and allows skipping)
	Reveal = {
		ReelSeconds = 5,
		MutationSeconds = 2.6,
		FlipSeconds = 0.35,
	},

	-- day / night
	Night = {
		DaySeconds = 360,
		NightSeconds = 150,
		BossEvery = 3, -- every Nth night is a 67 NIGHT
		WaveEvery = 20, -- seconds between monster waves
		WaveSize = { base = 2, perPlayer = 1, max = 8 },
		MaxMonsters = 24,
		HpGrowthPerNight = 0.15, -- monsters get tougher each night (resets... never, it's per server)
		LostFoundSeconds = 30, -- buying back a stolen brainrot costs this many seconds of its income
	},
	Grumbler = { hp = 120, speed = 9, shards = { 1, 3 } },
	Boss67 = { hp = 2500, hpPerPlayer = 1200, speed = 6, shards = 30, lil67Chance = 0.15, stompEvery = 8 },
	Spoon = { damage = 30, range = 11, cooldown = 0.4 },
	-- brainrot defense damage per second by rarity (x mutation bonus)
	Power = { Common = 6, Uncommon = 10, Rare = 15, Epic = 22, Legendary = 34, Mythic = 50, Secret = 75 },
	DefenseRange = 18,

	-- offline earnings
	OfflineEarnRate = 0.5,
	OfflineCapSeconds = 8 * 3600,

	-- server luck events (random, server-wide)
	LuckEvents = {
		MinInterval = 900,
		MaxInterval = 1500,
		List = {
			{ name = "LUCK STORM", luck = 2, mutationLuck = 1, duration = 120 },
			{ name = "67 SECONDS OF CHAOS", luck = 1, mutationLuck = 6.7, duration = 67 },
			{ name = "BRAINROT FRENZY", luck = 3, mutationLuck = 2, duration = 60 },
		},
	},

	-- wild brainrots walking the road around the plaza; first to buy/grab wins
	Wanderers = {
		MinInterval = 150,
		MaxInterval = 300,
		MaxActive = 2,
		Speed = 7, -- studs per second
		Scale = 1.6, -- bigger than garden brainrots so they stand out
		PriceIncomeSeconds = 90, -- price = this many seconds of its income
		mutationLuck = 3,
		rarities = { { "Epic", 55 }, { "Legendary", 35 }, { "Mythic", 9 }, { "Secret", 1 } },
		FreeChance = 0.2, -- sometimes one is free: pure race
		freeRarities = { { "Rare", 60 }, { "Epic", 40 } },
	},

	-- extra admin UserIds (the game's creator is always admin; everyone is admin in Studio)
	Admins = {},

	-- saving
	AutosaveInterval = 60,
}
