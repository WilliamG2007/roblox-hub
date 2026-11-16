-- Server entry point: wires services together and handles players joining/leaving.
-- Each service is a module in ./Services with optional init(services) and start().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
Remotes.setup()

-- order matters: init runs top to bottom, then start runs top to bottom
local ORDER = { "DataService", "MapService", "EconomyService", "SyncService", "PlotService", "ShopService", "GardenService" }

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

	local plot = services.PlotService.claim(player)
	services.GardenService.loadPlayer(player, data, plot)
	services.SyncService.mark(player)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.1)
		services.PlotService.sendHome(player)
	end)
	if player.Character then
		services.PlotService.sendHome(player)
	end

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
