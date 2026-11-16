-- Cash in and out. Every change to a player's cash goes through here.

local EconomyService = {}

local services

function EconomyService.init(s)
	services = s
end

function EconomyService.getCash(player): number
	local data = services.DataService.get(player)
	return if data then data.cash else 0
end

function EconomyService.add(player, amount: number)
	local data = services.DataService.get(player)
	if not data or amount <= 0 or amount ~= amount then
		return
	end
	data.cash += amount
	data.stats.earned += amount
	services.SyncService.mark(player)
end

function EconomyService.spend(player, amount: number): boolean
	local data = services.DataService.get(player)
	if not data or amount < 0 or data.cash < amount then
		return false
	end
	data.cash -= amount
	services.SyncService.mark(player)
	return true
end

return EconomyService
