-- Global tuning knobs. Change balance here, not in services.

return {
	StartingCash = 50,
	StarterSeeds = { LiriliLarila = 2 },

	-- garden plots
	MaxPlots = 8,
	PlotCols = 3,
	PlotRows = 4,
	TileSize = 8,

	-- seed shop
	RestockInterval = 300, -- seconds, synced across all servers

	-- grown brainrots
	SizeMin = 0.8,
	SizeMax = 2.5,
	SizeCurve = 3, -- higher = big ones are rarer
	SellMultiplier = 0.5, -- sell value = seed cost * this * size (+ uncollected cash)

	-- offline earnings
	OfflineEarnRate = 0.5,
	OfflineCapSeconds = 8 * 3600,

	-- saving
	AutosaveInterval = 60,
}
