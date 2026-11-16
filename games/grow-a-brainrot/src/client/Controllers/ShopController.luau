-- Pack shop window: packs in stock, open x1 / x10, pity bars, and a per-pack
-- odds page that always shows the CURRENT odds (including server luck events).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Format)
local Odds = require(Shared.Odds)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Packs = require(Shared.Config.Packs)
local Kit = require(script.Parent.Parent.UI.Kit)

local ShopController = {}

local State
local buyRemote
local panel, list, timerLabel, luckLabel
local oddsPanel, oddsList, oddsTitle
local cards = {} -- [packId] = widgets
local renderedStockId = nil
local oddsPackId = nil

local function percent(chance)
	local p = chance * 100
	if p >= 10 then
		return string.format("%.1f%%", p)
	elseif p >= 0.1 then
		return string.format("%.2f%%", p)
	end
	return string.format("%.4f%%", p)
end

local function serverLuck()
	local endsAt = ReplicatedStorage:GetAttribute("LuckEndsAt") or 0
	if endsAt > workspace:GetServerTimeNow() then
		return ReplicatedStorage:GetAttribute("Luck") or 1, ReplicatedStorage:GetAttribute("MutationLuck") or 1
	end
	return 1, 1
end

--------------------------------------------------------------------------------
-- Odds page

local function oddsLine(text, color, size, order)
	return Kit.label({ Size = UDim2.new(1, -10, 0, size), Text = text, TextSize = size - 4, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order, Parent = oddsList })
end

local function renderOdds()
	if not oddsPackId then
		return
	end
	local pack = Packs.byId[oddsPackId]
	for _, child in oddsList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local luck, mutationLuck = serverLuck()
	oddsTitle.Text = pack.name .. " odds"
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end
	if luck > 1 or mutationLuck > 1 then
		oddsLine(string.format("Server luck active: x%s rarity, x%s mutations (included below)", tostring(luck), tostring(mutationLuck)), Kit.Theme.Accent, 22, nextOrder())
	end
	oddsLine("RARITY", Color3.new(1, 1, 1), 28, nextOrder())
	local rarities = Odds.rarities(pack, luck)
	for _, entry in rarities do
		oddsLine(entry.rarity .. ":  " .. percent(entry.chance), Rarities.byName[entry.rarity].color, 24, nextOrder())
	end
	oddsLine("EACH BRAINROT", Color3.new(1, 1, 1), 28, nextOrder())
	for _, entry in rarities do
		for _, b in Odds.brainrots(entry.rarity) do
			oddsLine("   " .. Brainrots.byId[b.id].name .. ":  " .. percent(entry.chance * b.chance), Rarities.byName[entry.rarity].color, 20, nextOrder())
		end
	end
	oddsLine("MUTATION (rolled separately)", Color3.new(1, 1, 1), 28, nextOrder())
	for _, entry in Odds.mutations(pack.mutationLuck * mutationLuck) do
		local mutation = Mutations.byId[entry.id]
		local label = if mutation.id == "Normal" then "Normal" else string.format("%s (x%d)", mutation.name, mutation.mult)
		oddsLine(label .. ":  " .. percent(entry.chance), mutation.color, 22, nextOrder())
	end
	oddsLine(string.format("PITY: guaranteed %s or better after %d opens without one.", pack.pity.rarity, pack.pity.count), Kit.Theme.Accent, 22, nextOrder())
end

local function showOdds(packId)
	oddsPackId = packId
	oddsPanel.Visible = true
	renderOdds()
end

--------------------------------------------------------------------------------
-- Pack cards

local function clearCards()
	for _, card in cards do
		card.frame:Destroy()
	end
	cards = {}
end

local function buildCard(item)
	local pack = Packs.byId[item.id]
	local frame = Kit.new("Frame", { Size = UDim2.new(1, -10, 0, 104), BackgroundColor3 = Kit.Theme.PanelLight, LayoutOrder = pack.order, Parent = list })
	Kit.corner(frame, 14)
	Kit.stroke(frame, pack.color, 3)
	local icon = Kit.new("Frame", { Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(64, 80), BackgroundColor3 = pack.color, Parent = frame })
	Kit.corner(icon, 10)
	Kit.stroke(icon, Color3.new(0, 0, 0), 3)
	Kit.label({ Size = UDim2.fromScale(1, 1), Text = "?", TextSize = 48, Parent = icon })

	Kit.label({ Position = UDim2.fromOffset(84, 8), Size = UDim2.new(1, -330, 0, 28), Text = pack.name, TextSize = 26, TextColor3 = pack.color, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	local price = Kit.label({ Position = UDim2.fromOffset(84, 36), Size = UDim2.new(1, -330, 0, 24), Text = Format.cash(pack.price), TextSize = 22, TextColor3 = Kit.Theme.Cash, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	local stock = Kit.label({ Position = UDim2.fromOffset(84, 60), Size = UDim2.new(1, -330, 0, 18), Text = "", Font = Kit.Theme.Body, TextSize = 14, TextColor3 = Color3.fromRGB(210, 210, 230), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })

	-- pity bar
	local pityBack = Kit.new("Frame", { Position = UDim2.fromOffset(84, 82), Size = UDim2.new(1, -330, 0, 12), BackgroundColor3 = Color3.fromRGB(20, 18, 40), Parent = frame })
	Kit.corner(pityBack, 6)
	local pityFill = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Rarities.byName[pack.pity.rarity].color, Parent = pityBack })
	Kit.corner(pityFill, 6)

	local one = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -128, 0, 10), Size = UDim2.fromOffset(110, 50), Text = "OPEN", TextSize = 24, Parent = frame })
	local ten = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(110, 50), Text = "x10", TextSize = 24, Parent = frame })
	local odds = Kit.button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10), Size = UDim2.fromOffset(228, 30), Text = "Odds & Pity", TextSize = 18, BackgroundColor3 = Color3.fromRGB(90, 120, 255), Parent = frame })
	one.Activated:Connect(function()
		buyRemote:FireServer(item.id, 1)
	end)
	ten.Activated:Connect(function()
		buyRemote:FireServer(item.id, 10)
	end)
	odds.Activated:Connect(function()
		showOdds(item.id)
	end)
	cards[item.id] = { frame = frame, price = price, stock = stock, pityFill = pityFill, one = one, ten = ten, pack = pack }
end

local function refresh()
	local data = State.data
	if not data or not panel.Visible then
		return
	end
	local shop = data.shop
	if renderedStockId ~= shop.stockId then
		renderedStockId = shop.stockId
		clearCards()
		for _, item in shop.items do
			buildCard(item)
		end
	end
	for _, item in shop.items do
		local card = cards[item.id]
		if card then
			local pack = card.pack
			local pity = shop.pity[pack.id] or 0
			card.stock.Text = string.format("%s  ·  pity %d/%d → %s", if item.left > 0 then item.left .. " left" else "SOLD OUT", pity, pack.pity.count, pack.pity.rarity)
			card.pityFill.Size = UDim2.fromScale(math.clamp(pity / pack.pity.count, 0, 1), 1)
			local tenCount = math.min(10, item.left)
			card.one.BackgroundColor3 = if item.left <= 0 then Color3.fromRGB(90, 90, 100) elseif data.cash >= pack.price then Kit.Theme.Good else Kit.Theme.Bad
			card.ten.Text = if tenCount > 1 then "x" .. tenCount else "x10"
			card.ten.BackgroundColor3 = if tenCount <= 1 then Color3.fromRGB(90, 90, 100) elseif data.cash >= pack.price * tenCount then Kit.Theme.Good else Kit.Theme.Bad
		end
	end
end

--------------------------------------------------------------------------------

function ShopController.open()
	panel.Visible = true
	refresh()
end

function ShopController.close()
	panel.Visible = false
	oddsPanel.Visible = false
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
	buyRemote = Remotes.get("BuyPack")
	local gui = Kit.screen("Shop", 5)

	panel = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(640, 620),
		BackgroundColor3 = Kit.Theme.Panel,
		Visible = false,
		Parent = gui,
	}))
	Kit.corner(panel, 18)
	Kit.stroke(panel, Color3.new(0, 0, 0), 4)
	Kit.label({ Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 42), Text = "PACK SHOP", TextSize = 40, TextColor3 = Kit.Theme.Accent, Parent = panel })
	timerLabel = Kit.label({ Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 24), Text = "", TextSize = 20, Parent = panel })
	luckLabel = Kit.label({ Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 22), Text = "", TextSize = 20, TextColor3 = Kit.Theme.Accent, Parent = panel })
	local close = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(44, 44), Text = "X", TextSize = 26, BackgroundColor3 = Kit.Theme.Bad, Parent = panel })
	close.Activated:Connect(ShopController.close)

	list = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 100),
		Size = UDim2.new(1, -24, 1, -112),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })

	-- odds overlay (covers the pack list)
	oddsPanel = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Kit.Theme.Panel, Visible = false, ZIndex = 5, Parent = panel })
	Kit.corner(oddsPanel, 18)
	oddsTitle = Kit.label({ Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 40), Text = "", TextSize = 34, TextColor3 = Kit.Theme.Accent, ZIndex = 5, Parent = oddsPanel })
	local back = Kit.button({ Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(90, 40), Text = "Back", TextSize = 22, BackgroundColor3 = Color3.fromRGB(90, 120, 255), ZIndex = 6, Parent = oddsPanel })
	back.Activated:Connect(function()
		oddsPanel.Visible = false
		oddsPackId = nil
	end)
	oddsList = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 60),
		Size = UDim2.new(1, -32, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 5,
		Parent = oddsPanel,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = oddsList })

	State.Changed:Connect(refresh)
	ReplicatedStorage:GetAttributeChangedSignal("LuckEndsAt"):Connect(renderOdds)

	RunService.Heartbeat:Connect(function()
		local data = State.data
		if not panel.Visible or not data then
			return
		end
		timerLabel.Text = "Restocks in " .. Format.time(data.shop.endsAt - workspace:GetServerTimeNow())
		local luck, mutationLuck = serverLuck()
		luckLabel.Text = if luck > 1 or mutationLuck > 1
			then string.format("%s ACTIVE: x%s luck, x%s mutations!", ReplicatedStorage:GetAttribute("LuckEventName") or "LUCK", tostring(luck), tostring(mutationLuck))
			else ""
	end)

	Remotes.get("Fx").OnClientEvent:Connect(function(kind)
		if kind == "OpenShop" then
			ShopController.open()
		end
	end)
end

return ShopController
