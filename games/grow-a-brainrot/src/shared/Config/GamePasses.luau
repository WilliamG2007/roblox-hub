-- Gamepasses + developer products. Create each one on the Creator Dashboard
-- (your experience > Monetization > Passes / Developer Products) and paste
-- its ID here. id = 0 means "not set up yet": it's hidden from the store and
-- nobody owns it (admins can test perks with the "pass" command).

local GamePasses = {
	FastRoll = {
		id = 0,
		name = "2x Roll Speed",
		desc = "Pack reveals play twice as fast and you can skip them.",
		price = 99,
		icon = "⚡",
	},
	DoubleCash = {
		id = 0,
		name = "2x Cash",
		desc = "All your brainrots earn double, forever.",
		price = 299,
		icon = "💵",
	},
	VIP = {
		id = 0,
		name = "VIP",
		desc = "+25% income, a VIP tag and bragging rights.",
		price = 249,
		icon = "👑",
	},
	AutoCollect = {
		id = 0,
		name = "Auto-Collect",
		desc = "Cash goes straight to your wallet. No more walking to the pad.",
		price = 149,
		icon = "🧲",
	},
}

-- Developer products (buy many times). random = true means it affects random
-- results: it's hidden where paid random items are restricted (PolicyService)
-- and its effect is shown live in the pack odds.
GamePasses.Products = {
	CashSmall = { id = 0, name = "Pile of Cash", desc = "10 minutes of income (at least $1K).", price = 49, icon = "💰", incomeSeconds = 600, min = 1000 },
	CashLarge = { id = 0, name = "Mountain of Cash", desc = "1 hour of income (at least $10K).", price = 249, icon = "🏦", incomeSeconds = 3600, min = 10000 },
	LuckPotion = { id = 0, name = "Luck Potion", desc = "x2 pack luck for 15 minutes (shown in the odds).", price = 179, icon = "🧪", luck = 2, duration = 900, random = true },
	InstantRestock = { id = 0, name = "Instant Restock", desc = "Refills your pack stock right now.", price = 39, icon = "📦" },
}

return GamePasses
