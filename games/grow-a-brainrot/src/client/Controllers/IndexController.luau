-- Brainrot Index: the collection book. Every brainrot by rarity row;
-- undiscovered ones are dark "???" silhouettes. Completing a row unlocks a
-- claimable permanent income bonus.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Progress = require(Shared.Config.Progress)
local Kit = require(script.Parent.Parent.UI.Kit)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local IndexController = {}

local State
local remote
local window, list, totalLabel

local function card(parent, def, found)
	local rarity = Rarities.byName[def.rarity]
	local frame = Kit.new("Frame", { Size = UDim2.fromOffset(104, 124), BackgroundColor3 = if found then Kit.Theme.Panel else Color3.fromRGB(70, 60, 95), Parent = parent })
	Kit.corner(frame)
	Kit.stroke(frame, if found then rarity.color else Kit.Theme.Outline, 3)
	local body = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(58, 58), BackgroundColor3 = if found then def.colors[1] else Color3.fromRGB(40, 32, 60), Parent = frame })
	Kit.corner(body, 999)
	Kit.stroke(body, if found then def.colors[2] else Color3.fromRGB(25, 18, 40), 4)
	if found then
		for i, x in { 0.32, 0.68 } do
			local eye = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.42), Size = UDim2.fromOffset(if i == 1 then 14 else 17, if i == 1 then 14 else 17), BackgroundColor3 = Color3.new(1, 1, 1), Parent = body })
			Kit.corner(eye, 999)
			local pupil = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.55, 0.55), Size = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.new(0, 0, 0), Parent = eye })
			Kit.corner(pupil, 999)
		end
	else
		Kit.label({ Size = UDim2.fromScale(1, 1), Text = "?", TextScaled = true, TextColor3 = Color3.fromRGB(120, 105, 160), Parent = body })
	end
	Kit.label({ Position = UDim2.fromOffset(4, 74), Size = UDim2.new(1, -8, 0, 44), Text = if found then def.name else "???", TextScaled = true, TextWrapped = true, Outline = not found, TextColor3 = if found then Kit.Theme.TextDark else nil, Parent = frame })
	return frame
end

local function render()
	local data = State.data
	if not data or not window.isOpen() then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local claimed = data.progress and data.progress.indexClaimed or {}
	local foundTotal, total = 0, 0
	for order, rarity in Rarities.list do
		local group = Brainrots.byRarity[rarity.name] or {}
		local found = 0
		for _, def in group do
			if data.discovered[def.id] then
				found += 1
			end
		end
		foundTotal += found
		total += #group
		local row = Kit.card({ Size = UDim2.new(1, -10, 0, 196), LayoutOrder = order, Parent = list })
		local tag = Kit.new("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(170, 32), BackgroundColor3 = rarity.color, Parent = row })
		Kit.corner(tag, 999)
		Kit.stroke(tag)
		Kit.gloss(tag, 0.15)
		Kit.label({ Size = UDim2.fromScale(1, 1), Text = string.format("%s  %d/%d", rarity.name:upper(), found, #group), TextScaled = true, Parent = tag })
		local complete = found == #group and #group > 0
		local isClaimed = claimed[rarity.name]
		local claimButton = Kit.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 6),
			Size = UDim2.fromOffset(200, 40),
			Text = if isClaimed then string.format("+%d%% ✓", Progress.IndexBonusPerRarity * 100) elseif complete then string.format("CLAIM +%d%%!", Progress.IndexBonusPerRarity * 100) else string.format("complete: +%d%% income", Progress.IndexBonusPerRarity * 100),
			TextSize = 18,
			BackgroundColor3 = if isClaimed then Kit.Theme.Disabled elseif complete then Kit.Theme.Good else Kit.Theme.Purple,
			Parent = row,
		}, { sound = false })
		claimButton.Activated:Connect(function()
			if complete and not isClaimed then
				remote:FireServer("ClaimIndex", rarity.name)
				Sfx.play("unlock")
			else
				Sfx.play("ui_error")
			end
		end)
		local cards = Kit.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 0, 134), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 5, Parent = row })
		Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = cards })
		for _, def in group do
			card(cards, def, data.discovered[def.id] == true)
		end
	end
	totalLabel.Text = string.format("Discovered %d / %d brainrots", foundTotal, total)
end

function IndexController.toggle()
	window.toggle()
end

function IndexController.start(controllers)
	State = controllers.State
	remote = Remotes.get("Progress")
	local gui = Kit.screen("Index", 6)
	window = Kit.window(gui, { title = "📖 BRAINROT INDEX", accent = Kit.Theme.Purple, size = Vector2.new(700, 640) })
	totalLabel = Kit.label({ Position = UDim2.fromOffset(18, 66), Size = UDim2.new(1, -36, 0, 26), Text = "", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Outline = false, Parent = window.frame })
	list = Kit.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 100), Size = UDim2.new(1, -24, 1, -112), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = window.frame })
	Kit.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), Parent = list })
	window.onOpen = function()
		task.defer(render)
	end
	State.Changed:Connect(render)
end

return IndexController
