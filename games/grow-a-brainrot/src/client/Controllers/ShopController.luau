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
local Sfx = require(script.Parent.Parent.UI.Sfx)

local ShopController = {}

local State
local buyRemote
local window, list, timerLabel, luckLabel
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
	for _, entry in Odds.mutations(pack.mutationLuck * mutationLuck, pack.bonusMutation) do
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
	local frame = Kit.card({ Size = UDim2.new(1, -12, 0, 112), LayoutOrder = pack.order, Parent = list })
	-- colored edge in the pack's color
	local edge = Kit.new("Frame", { Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = pack.color, BorderSizePixel = 0, Parent = frame })
	Kit.corner(edge, 16)

	-- glossy pack "box" icon with a wobbling ?
	local icon = Kit.new("Frame", { Position = UDim2.fromOffset(20, 12), Size = UDim2.fromOffset(72, 88), BackgroundColor3 = pack.color, Parent = frame })
	Kit.corner(icon, 14)
	Kit.stroke(icon, Kit.Theme.Outline, 3)
	Kit.gloss(icon, 0.4)
	Kit.new("Frame", { Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, Parent = icon })
	local question = Kit.label({ Size = UDim2.fromScale(1, 1), Text = "?", TextSize = 54, Parent = icon })

	Kit.label({ Position = UDim2.fromOffset(104, 8), Size = UDim2.new(1, -350, 0, 30), Text = pack.name, TextSize = 28, TextColor3 = pack.color, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	local shardPack = pack.currency == "shards"
	local price = Kit.label({ Position = UDim2.fromOffset(104, 40), Size = UDim2.new(1, -350, 0, 26), Text = if shardPack then pack.price .. " Moon Shards" else Format.cash(pack.price), TextSize = 24, TextColor3 = if shardPack then Kit.Theme.Shards else Kit.Theme.Cash, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	local stock = Kit.label({ Position = UDim2.fromOffset(104, 68), Size = UDim2.new(1, -350, 0, 16), Text = "", Font = Kit.Theme.Body, TextSize = 13, TextColor3 = Kit.Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left, Outline = false, Parent = frame })

	-- pity bar
	local pityBack = Kit.new("Frame", { Position = UDim2.fromOffset(104, 88), Size = UDim2.new(1, -350, 0, 12), BackgroundColor3 = Kit.Theme.PanelInset, Parent = frame })
	Kit.corner(pityBack, 6)
	Kit.stroke(pityBack, Kit.Theme.Outline, 2)
	local pityFill = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Rarities.byName[pack.pity.rarity].color, Parent = pityBack })
	Kit.corner(pityFill, 6)
	Kit.gloss(pityFill, 0.3)

	local one = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -134, 0, 12), Size = UDim2.fromOffset(114, 52), Text = "OPEN", TextSize = 26, Parent = frame }, { sound = false })
	local ten = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(114, 52), Text = "x10", TextSize = 26, Parent = frame }, { sound = false })
	local odds = Kit.button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.fromOffset(236, 32), Text = "Odds & Pity", TextSize = 18, BackgroundColor3 = Kit.Theme.Blue, Parent = frame })
	local card = { frame = frame, price = price, stock = stock, pityFill = pityFill, one = one, ten = ten, pack = pack, question = question }
	card.affordable = function()
		return true
	end
	local function buy(count)
		if card.affordable(count) then
			buyRemote:FireServer(item.id, count)
		else
			Sfx.play("ui_error")
		end
	end
	one.Activated:Connect(function()
		buy(1)
	end)
	ten.Activated:Connect(function()
		buy(10)
	end)
	odds.Activated:Connect(function()
		showOdds(item.id)
	end)
	cards[item.id] = card
end

local function refresh()
	local data = State.data
	if not data or not window.isOpen() then
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
			local wallet = if pack.currency == "shards" then data.shards or 0 else data.cash
			local left = item.left
			card.affordable = function(count)
				local n = math.min(count, left)
				return n >= 1 and wallet >= pack.price * n
			end
			card.one.BackgroundColor3 = if left <= 0 then Kit.Theme.Disabled elseif wallet >= pack.price then Kit.Theme.Good else Kit.Theme.Bad
			card.ten.Text = if tenCount > 1 then "x" .. tenCount else "x10"
			card.ten.BackgroundColor3 = if tenCount <= 1 then Kit.Theme.Disabled elseif wallet >= pack.price * tenCount then Kit.Theme.Good else Kit.Theme.Bad
		end
	end
end

--------------------------------------------------------------------------------

function ShopController.open()
	window.open()
	refresh()
end

function ShopController.close()
	window.close()
end

function ShopController.toggle()
	if window.isOpen() then
		ShopController.close()
	else
		ShopController.open()
	end
end

function ShopController.start(controllers)
	State = controllers.State
	buyRemote = Remotes.get("BuyPack")
	local gui = Kit.screen("Shop", 5)

	window = Kit.window(gui, { title = "PACK SHOP", accent = Kit.Theme.Pink, size = Vector2.new(660, 640) })
	window.onClose = function()
		oddsPanel.Visible = false
		oddsPackId = nil
	end
	local panel = window.frame
	timerLabel = Kit.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -70, 0, 14), Size = UDim2.fromOffset(240, 28), Text = "", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Right, Parent = window.header })
	luckLabel = Kit.label({ Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 24), Text = "", TextSize = 20, TextColor3 = Kit.Theme.Accent, Parent = panel })

	list = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 90),
		Size = UDim2.new(1, -24, 1, -100),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Kit.Theme.Pink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), Parent = list })

	-- odds overlay (covers the pack list, below the header)
	oddsPanel = Kit.new("Frame", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundColor3 = Kit.Theme.Panel, Visible = false, ZIndex = 5, Parent = panel })
	Kit.gloss(oddsPanel, 0.3)
	oddsTitle = Kit.label({ Position = UDim2.fromOffset(110, 10), Size = UDim2.new(1, -130, 0, 40), Text = "", TextSize = 32, TextColor3 = Kit.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = oddsPanel })
	local back = Kit.button({ Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(88, 40), Text = "Back", TextSize = 22, BackgroundColor3 = Kit.Theme.Blue, ZIndex = 6, Parent = oddsPanel })
	back.Activated:Connect(function()
		oddsPanel.Visible = false
		oddsPackId = nil
	end)
	oddsList = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 60),
		Size = UDim2.new(1, -32, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
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
		if not window.isOpen() or not data then
			return
		end
		timerLabel.Text = "restock " .. Format.time(data.shop.endsAt - workspace:GetServerTimeNow())
		local luck, mutationLuck = serverLuck()
		luckLabel.Text = if luck > 1 or mutationLuck > 1
			then string.format("%s ACTIVE: x%s luck, x%s mutations!", ReplicatedStorage:GetAttribute("LuckEventName") or "LUCK", tostring(luck), tostring(mutationLuck))
			else ""
		-- gently wobble the ? on every pack
		local t = os.clock()
		for _, card in cards do
			card.question.Rotation = math.sin(t * 2 + card.pack.order) * 8
		end
	end)

	Remotes.get("Fx").OnClientEvent:Connect(function(kind)
		if kind == "OpenShop" then
			ShopController.open()
		end
	end)
end

return ShopController
