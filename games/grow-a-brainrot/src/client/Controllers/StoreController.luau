-- Robux store: gamepasses and developer products from Config/GamePasses.
-- Items with id = 0 aren't set up yet and show "coming soon". Products that
-- affect random results are hidden where paid random items are restricted.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GamePasses = require(Shared.Config.GamePasses)
local Kit = require(script.Parent.Parent.UI.Kit)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local StoreController = {}

local player = Players.LocalPlayer
local window, list
local rows = {}

local PASS_ORDER = { "DoubleCash", "VIP", "AutoCollect", "FastRoll" }
local PRODUCT_ORDER = { "CashSmall", "CashLarge", "LuckPotion", "InstantRestock" }

local function row(def, order, isPass, name)
	local frame = Kit.card({ Size = UDim2.new(1, -12, 0, 96), LayoutOrder = order, Parent = list })
	local icon = Kit.new("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(72, 72), BackgroundColor3 = if isPass then Kit.Theme.Purple else Kit.Theme.Teal, Parent = frame })
	Kit.corner(icon, 18)
	Kit.stroke(icon)
	Kit.gloss(icon, 0.2)
	Kit.label({ Size = UDim2.fromScale(1, 1), Text = def.icon, TextScaled = true, Outline = false, Parent = icon })
	Kit.label({ Position = UDim2.fromOffset(98, 12), Size = UDim2.new(1, -270, 0, 30), Text = def.name, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	Kit.label({ Position = UDim2.fromOffset(98, 46), Size = UDim2.new(1, -270, 0, 40), Text = def.desc, Font = Kit.Theme.Body, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Outline = false, Parent = frame })
	local button = Kit.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(150, 56), Text = "", TextSize = 24, Parent = frame }, { sound = false })
	button.Activated:Connect(function()
		if def.id == 0 then
			Sfx.play("ui_error")
			return
		end
		if isPass and player:GetAttribute("Pass_" .. name) then
			Sfx.play("ui_error")
			return
		end
		Sfx.play("purchase")
		if isPass then
			MarketplaceService:PromptGamePassPurchase(player, def.id)
		else
			MarketplaceService:PromptProductPurchase(player, def.id)
		end
	end)
	rows[name] = { frame = frame, button = button, def = def, isPass = isPass }
end

local function render()
	for name, r in rows do
		local owned = r.isPass and player:GetAttribute("Pass_" .. name) == true
		r.frame.Visible = not (r.def.random and player:GetAttribute("RandomRestricted"))
		r.button.Text = if owned then "OWNED ✓" elseif r.def.id == 0 then "soon" else "⏣ " .. r.def.price
		r.button.BackgroundColor3 = if owned or r.def.id == 0 then Kit.Theme.Disabled else Kit.Theme.Good
	end
end

function StoreController.toggle()
	window.toggle()
end

function StoreController.start()
	local gui = Kit.screen("Store", 6)
	window = Kit.window(gui, { title = "💎 STORE", accent = Kit.Theme.Teal, size = Vector2.new(620, 620) })
	list = Kit.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 1, -82), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = window.frame })
	Kit.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), Parent = list })
	local function header(text, order)
		Kit.label({ Size = UDim2.new(1, -12, 0, 32), Text = text, TextSize = 26, Font = Kit.Theme.Heavy, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Kit.Theme.Purple, LayoutOrder = order, Parent = list })
	end
	header("GAMEPASSES (forever)", 0)
	for i, name in PASS_ORDER do
		if GamePasses[name] then
			row(GamePasses[name], i, true, name)
		end
	end
	header("BOOSTS", 10)
	for i, name in PRODUCT_ORDER do
		if GamePasses.Products[name] then
			row(GamePasses.Products[name], 10 + i, false, name)
		end
	end
	window.onOpen = function()
		task.defer(render)
	end
	player.AttributeChanged:Connect(render)
	render()
end

return StoreController
