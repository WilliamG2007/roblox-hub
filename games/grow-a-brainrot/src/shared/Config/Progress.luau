-- Onboarding tutorial, daily login streak, daily quests, Index rewards.
-- Cash rewards scale with your income so they stay meaningful:
--   { incomeSeconds = N, min = M } = max(M, your income/sec * N)

local Progress = {}

-- First-session guide. Each step completes on a tracked event.
Progress.Tutorial = {
	{ id = "claim", text = "Claim an empty garden", hint = "Walk to a garden with a CLAIM ME! sign", event = "claim", goal = 1, reward = { cash = { incomeSeconds = 0, min = 50 } } },
	{ id = "shop", text = "Open a pack at the Pack Shop", hint = "Click SHOP and open a Basic Bag", event = "packOpened", goal = 1, reward = { cash = { incomeSeconds = 0, min = 60 } } },
	{ id = "plant", text = "Plant a seed in your garden", hint = "Pick the seed in your hotbar, then click a dirt tile", event = "planted", goal = 1, reward = { cash = { incomeSeconds = 0, min = 60 } } },
	{ id = "grow", text = "Wait for your brainrot to POP", hint = "Watch the progress bar", event = "grown", goal = 1, reward = { cash = { incomeSeconds = 0, min = 100 } } },
	{ id = "collect", text = "Collect your cash", hint = "Step on the glowing green pad", event = "collected", goal = 1, reward = { cash = { incomeSeconds = 0, min = 150 }, pack = "RizzPack" } },
}

-- 7-day login streak (loops after day 7; missing a day resets to day 1)
Progress.LoginRewards = {
	{ label = "Cash", cash = { incomeSeconds = 60, min = 150 } },
	{ label = "More cash", cash = { incomeSeconds = 120, min = 300 } },
	{ label = "Moon Shards", shards = 15 },
	{ label = "Big cash", cash = { incomeSeconds = 240, min = 800 } },
	{ label = "2x Rizz Pack", pack = "RizzPack", packCount = 2 },
	{ label = "Huge cash", cash = { incomeSeconds = 480, min = 2000 } },
	{ label = "Sigma Pack + Shards", pack = "SigmaPack", packCount = 1, shards = 30 },
}

-- Daily quests: 3 are picked per player per day from this pool.
Progress.QuestPool = {
	{ id = "packs", text = "Open %d packs", event = "packOpened", goal = 5, reward = { cash = { incomeSeconds = 150, min = 300 } } },
	{ id = "plant", text = "Plant %d seeds", event = "planted", goal = 6, reward = { cash = { incomeSeconds = 120, min = 250 } } },
	{ id = "rare", text = "Grow %d Rare or better brainrot", event = "grownRare", goal = 1, reward = { cash = { incomeSeconds = 200, min = 500 } } },
	{ id = "collect", text = "Collect cash %d times", event = "collected", goal = 10, reward = { cash = { incomeSeconds = 120, min = 250 } } },
	{ id = "bonk", text = "Defeat %d night monsters", event = "monsterKilled", goal = 8, reward = { shards = 20 } },
	{ id = "sell", text = "Sell %d seeds or brainrots", event = "sold", goal = 3, reward = { cash = { incomeSeconds = 90, min = 200 } } },
	{ id = "wild", text = "Catch %d wild brainrot", event = "wildCaught", goal = 1, reward = { pack = "SigmaPack", packCount = 1 } },
	{ id = "mutation", text = "Pull %d mutated seed", event = "mutatedPull", goal = 1, reward = { cash = { incomeSeconds = 180, min = 400 } } },
}
Progress.QuestsPerDay = 3

-- Index: completing a rarity row (growing every brainrot of that rarity) can be
-- claimed for a permanent income bonus.
Progress.IndexBonusPerRarity = 0.05

return Progress
