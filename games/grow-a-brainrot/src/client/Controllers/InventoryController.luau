-- Backpack: every seed you own, with rarity filters, selling (one / all of a
-- kind / every Normal seed of a rarity) and auto-sell toggles for pack pulls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Format)
local Seeds = require(Shared.Seeds)
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Kit = require(script.Parent.Parent.UI.Kit)

local InventoryController = {}

local State
local pending
local remote
local window, panel, grid, detail, filterButtons, autoButtons
local filter = "All"
local selectedKey = nil

local function seedValue(id, mutationId)
	return Brainrots.byId[id].income * Mutations.byId[mutationId].mult * GameConfig.SeedSellSeconds
end

local function visibleSeeds()
	local data = State.data
	local list = {}
	if not data then
		return list
	end
	for key, count in data.seeds do
		count -= pending[key] or 0
		local id, mutationId = Seeds.parse(key)
		local def, mutation = Brainrots.byId[id], Mutations.byId[mutationId]
		if count > 0 and def and mutation and (filter == "All" or def.rarity == filter) then
			table.insert(list, { key = key, count = count, def = def, mutation = mutation })
		end
	end
	table.sort(list, function(a, b)
		if a.def.order ~= b.def.order then
			return a.def.order > b.def.order
		end
		return a.mutation.order > b.mutation.order
	end)
	return list
end

local function renderDetail()
	for _, child in detail:GetChildren() do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UIGradient") then
			child:Destroy()
		end
	end
	local data = State.data
	local count = selectedKey and data and (data.seeds[selectedKey] or 0) - (pending[selectedKey] or 0) or 0
	if not selectedKey or count <= 0 then
		selectedKey = nil
		Kit.label({ Size = UDim2.fromScale(1, 1), Text = "Click a seed to sell it", TextSize = 20, TextColor3 = Color3.fromRGB(180, 180, 210), Parent = detail })
		return
	end
	local id, mutationId = Seeds.parse(selectedKey)
	local def, mutation = Brainrots.byId[id], Mutations.byId[mutationId]
	local value = seedValue(id, mutationId)
	local title = (if mutationId ~= "Normal" then mutation.name .. " " else "") .. def.name
	Kit.label({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 26), Text = title, TextSize = 22, TextColor3 = if mutationId ~= "Normal" then mutation.color else Rarities.byName[def.rarity].color, TextXAlignment = Enum.TextXAlignment.Left, Parent = detail })
	Kit.label({ Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 18), Text = string.format("x%d  ·  sells for %s each  ·  earns %s/s when grown", count, Format.cash(value), Format.cash(def.income * mutation.mult)), Font = Kit.Theme.Body, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = detail })
	local sellOne = Kit.button({ Position = UDim2.fromOffset(12, 56), Size = UDim2.fromOffset(150, 38), Text = "Sell 1", TextSize = 20, BackgroundColor3 = Kit.Theme.Bad, Parent = detail })
	local sellAll = Kit.button({ Position = UDim2.fromOffset(172, 56), Size = UDim2.fromOffset(200, 38), Text = string.format("Sell all x%d (%s)", count, Format.cash(value * count)), TextSize = 16, BackgroundColor3 = Color3.fromRGB(200, 60, 70), Parent = detail })
	local key = selectedKey
	sellOne.Activated:Connect(function()
		remote:FireServer("Sell", key, 1)
	end)
	sellAll.Activated:Connect(function()
		remote:FireServer("Sell", key, count)
	end)
end

local function render()
	if not window.isOpen() then
		return
	end
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	for i, seed in visibleSeeds() do
		local mutated = seed.mutation.id ~= "Normal"
		local cell = Kit.button({ Text = "", BackgroundColor3 = if mutated then seed.mutation.color else seed.def.colors[1], LayoutOrder = i, Parent = grid })
		local stroke = Kit.outline(cell)
		stroke.Color = if seed.key == selectedKey then Color3.new(1, 1, 1) else Rarities.byName[seed.def.rarity].color
		stroke.Thickness = if seed.key == selectedKey then 4 else 3
		Kit.label({ Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 40), Text = seed.def.name, TextScaled = true, TextWrapped = true, Parent = Kit.face(cell) })
		if mutated then
			Kit.label({ Position = UDim2.fromOffset(4, 44), Size = UDim2.new(1, -8, 0, 18), Text = string.upper(seed.mutation.name), TextScaled = true, Parent = Kit.face(cell) })
		end
		Kit.label({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -4), Size = UDim2.fromOffset(60, 26), Text = "x" .. seed.count, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Right, Parent = Kit.face(cell) })
		cell.Activated:Connect(function()
			selectedKey = seed.key
			render()
		end)
	end
	for name, button in filterButtons do
		button.BackgroundColor3 = if name == filter then Kit.Theme.Purple else Color3.fromRGB(200, 190, 230)
	end
	local autoSell = State.data and State.data.autoSell or {}
	for name, button in autoButtons do
		button.Text = name .. (if autoSell[name] then ": ON" else ": off")
		button.BackgroundColor3 = if autoSell[name] then Kit.Theme.Good else Kit.Theme.Disabled
	end
	renderDetail()
end

function InventoryController.toggle()
	window.toggle()
end

function InventoryController.start(controllers)
	State = controllers.State
	pending = controllers.PackRevealController.pending
	remote = Remotes.get("Inventory")
	local gui = Kit.screen("Inventory", 6)

	window = Kit.window(gui, { title = "BACKPACK", accent = Kit.Theme.Blue, size = Vector2.new(680, 620) })
	window.onOpen = function()
		task.defer(render)
	end
	panel = window.frame

	-- rarity filter tabs
	local tabs = Kit.new("Frame", { Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 0, 30), BackgroundTransparency = 1, Parent = panel })
	Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabs })
	filterButtons = {}
	local names = { "All" }
	for _, rarity in Rarities.list do
		table.insert(names, rarity.name)
	end
	for i, name in names do
		local button = Kit.button({ Size = UDim2.fromOffset(78, 30), Text = name, TextSize = 14, TextColor3 = if name == "All" then Color3.new(1, 1, 1) else Rarities.byName[name].color, LayoutOrder = i, Parent = tabs })
		button.Activated:Connect(function()
			filter = name
			render()
		end)
		filterButtons[name] = button
	end

	grid = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 104),
		Size = UDim2.new(1, -24, 0, 286),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Kit.new("UIGridLayout", { CellSize = UDim2.fromOffset(96, 96), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), Parent = grid })

	detail = Kit.new("Frame", { Position = UDim2.fromOffset(12, 398), Size = UDim2.new(1, -24, 0, 102), BackgroundColor3 = Kit.Theme.PanelLight, Parent = panel })
	Kit.corner(detail, 12)
	Kit.stroke(detail, Kit.Theme.Outline, 3)
	Kit.gloss(detail, 0.2)

	-- bulk sell + auto-sell
	Kit.label({ Position = UDim2.fromOffset(12, 506), Size = UDim2.new(1, -24, 0, 20), Text = "Sell every NORMAL seed of a rarity  /  auto-sell Normal pulls:", Font = Kit.Theme.Body, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
	local bulk = Kit.new("Frame", { Position = UDim2.fromOffset(12, 530), Size = UDim2.new(1, -24, 0, 34), BackgroundTransparency = 1, Parent = panel })
	Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = bulk })
	local auto = Kit.new("Frame", { Position = UDim2.fromOffset(12, 572), Size = UDim2.new(1, -24, 0, 34), BackgroundTransparency = 1, Parent = panel })
	Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = auto })
	autoButtons = {}
	for _, name in GameConfig.AutoSellRarities do
		local sellButton = Kit.button({ Size = UDim2.fromOffset(150, 34), Text = "Sell all " .. name, TextSize = 15, BackgroundColor3 = Color3.fromRGB(200, 60, 70), Parent = bulk })
		sellButton.Activated:Connect(function()
			remote:FireServer("SellRarity", name)
		end)
		local autoButton = Kit.button({ Size = UDim2.fromOffset(150, 34), Text = "", TextSize = 15, Parent = auto })
		autoButton.Activated:Connect(function()
			local on = State.data and State.data.autoSell and State.data.autoSell[name]
			remote:FireServer("AutoSell", name, not on)
		end)
		autoButtons[name] = autoButton
	end

	State.Changed:Connect(render)
	controllers.PackRevealController.PendingChanged:Connect(render)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.B then
			InventoryController.toggle()
		end
	end)
end

return InventoryController
