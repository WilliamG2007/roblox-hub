-- Global leaderboards (OrderedDataStore) shown on boards in the world:
--   Richest   total cash ever earned (stored as a scaled log so huge numbers fit)
--   Collectors  how many different brainrots discovered
-- Boards are added to the map at runtime if the baked map doesn't have them.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(ReplicatedStorage.Shared.Style)
local Format = require(ReplicatedStorage.Shared.Format)

local LeaderboardService = {}

local P = Style.Palette
local services
local BOARDS = {
	{ key = "Richest", title = "💰 RICHEST", color = P.Gold, position = Vector3.new(118, 0.5, 0) },
	{ key = "Collectors", title = "📖 COLLECTORS", color = P.Purple, position = Vector3.new(-118, 0.5, 0) },
}
local stores = {}
local lines = {} -- [key] = { TextLabel }
local names = {}

local function encode(key, data)
	if key == "Richest" then
		return math.floor(math.log10(math.max(1, data.allTotal)) * 1e6)
	end
	local found = 0
	for _ in data.index do
		found += 1
	end
	return found
end

local function decode(key, value)
	if key == "Richest" then
		return Format.cash(10 ^ (value / 1e6))
	end
	return tostring(value)
end

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok then name else "???"
	return names[userId]
end

local function buildBoard(root, def)
	local folder = root:FindFirstChild("Leaderboards") or Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = root
	local name = "Leaderboard_" .. def.key
	local board = folder:FindFirstChild(name, true)
	if not board then
		local model = Instance.new("Model")
		model.Name = name .. "Stand"
		local cf = CFrame.lookAt(def.position + Vector3.new(0, 11, 0), Vector3.new(0, 11, 0))
		Style.roundedBox(model, Vector3.new(20, 22, 0.8), cf * CFrame.new(0, 0, 0.6), def.color, 2.5)
		board = Style.roundedBox(model, Vector3.new(18, 20, 1), cf, P.White, 2)
		board.Name = name
		for _, x in { -6, 6 } do
			Style.cylinder(model, 3, 1.2, cf * CFrame.new(x, -14, 0.6), P.WoodDark)
		end
		model.Parent = folder
	end
	local old = board:FindFirstChild("BoardGui")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.Parent = board
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = gui
	local function label(text, height, color, order, font)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -30, 0, height)
		l.BackgroundTransparency = 1
		l.Font = font or Enum.Font.FredokaOne
		l.TextScaled = true
		l.Text = text
		l.TextColor3 = color
		l.LayoutOrder = order
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(35, 24, 58)
		stroke.Thickness = 3
		stroke.Parent = l
		l.Parent = gui
		return l
	end
	label(def.title, 80, def.color, 0, Enum.Font.LuckiestGuy)
	lines[def.key] = {}
	for i = 1, 10 do
		lines[def.key][i] = label("", 44, if i <= 3 then def.color else Color3.fromRGB(80, 65, 120), i)
	end
end

local function refresh(def)
	local store = stores[def.key]
	if not store then
		return
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
	if not ok then
		return
	end
	local entries = pages:GetCurrentPage()
	for i = 1, 10 do
		local entry = entries[i]
		local line = lines[def.key][i]
		if line then
			line.Text = if entry then string.format("#%d  %s  ·  %s", i, nameOf(tonumber(entry.key)), decode(def.key, entry.value)) else ""
		end
	end
end

local function submit(player)
	local data = services.DataService.get(player)
	if not data or not services.DataService.canSave(player) then
		return
	end
	for _, def in BOARDS do
		local store = stores[def.key]
		if store then
			pcall(store.SetAsync, store, tostring(player.UserId), encode(def.key, data))
		end
	end
end

function LeaderboardService.init(s)
	services = s
end

function LeaderboardService.start()
	for _, def in BOARDS do
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "GAB_" .. def.key .. "_v1")
		if ok then
			stores[def.key] = store
		end
		buildBoard(services.MapService.Root, def)
	end
	Players.PlayerRemoving:Connect(submit)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				submit(player)
			end
			for _, def in BOARDS do
				refresh(def)
			end
			task.wait(90)
		end
	end)
end

return LeaderboardService
