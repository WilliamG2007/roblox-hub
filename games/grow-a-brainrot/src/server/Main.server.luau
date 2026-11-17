-- Server entry point: wires services together and handles players joining/leaving.
-- Each service is a module in ./Services with optional init(services) and start().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
Remotes.setup()

-- order matters: init runs top to bottom, then start runs top to bottom
local ORDER = {
	"DataService", "MapService", "EconomyService", "SyncService", "PlotService", "MonetizationService",
	"LuckService", "FameService", "InventoryService", "ShopService", "GardenService", "WanderService",
	"DayNightService", "MonsterService", "LostFoundService", "AdminService",
}

local services = {}
for _, name in ORDER do
	services[name] = require(script.Parent.Services[name])
end
for _, name in ORDER do
	if services[name].init then
		services[name].init(services)
	end
end
for _, name in ORDER do
	if services[name].start then
		services[name].start()
	end
end

local fx = Remotes.get("Fx")

services.PlotService.Claimed:Connect(function(player, plot)
	services.GardenService.loadPlayer(player, services.DataService.get(player), plot)
	services.SyncService.mark(player)
	fx:FireClient(player, "Toast", "This garden is yours! Open the PACK SHOP to get seeds.", Color3.fromRGB(150, 255, 150))
	fx:FireClient(player, "Celebrate", plot:GetPivot().Position, Color3.fromRGB(255, 215, 80))
end)

local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "$0"
	cash.Parent = leaderstats
	leaderstats.Parent = player

	local data, canSave = services.DataService.load(player)
	if not player.Parent then
		services.DataService.release(player)
		return
	end

	-- no auto-assign: the player walks to an empty garden and claims it
	services.SyncService.mark(player)
	task.delay(2, function()
		if not player.Parent or services.PlotService.getPlot(player) then
			return
		end
		if services.PlotService.hasFreePlot() then
			fx:FireClient(player, "Toast", "Pick a garden! Walk up to any empty plot and claim it.", Color3.fromRGB(255, 215, 80))
		else
			fx:FireClient(player, "Toast", "All gardens are taken in this server! Try another server.", Color3.fromRGB(255, 120, 120))
		end
	end)

	-- after respawning, go back to your own garden (once you have one)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.1)
		services.PlotService.sendHome(player)
	end)

	if not canSave then
		task.delay(4, function()
			fx:FireClient(player, "Toast", "Saving is OFF right now (in Studio: Game Settings > Security > enable API access).", Color3.fromRGB(255, 170, 90))
		end)
	end
end

local function onPlayerRemoving(player)
	services.GardenService.unloadPlayer(player)
	services.PlotService.release(player)
	services.DataService.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
