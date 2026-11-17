-- Thin wrapper over Roblox's AnalyticsService (Creator Dashboard > Analytics).
-- Funnels show where new players drop off; economy events show where cash
-- comes from and goes. Failures never affect gameplay.

local Analytics = game:GetService("AnalyticsService")

local AnalyticsService = {}

function AnalyticsService.funnel(player, step: number, name: string)
	pcall(Analytics.LogOnboardingFunnelStepEvent, Analytics, player, step, name)
end

-- flow: "Source" (earned) or "Sink" (spent); txType: "Shop", "Gameplay", "IAP", "TimedReward", "Onboarding"
function AnalyticsService.economy(player, flow: string, currency: string, amount: number, balance: number, txType: string, sku: string?)
	if amount <= 0 or amount ~= amount or amount == math.huge then
		return
	end
	pcall(function()
		Analytics:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType[flow],
			currency,
			math.floor(amount),
			math.floor(math.min(balance, 2 ^ 52)),
			Enum.AnalyticsEconomyTransactionType[txType].Name,
			sku
		)
	end)
end

function AnalyticsService.event(player, name: string, value: number?)
	pcall(Analytics.LogCustomEvent, Analytics, player, name, value or 1)
end

return AnalyticsService
