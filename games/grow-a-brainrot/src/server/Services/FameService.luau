-- Bragging rights: big pulls go on a Wall of Fame in the plaza and get announced
-- to the server. The rarest ones (Secrets, 67 mutations) are announced to EVERY
-- server through MessagingService.

local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local FameService = {}

local TOPIC = "GrowABrainrotGlobalPulls"
local MAX_ENTRIES = 8

local services
local fx
local entries = {}
local lines = {}

local function render()
	for i, line in lines do
		local entry = entries[i]
		line.Text = if entry then entry.text else ""
		line.TextColor3 = if entry then entry.color else Color3.new(1, 1, 1)
	end
end

local function buildBoard()
	-- the board itself is part of the map (WorldBuilder); we only add the live text
	local board = services.MapService.Root:FindFirstChild("WallOfFame", true)
	if not board then
		warn("[FameService] no WallOfFame part in the map; skipping the board")
		lines = {}
		return
	end
	local old = board:FindFirstChild("FameGui")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "FameGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 90)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.LuckiestGuy
	title.TextScaled = true
	title.Text = "WALL OF FAME"
	title.TextColor3 = Color3.fromRGB(255, 210, 60)
	title.TextStrokeTransparency = 0
	title.LayoutOrder = 0
	title.Parent = gui
	for i = 1, MAX_ENTRIES do
		local line = Instance.new("TextLabel")
		line.Size = UDim2.new(1, -40, 0, 50)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.FredokaOne
		line.TextScaled = true
		line.Text = ""
		line.TextStrokeTransparency = 0
		line.LayoutOrder = i
		line.Parent = gui
		lines[i] = line
	end
end

-- Server-wide: announce + Wall of Fame.
function FameService.record(text: string, color: Color3)
	table.insert(entries, 1, { text = text, color = color })
	if #entries > MAX_ENTRIES then
		table.remove(entries)
	end
	render()
	fx:FireAllClients("Announce", text, color)
end

-- Every server.
function FameService.broadcast(text: string, color: Color3)
	task.spawn(function()
		local ok, err = pcall(MessagingService.PublishAsync, MessagingService, TOPIC, {
			text = text,
			color = { color.R, color.G, color.B },
			job = game.JobId,
		})
		if not ok then
			warn("[FameService] global broadcast failed:", err)
		end
	end)
end

function FameService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function FameService.start()
	buildBoard()
	task.spawn(function()
		local ok, err = pcall(MessagingService.SubscribeAsync, MessagingService, TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" or data.job == game.JobId then
				return
			end
			local c = data.color
			fx:FireAllClients("Announce", "[GLOBAL] " .. tostring(data.text), Color3.new(c[1], c[2], c[3]))
		end)
		if not ok then
			warn("[FameService] global pulls unavailable:", err)
		end
	end)
end

return FameService
