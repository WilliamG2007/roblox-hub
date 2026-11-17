-- Hype text for good moments (kid-friendly meme speak), scaled by how rare it was.

local Hype = {}

local TIERS = {
	-- rarity order 3 (Rare)
	{ "NICE!", "W PULL!", "LET'S GOOO", "NOT BAD!", "OOOH" },
	-- 4 (Epic)
	{ "SHEEESH!", "W PULL!", "BUSSIN!", "HUGE W", "NO CAP!" },
	-- 5 (Legendary)
	{ "AURA +1000", "LEGENDARY W!", "SHEEEEESH!", "CERTIFIED BRAINROT", "MAX RIZZ!" },
	-- 6 (Mythic)
	{ "AURA +9999", "MYTHIC?!?!", "UNREAL!!!", "THE ULTIMATE W", "HISTORY MADE" },
	-- 7 (Secret)
	{ "SECRET?!?! NO WAY", "AURA +∞", "6 7 6 7 6 7", "SERVER SHUTDOWN W", "BRAINROT GOD" },
}

local rng = Random.new()

-- returns nil for Common/Uncommon (no hype spam on every pull)
function Hype.pick(rarityOrder: number): string?
	local tier = TIERS[rarityOrder - 2]
	if not tier then
		return nil
	end
	return tier[rng:NextInteger(1, #tier)]
end

return Hype
