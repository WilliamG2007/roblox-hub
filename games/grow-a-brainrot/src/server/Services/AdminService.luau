-- Admin commands for live "admin abuse" events and testing. One parser serves
-- both chat ("/luck 5 60") and the admin panel ("luck 5 60"). The command list
-- with usage text lives in shared/AdminCommands.
-- Admins: the game's creator, anyone in GameConfig.Admins, and everyone in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local Packs = require(Shared.Config.Packs)
local Brainrots = require(Shared.Config.Brainrots)
local Mutations = require(Shared.Config.Mutations)
local AdminCommands = require(Shared.AdminCommands)
local Seeds = require(Shared.Seeds)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local AdminService = {}

local services
local fx
local handlers = {}

local GOOD = Color3.fromRGB(150, 255, 150)
local BAD = Color3.fromRGB(255, 120, 120)

local function isAdmin(player)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(GameConfig.Admins, player.UserId) ~= nil
end

local function reply(admin, text, color)
	fx:FireClient(admin, "Toast", text, color or GOOD)
end

-- "me" (default), "all", or the start of a name / display name
local function targets(admin, query)
	if not query or query == "" or string.lower(query) == "me" then
		return { admin }
	end
	query = string.lower(query)
	if query == "all" or query == "everyone" then
		return Players:GetPlayers()
	end
	for _, player in Players:GetPlayers() do
		if string.sub(string.lower(player.Name), 1, #query) == query or string.sub(string.lower(player.DisplayName), 1, #query) == query then
			return { player }
		end
	end
	error("no player matching '" .. query .. "'")
end

local function findIn(list, query, fields)
	local n = tonumber(query)
	if n then
		return list[math.clamp(math.floor(n), 1, #list)]
	end
	query = string.lower((query or ""):gsub("[%s_%-]", ""))
	for _, item in list do
		for _, field in fields do
			local value = string.lower((item[field]:gsub("[%s_%-]", "")))
			if value == query then
				return item
			end
		end
	end
	for _, item in list do
		for _, field in fields do
			if string.find(string.lower((item[field]:gsub("[%s_%-]", ""))), query, 1, true) then
				return item
			end
		end
	end
	return nil
end

local function num(value, default)
	return tonumber(value) or default
end

--------------------------------------------------------------------------------
-- Commands

function handlers.help(admin)
	local names = {}
	for _, cmd in AdminCommands do
		table.insert(names, cmd.name)
	end
	reply(admin, "Commands: " .. table.concat(names, ", ") .. "  (open the ADMIN panel for details)")
end

function handlers.luck(_, args)
	local mult, seconds = num(args[1], 3), num(args[2], 60)
	services.LuckService.startEvent("ADMIN LUCK x" .. mult, mult, 1, seconds)
end

function handlers.mutluck(_, args)
	local mult, seconds = num(args[1], 6.7), num(args[2], 67)
	services.LuckService.startEvent("ADMIN MUTATIONS x" .. mult, 1, mult, seconds)
end

function handlers.event(_, args)
	local luck, mutationLuck, seconds = num(args[1], 2), num(args[2], 2), num(args[3], 60)
	local name = table.concat(args, " ", 4)
	services.LuckService.startEvent(if name ~= "" then string.upper(name) else "ADMIN EVENT", luck, mutationLuck, seconds)
end

function handlers.endevent(admin)
	services.LuckService.endEvent()
	reply(admin, "Luck event ended.")
end

function handlers.givepack(admin, args)
	local pack = findIn(Packs.list, args[1] or "1", { "id", "name" })
	assert(pack, "unknown pack '" .. tostring(args[1]) .. "'")
	local count = math.clamp(math.floor(num(args[2], 1)), 1, GameConfig.MaxOpenAtOnce)
	local list = targets(admin, args[3] or "all")
	if #list > 1 then
		fx:FireAllClients("Announce", string.format("ADMIN ABUSE! Everyone gets %dx %s!", count, pack.name), pack.color)
	end
	for _, player in list do
		services.ShopService.openPacks(player, pack, count)
	end
end

function handlers.seed(admin, args)
	local def = findIn(Brainrots.list, args[1], { "id", "name" })
	assert(def, "unknown brainrot '" .. tostring(args[1]) .. "'")
	local mutation = findIn(Mutations.list, args[2] or "Normal", { "id", "name" })
	assert(mutation, "unknown mutation '" .. tostring(args[2]) .. "'")
	local count = math.clamp(math.floor(num(args[3], 1)), 1, 100)
	for _, player in targets(admin, args[4]) do
		local data = services.DataService.get(player)
		if data then
			local key = Seeds.key(def.id, mutation.id)
			data.seeds[key] = (data.seeds[key] or 0) + count
			services.SyncService.mark(player)
		end
	end
	reply(admin, string.format("Gave %dx %s %s seed", count, mutation.name, def.name))
end

function handlers.cash(admin, args)
	local amount = num(args[1], 1e6)
	for _, player in targets(admin, args[2]) do
		services.EconomyService.add(player, amount)
	end
	reply(admin, "+" .. Format.cash(amount))
end

function handlers.setcash(admin, args)
	local amount = math.max(0, num(args[1], 0))
	for _, player in targets(admin, args[2]) do
		local data = services.DataService.get(player)
		if data then
			data.cash = amount
			services.SyncService.mark(player)
		end
	end
	reply(admin, "Cash set to " .. Format.cash(amount))
end

function handlers.wander(_, args)
	local free = args[3] ~= nil and string.lower(args[3]) == "free"
	if not args[1] or string.lower(args[1]) == "random" then
		services.WanderService.spawn(nil, nil, if free then true else nil)
		return
	end
	local def = findIn(Brainrots.list, args[1], { "id", "name" })
	assert(def, "unknown brainrot '" .. tostring(args[1]) .. "'")
	local mutation = findIn(Mutations.list, args[2] or "Normal", { "id", "name" })
	assert(mutation, "unknown mutation '" .. tostring(args[2]) .. "'")
	services.WanderService.spawn(def.id, mutation.id, free)
end

function handlers.restock()
	services.ShopService.forceRestock()
end

function handlers.stock(admin, args)
	local pack = findIn(Packs.list, args[1] or "1", { "id", "name" })
	assert(pack, "unknown pack '" .. tostring(args[1]) .. "'")
	local qty = math.clamp(math.floor(num(args[2], 5)), 1, 100)
	services.ShopService.addToStock(pack.id, qty)
	reply(admin, string.format("Added %dx %s to the shop", qty, pack.name))
end

function handlers.grow(admin, args)
	for _, player in targets(admin, args[1]) do
		services.GardenService.finishGrowing(player)
	end
end

function handlers.clear(admin, args)
	for _, player in targets(admin, args[1]) do
		services.GardenService.clearGarden(player)
	end
	reply(admin, "Garden cleared.")
end

function handlers.reset(admin, args)
	assert(args[1], "say who: reset me / reset <name>")
	for _, player in targets(admin, args[1]) do
		local plot = services.PlotService.getPlot(player)
		services.GardenService.unloadPlayer(player)
		local data = services.DataService.reset(player)
		if data and plot then
			services.GardenService.loadPlayer(player, data, plot)
		end
		services.SyncService.mark(player)
		reply(player, "Your save was reset by an admin.", BAD)
	end
end

function handlers.announce(_, args)
	local text = table.concat(args, " ")
	assert(text ~= "", "nothing to announce")
	fx:FireAllClients("Announce", text, Color3.fromRGB(255, 220, 80))
end

function handlers.speed(admin, args)
	local speed = math.clamp(num(args[1], 16), 0, 200)
	for _, player in targets(admin, args[2]) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speed
		end
	end
end

function handlers.tp(admin, args)
	local target = targets(admin, args[1])[1]
	local plot = services.PlotService.getPlot(target)
	if plot and admin.Character then
		admin.Character:PivotTo(plot:GetAttribute("Spawn"))
	end
end

--------------------------------------------------------------------------------

function AdminService.run(admin, text: string)
	if not isAdmin(admin) or type(text) ~= "string" then
		return
	end
	text = string.gsub(text, "^%s*/?", "")
	local args = string.split(text, " ")
	for i = #args, 1, -1 do
		if args[i] == "" then
			table.remove(args, i)
		end
	end
	local name = string.lower(table.remove(args, 1) or "")
	if not handlers[name] and string.sub(name, 1, 1) == "a" and handlers[string.sub(name, 2)] then
		name = string.sub(name, 2) -- "/ahelp" -> help (chat aliases for names Roblox reserves)
	end
	local handler = handlers[name]
	if not handler then
		reply(admin, "Unknown command '" .. name .. "'. Try: help", BAD)
		return
	end
	local ok, err = pcall(handler, admin, args)
	if not ok then
		reply(admin, "Command failed: " .. tostring(err):gsub("^.-:%d+: ", ""), BAD)
	end
end

function AdminService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function AdminService.start()
	-- chat: one TextChatCommand per command name
	-- Roblox already uses some names (/help, /clear...), so those get an "a" prefix in chat
	local RESERVED = { help = true, clear = true, mute = true, unmute = true, team = true, whisper = true, console = true, emote = true }
	local container = TextChatService:FindFirstChild("TextChatCommands") or TextChatService
	for _, cmd in AdminCommands do
		local command = Instance.new("TextChatCommand")
		command.Name = "Admin_" .. cmd.name
		command.PrimaryAlias = "/" .. (if RESERVED[cmd.name] then "a" .. cmd.name else cmd.name)
		command.Parent = container
		command.Triggered:Connect(function(source, text)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				AdminService.run(player, text)
			end
		end)
	end

	-- admin panel
	Remotes.get("Admin").OnServerEvent:Connect(AdminService.run)

	local function mark(player)
		player:SetAttribute("IsAdmin", isAdmin(player))
	end
	Players.PlayerAdded:Connect(mark)
	for _, player in Players:GetPlayers() do
		mark(player)
	end
end

return AdminService
