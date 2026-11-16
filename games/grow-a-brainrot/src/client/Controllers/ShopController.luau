-- Seed shop window: current stock, buy buttons, restock timer and an odds page.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Format)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Kit = require(script.Parent.Parent.UI.Kit)

local ShopController = {}

local panel, list, oddsPage, timerLabel
local rows = {} -- [id] = row widgets
local renderedWindow = nil
local buyRemote
local State

local function clearRows()
	for _, row in rows do
		row.frame:Destroy()
	end
	rows = {}
end

local function buildRow(item, order)
	local def = Brainrots.byId[item.id]
	local rarity = Rarities.byName[def.rarity]
	local frame = Kit.new("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = Kit.Theme.PanelLight, LayoutOrder = order, Parent = list })
	Kit.corner(frame, 12)
	Kit.stroke(frame, rarity.color, 2)
	local swatch = Kit.new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = def.colors[1], Parent = frame })
	Kit.corner(swatch, 27)
	Kit.stroke(swatch, def.colors[2], 4)
	Kit.label({ Position = UDim2.fromOffset(74, 8), Size = UDim2.new(1, -200, 0, 26), Text = def.name, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	Kit.label({ Position = UDim2.fromOffset(74, 34), Size = UDim2.new(1, -200, 0, 18), Text = string.upper(def.rarity) .. "  ·  " .. Format.cash(def.income) .. "/s  ·  " .. Format.time(def.growTime), Font = Kit.Theme.Body, TextSize = 14, TextColor3 = rarity.color, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	local stock = Kit.label({ Position = UDim2.fromOffset(74, 52), Size = UDim2.new(1, -200, 0, 16), Text = "", Font = Kit.Theme.Body, TextSize = 13, TextColor3 = Color3.fromRGB(200, 200, 220), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	local buy = Kit.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(110, 50), Text = Format.cash(def.cost), TextSize = 22, Parent = frame })
	buy.Activated:Connect(function()
		buyRemote:FireServer(item.id)
	end)
	rows[item.id] = { frame = frame, stock = stock, buy = buy, def = def }
end

local function refresh()
	local data = State.data
	if not data or not panel.Visible then
		return
	end
	local shop = data.shop
	if renderedWindow ~= shop.window then
		renderedWindow = shop.window
		clearRows()
		local items = table.clone(shop.items)
		table.sort(items, function(a, b)
			return Brainrots.byId[a.id].order < Brainrots.byId[b.id].order
		end)
		for i, item in items do
			buildRow(item, i)
		end
	end
	for _, item in shop.items do
		local row = rows[item.id]
		if row then
			local affordable = data.cash >= row.def.cost
			row.stock.Text = if item.left > 0 then string.format("%d / %d in stock", item.left, item.qty) else "SOLD OUT"
			row.buy.Text = if item.left > 0 then Format.cash(row.def.cost) else "—"
			row.buy.BackgroundColor3 = if item.left <= 0 then Color3.fromRGB(90, 90, 100) elseif affordable then Kit.Theme.Good else Kit.Theme.Bad
		end
	end
end

local function buildOddsPage()
	oddsPage = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 96),
		Size = UDim2.new(1, -24, 1, -108),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
		Parent = panel,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = oddsPage })
	Kit.label({ Size = UDim2.new(1, 0, 0, 44), Text = "Chance each seed appears in a restock:", Font = Kit.Theme.Body, TextSize = 16, TextWrapped = true, LayoutOrder = 0, Parent = oddsPage })
	for i, rarity in Rarities.list do
		if rarity.shopChance > 0 then
			local text = string.format("%s:  %s%%  (stock %d–%d)", rarity.name, tostring(math.floor(rarity.shopChance * 1000 + 0.5) / 10), rarity.stock[1], rarity.stock[2])
			Kit.label({ Size = UDim2.new(1, 0, 0, 30), Text = text, TextSize = 22, TextColor3 = rarity.color, LayoutOrder = i, Parent = oddsPage })
		end
	end
	Kit.label({ Size = UDim2.new(1, 0, 0, 30), Text = "Secret: not sold in the shop", TextSize = 20, TextColor3 = Color3.fromRGB(200, 200, 200), LayoutOrder = 99, Parent = oddsPage })
end

function ShopController.open()
	panel.Visible = true
	refresh()
end

function ShopController.close()
	panel.Visible = false
end

function ShopController.toggle()
	if panel.Visible then
		ShopController.close()
	else
		ShopController.open()
	end
end

function ShopController.start(controllers)
	State = controllers.State
	buyRemote = Remotes.get("Buy")
	local gui = Kit.screen("Shop", 5)

	panel = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(520, 560),
		BackgroundColor3 = Kit.Theme.Panel,
		Visible = false,
		Parent = gui,
	}))
	Kit.corner(panel, 18)
	Kit.stroke(panel, Color3.new(0, 0, 0), 4)
	Kit.label({ Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 40), Text = "SEED SHOP", TextSize = 38, TextColor3 = Kit.Theme.Accent, Parent = panel })
	timerLabel = Kit.label({ Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 24), Text = "", TextSize = 20, Parent = panel })

	local close = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(44, 44), Text = "X", TextSize = 26, BackgroundColor3 = Kit.Theme.Bad, Parent = panel })
	close.Activated:Connect(ShopController.close)
	local oddsButton = Kit.button({ Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(80, 36), Text = "Odds", TextSize = 20, BackgroundColor3 = Color3.fromRGB(90, 120, 255), Parent = panel })

	list = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 86),
		Size = UDim2.new(1, -24, 1, -98),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	buildOddsPage()
	oddsButton.Activated:Connect(function()
		oddsPage.Visible = not oddsPage.Visible
		list.Visible = not oddsPage.Visible
		oddsButton.Text = if oddsPage.Visible then "Back" else "Odds"
	end)

	State.Changed:Connect(refresh)
	RunService.Heartbeat:Connect(function()
		local data = State.data
		if panel.Visible and data then
			timerLabel.Text = "Restocks in " .. Format.time(data.shop.endsAt - workspace:GetServerTimeNow())
		end
	end)
	Remotes.get("Fx").OnClientEvent:Connect(function(kind)
		if kind == "OpenShop" then
			ShopController.open()
		end
	end)
end

return ShopController
