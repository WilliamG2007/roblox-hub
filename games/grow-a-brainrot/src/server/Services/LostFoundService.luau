-- Lost & Found booth: brainrots that monsters escaped with can be bought back
-- (cheapest first, as many as you can afford). They come back as seeds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Mutations = require(Shared.Config.Mutations)
local Seeds = require(Shared.Seeds)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local LostFoundService = {}

local services
local fx

local function priceOf(entry)
	local def = Brainrots.byId[entry.id]
	local mutation = Mutations.byId[entry.mutation] or Mutations.byId.Normal
	return if def then math.floor(def.income * mutation.mult * GameConfig.Night.LostFoundSeconds) else 0
end

function LostFoundService.recover(player)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	if #data.lostFound == 0 then
		fx:FireClient(player, "Toast", "Nothing lost! Your brainrots are all safe.", Color3.fromRGB(150, 255, 150))
		return
	end
	table.sort(data.lostFound, function(a, b)
		return priceOf(a) < priceOf(b)
	end)
	local recovered, spent = 0, 0
	while #data.lostFound > 0 do
		local entry = data.lostFound[1]
		local price = priceOf(entry)
		if not services.EconomyService.spend(player, price) then
			break
		end
		table.remove(data.lostFound, 1)
		if Brainrots.byId[entry.id] then
			local key = Seeds.key(entry.id, entry.mutation)
			data.seeds[key] = (data.seeds[key] or 0) + 1
		end
		recovered += 1
		spent += price
	end
	services.SyncService.mark(player)
	if recovered > 0 then
		fx:FireClient(player, "Toast", string.format("Recovered %d brainrot%s for %s! They're back in your seeds.", recovered, if recovered == 1 then "" else "s", Format.cash(spent)), Color3.fromRGB(150, 255, 150))
	end
	if #data.lostFound > 0 then
		fx:FireClient(player, "Toast", string.format("%d more waiting. Next one costs %s.", #data.lostFound, Format.cash(priceOf(data.lostFound[1]))), Color3.fromRGB(255, 200, 120))
	end
end

function LostFoundService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function LostFoundService.start()
	services.MapService.LostFoundPrompt.Triggered:Connect(LostFoundService.recover)
end

return LostFoundService
