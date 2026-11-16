-- Admin chat commands for live "admin abuse" events and testing.
-- Admins: the game's creator, anyone in GameConfig.Admins, and everyone in Studio.
--   /luck [mult] [seconds]         server luck event (default x3 for 60s)
--   /mutluck [mult] [seconds]      mutation luck event (default x6.7 for 67s)
--   /givepack [pack] [count]       gives EVERY player free packs (pack = number 1-10 or name)
--   /restock                       instant shop restock
--   /cash [amount]                 gives yourself cash (testing)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Packs = require(ReplicatedStorage.Shared.Config.Packs)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local AdminService = {}

local services
local fx

local function isAdmin(player)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(GameConfig.Admins, player.UserId) ~= nil
end

local function findPack(query)
	if not query then
		return Packs.list[1]
	end
	local n = tonumber(query)
	if n then
		return Packs.list[math.clamp(math.floor(n), 1, #Packs.list)]
	end
	query = string.lower(query)
	for _, pack in Packs.list do
		if string.find(string.lower(pack.id), query, 1, true) or string.find(string.lower(pack.name), query, 1, true) then
			return pack
		end
	end
	return nil
end

local function command(name, alias, handler)
	local container = TextChatService:FindFirstChild("TextChatCommands") or TextChatService
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "Admin_" .. name
	cmd.PrimaryAlias = alias
	cmd.Parent = container
	cmd.Triggered:Connect(function(source, text)
		local player = Players:GetPlayerByUserId(source.UserId)
		if not player or not isAdmin(player) then
			return
		end
		local args = string.split(text, " ")
		table.remove(args, 1)
		local ok, err = pcall(handler, player, args)
		if not ok then
			fx:FireClient(player, "Toast", "Command failed: " .. tostring(err), Color3.fromRGB(255, 120, 120))
		end
	end)
end

function AdminService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function AdminService.start()
	command("Luck", "/luck", function(_, args)
		local mult = tonumber(args[1]) or 3
		local seconds = tonumber(args[2]) or 60
		services.LuckService.startEvent("ADMIN LUCK x" .. mult, mult, 1, seconds)
	end)

	command("MutationLuck", "/mutluck", function(_, args)
		local mult = tonumber(args[1]) or 6.7
		local seconds = tonumber(args[2]) or 67
		services.LuckService.startEvent("ADMIN MUTATIONS x" .. mult, 1, mult, seconds)
	end)

	command("GivePack", "/givepack", function(admin, args)
		local pack = findPack(args[1])
		if not pack then
			fx:FireClient(admin, "Toast", "Unknown pack: " .. tostring(args[1]), Color3.fromRGB(255, 120, 120))
			return
		end
		local count = math.clamp(math.floor(tonumber(args[2]) or 1), 1, GameConfig.MaxOpenAtOnce)
		fx:FireAllClients("Announce", string.format("ADMIN ABUSE! Everyone gets %dx %s!", count, pack.name), pack.color)
		for _, player in Players:GetPlayers() do
			services.ShopService.openPacks(player, pack, count)
		end
	end)

	command("Restock", "/restock", function()
		services.ShopService.forceRestock()
	end)

	command("Cash", "/cash", function(admin, args)
		local amount = tonumber(args[1]) or 1e6
		services.EconomyService.add(admin, amount)
		fx:FireClient(admin, "Toast", "Admin: +" .. Format.cash(amount), Color3.fromRGB(150, 255, 150))
	end)
end

return AdminService
