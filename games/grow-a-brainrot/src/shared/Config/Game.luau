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

	-- extra admin UserIds (the game's creator is always admin; everyone is admin in Studio)
	Admins = {},

	-- saving
	AutosaveInterval = 60,
}
