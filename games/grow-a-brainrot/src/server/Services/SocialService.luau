-- Friend boost: if any of your Roblox friends is in the same server you get
-- +10% income and +25% Moon Shards (player attribute "FriendBoost").

local Players = game:GetService("Players")

local SocialService = {}

local cache = {} -- ["a:b"] = boolean

local function areFriends(a, b)
	local key = if a.UserId < b.UserId then a.UserId .. ":" .. b.UserId else b.UserId .. ":" .. a.UserId
	if cache[key] == nil then
		local ok, result = pcall(a.IsFriendsWith, a, b.UserId)
		cache[key] = ok and result == true
	end
	return cache[key]
end

local function recompute()
	local players = Players:GetPlayers()
	for _, player in players do
		local boosted = false
		for _, other in players do
			if other ~= player and areFriends(player, other) then
				boosted = true
				break
			end
		end
		player:SetAttribute("FriendBoost", boosted)
	end
end

function SocialService.start()
	Players.PlayerAdded:Connect(function()
		task.defer(recompute)
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(recompute)
	end)
	recompute()
end

return SocialService
