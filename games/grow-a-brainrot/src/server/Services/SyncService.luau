-- Sends each player a snapshot of their state. Services call mark(player)
-- whenever something changes; snapshots go out at most 5x per second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Format = require(ReplicatedStorage.Shared.Format)

local SyncService = {}

local services
local stateRemote
local dirty = {}

function SyncService.init(s)
	services = s
	stateRemote = Remotes.get("State")
end

function SyncService.mark(player)
	dirty[player] = true
end

local function send(player)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	stateRemote:FireClient(player, {
		cash = data.cash,
		income = services.GardenService.getIncome(player),
		seeds = data.seeds,
		shop = services.ShopService.snapshot(player),
		plotIndex = services.PlotService.getPlotIndex(player),
		discovered = data.index,
		canSave = services.DataService.canSave(player),
	})
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = Format.cash(data.cash)
	end
end

function SyncService.start()
	task.spawn(function()
		local sinceFull = 0
		while true do
			task.wait(0.2)
			sinceFull += 0.2
			local full = sinceFull >= 2
			if full then
				sinceFull = 0
			end
			for _, player in Players:GetPlayers() do
				if full or dirty[player] then
					dirty[player] = nil
					send(player)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		dirty[player] = nil
	end)
end

return SyncService
