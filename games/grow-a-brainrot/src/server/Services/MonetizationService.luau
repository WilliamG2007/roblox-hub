-- Gamepass ownership. Owned passes are exposed as player attributes
-- ("Pass_FastRoll" = true) so the client can apply perks; anything that
-- matters for the economy must still be checked on the server via owns().

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePasses = require(ReplicatedStorage.Shared.Config.GamePasses)

local MonetizationService = {}

local function attribute(name)
	return "Pass_" .. name
end

function MonetizationService.owns(player, name: string): boolean
	return player:GetAttribute(attribute(name)) == true
end

-- admin/testing override
function MonetizationService.setOwned(player, name: string, owned: boolean)
	player:SetAttribute(attribute(name), owned)
end

local function check(player)
	for name, pass in GamePasses do
		if pass.id ~= 0 then
			local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok and owned then
				player:SetAttribute(attribute(name), true)
			end
		end
	end
end

function MonetizationService.start()
	Players.PlayerAdded:Connect(check)
	for _, player in Players:GetPlayers() do
		task.spawn(check, player)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for name, pass in GamePasses do
			if pass.id == passId then
				player:SetAttribute(attribute(name), true)
			end
		end
	end)
end

return MonetizationService
