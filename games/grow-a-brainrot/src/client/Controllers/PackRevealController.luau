-- The dopamine machine. When a pack opens, the server sends the results and we
-- play them back to back:
--   1x : spin 1 = a reel of brainrot cards slows down and lands on yours,
--        spin 2 = a slot machine rolls the mutation.
--   10x: ten cards flip one by one, then mutation tags slam onto the lucky ones.
-- Click/tap anywhere to skip. Results are already decided server-side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Odds = require(Shared.Odds)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Packs = require(Shared.Config.Packs)
local GameConfig = require(Shared.Config.Game)
local GamePasses = require(Shared.Config.GamePasses)
local Format = require(Shared.Format)
local Kit = require(script.Parent.Parent.UI.Kit)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Seeds = require(Shared.Seeds)

local PackRevealController = {}

-- Seeds that exist server-side but whose reveal hasn't finished yet.
-- The hotbar hides these so the reveal isn't spoiled.
PackRevealController.pending = {} -- [seedKey] = count
local revealDone = Instance.new("BindableEvent")
PackRevealController.PendingChanged = revealDone.Event

local function addPending(results, delta)
	local pending = PackRevealController.pending
	for _, result in results do
		local key = Seeds.key(result.id, result.mutation)
		pending[key] = (pending[key] or 0) + delta
		if pending[key] <= 0 then
			pending[key] = nil
		end
	end
	revealDone:Fire()
end

local CARD_W, CARD_H, GAP = 130, 160, 10
local STEP = CARD_W + GAP
local REEL_CARDS = 46
local TARGET_INDEX = 40
local BIG = { Legendary = true, Mythic = true, Secret = true }

local gui, overlay, stage, flash, upsell
local queue = {}
local playing = false
local skip = false
local rng = Random.new()
local skippable = false -- spins can only be skipped with the 2x Roll Speed pass

local function hasFastRoll()
	return Players.LocalPlayer:GetAttribute("Pass_FastRoll") == true
end

local function speed()
	return if hasFastRoll() then 0.5 else 1
end

local function wait(seconds)
	local deadline = os.clock() + seconds
	while os.clock() < deadline and not skip do
		task.wait()
	end
end

local function clearStage()
	for _, child in stage:GetChildren() do
		if not child:IsA("UIScale") then
			child:Destroy()
		end
	end
end

local function screenFlash(color)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.2
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
end

local function card(def, parent, position, size)
	local rarity = Rarities.byName[def.rarity]
	local frame = Kit.new("Frame", { Position = position, Size = size, BackgroundColor3 = rarity.color:Lerp(Color3.new(0, 0, 0), 0.55), Parent = parent })
	Kit.corner(frame, 12)
	Kit.stroke(frame, rarity.color, 4)
	local body = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromScale(0.55, 0.45), BackgroundColor3 = def.colors[1], Parent = frame })
	Kit.corner(body, 8)
	Kit.stroke(body, def.colors[2], 4)
	-- googly eyes
	for i, x in { 0.3, 0.7 } do
		local eyeScale = if i == 1 then 0.22 else 0.27
		local eye = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.4), Size = UDim2.fromScale(eyeScale, eyeScale), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.new(1, 1, 1), Parent = body })
		Kit.corner(eye, 99)
		local pupil = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.55, 0.55), Size = UDim2.fromScale(0.45, 0.45), BackgroundColor3 = Color3.new(0, 0, 0), Parent = eye })
		Kit.corner(pupil, 99)
	end
	Kit.label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -10, 0.38, 0), Text = def.name, TextScaled = true, TextWrapped = true, TextStrokeTransparency = 0, Parent = frame })
	return frame
end

local function randomFiller(pack)
	local rarity = Odds.pick(Odds.rarities(pack, 1), rng).rarity
	return Brainrots.byId[Odds.pick(Odds.brainrots(rarity), rng).id]
end

local function easeOutQuint(t)
	return 1 - (1 - t) ^ 5
end

local function bigText(text, color, y, size)
	local label = Kit.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.fromOffset(900, size), Text = text, TextScaled = true, TextColor3 = color, TextStrokeTransparency = 0, Parent = stage })
	Kit.bounce(label)
	return label
end

--------------------------------------------------------------------------------
-- 1x: reel then mutation slot

local function mutationSlot(result)
	local mutation = Mutations.byId[result.mutation]
	local window = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 390), Size = UDim2.fromOffset(360, 80), BackgroundColor3 = Color3.fromRGB(20, 18, 40), ClipsDescendants = true, Parent = stage })
	Kit.corner(window, 14)
	Kit.stroke(window, Kit.Theme.Accent, 4)
	Kit.label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 386), Size = UDim2.fromOffset(360, 28), Text = "MUTATION", TextSize = 26, TextColor3 = Kit.Theme.Accent, Parent = stage })

	local strip = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, Parent = window })
	local rows = 30
	local entries = Odds.mutations(3) -- filler looks juicier than real odds; the landing is the real result
	for i = 1, rows do
		local m = if i == rows - 2 then mutation else Mutations.byId[Odds.pick(entries, rng).id]
		Kit.label({ Position = UDim2.fromOffset(0, (i - 1) * 80), Size = UDim2.new(1, 0, 0, 80), Text = if m.id == "Normal" then "Normal" else string.upper(m.name) .. "  x" .. m.mult, TextSize = 40, TextColor3 = m.color, TextStrokeTransparency = 0, Parent = strip })
	end
	local finalY = -(rows - 3) * 80
	local start, duration = os.clock(), GameConfig.Reveal.MutationSeconds * speed()
	local lastRow = 0
	while not skip do
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		local y = finalY * easeOutQuint(t)
		strip.Position = UDim2.fromOffset(0, y)
		local row = math.floor(-y / 80)
		if row ~= lastRow then
			lastRow = row
			Kit.sound(0.12, 2.2)
		end
		if t >= 1 then
			break
		end
		task.wait()
	end
	strip.Position = UDim2.fromOffset(0, finalY)

	if result.mutation ~= "Normal" then
		screenFlash(mutation.color)
		Kit.sound(0.7, 0.9 + mutation.order * 0.1)
		bigText(string.upper(mutation.name) .. "  x" .. mutation.mult .. "!", mutation.color, 510, 70)
	else
		bigText("Normal", Color3.fromRGB(200, 200, 200), 510, 40)
	end
end

local function playSingle(pack, result)
	local def = Brainrots.byId[result.id]
	local rarity = Rarities.byName[def.rarity]
	bigText(pack.name, pack.color, 40, 54)

	local window = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.fromOffset(STEP * 6, CARD_H + 20), BackgroundColor3 = Color3.fromRGB(15, 12, 30), ClipsDescendants = true, Parent = stage })
	Kit.corner(window, 16)
	Kit.stroke(window, pack.color, 4)
	local strip = Kit.new("Frame", { Size = UDim2.new(0, STEP * REEL_CARDS, 1, 0), BackgroundTransparency = 1, Parent = window })
	for i = 1, REEL_CARDS do
		local d = if i == TARGET_INDEX then def else randomFiller(pack)
		card(d, strip, UDim2.fromOffset((i - 1) * STEP + GAP / 2, 10), UDim2.fromOffset(CARD_W, CARD_H))
	end
	-- center marker
	Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Kit.Theme.Accent, ZIndex = 3, Parent = window })

	local center = window.Size.X.Offset / 2
	local landing = (TARGET_INDEX - 1) * STEP + STEP / 2 + rng:NextNumber(-CARD_W * 0.38, CARD_W * 0.38)
	local finalX = center - landing
	local start, duration = os.clock(), GameConfig.Reveal.ReelSeconds * speed()
	local lastCard = 0
	while not skip do
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		local x = finalX * easeOutQuint(t)
		strip.Position = UDim2.fromOffset(x, 0)
		local under = math.floor((center - x) / STEP)
		if under ~= lastCard then
			lastCard = under
			Kit.sound(0.15, 1.8 + rng:NextNumber() * 0.2)
		end
		if t >= 1 then
			break
		end
		task.wait()
	end
	strip.Position = UDim2.fromOffset(finalX, 0)

	if BIG[def.rarity] then
		screenFlash(rarity.color)
	end
	Kit.sound(0.6, 1 + rarity.order * 0.12)
	bigText(string.upper(def.rarity), rarity.color, 310, 44)
	bigText(def.name .. (if result.pity then "  (PITY!)" else ""), Color3.new(1, 1, 1), 350, 44)
	wait(0.6)
	skip = false -- the mutation spin always plays its own moment
	mutationSlot(result)
	if result.autoSold then
		bigText("AUTO-SOLD  +" .. Format.cash(result.autoSold), Color3.fromRGB(190, 190, 190), 570, 30)
	end
end

--------------------------------------------------------------------------------
-- 10x: card flips then mutation tags

local function playMulti(pack, results)
	bigText(pack.name .. "  x" .. #results, pack.color, 40, 54)
	local cols = math.min(5, #results)
	local w, h, gap = 140, 175, 14
	local rowsCount = math.ceil(#results / cols)
	local grid = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.fromOffset(cols * (w + gap), rowsCount * (h + gap)), BackgroundTransparency = 1, Parent = stage })

	local slots = {}
	for i = 1, #results do
		local c = (i - 1) % cols
		local r = math.floor((i - 1) / cols)
		local back = Kit.new("Frame", { Position = UDim2.fromOffset(c * (w + gap), r * (h + gap)), Size = UDim2.fromOffset(w, h), BackgroundColor3 = pack.color, Parent = grid })
		Kit.corner(back, 12)
		Kit.stroke(back, Color3.new(0, 0, 0), 4)
		Kit.label({ Size = UDim2.fromScale(1, 1), Text = "?", TextSize = 70, Parent = back })
		slots[i] = back
	end

	local best, bestScore = nil, -1
	for i, result in results do
		local def = Brainrots.byId[result.id]
		local rarity = Rarities.byName[def.rarity]
		local score = rarity.order * 10 + Mutations.byId[result.mutation].order
		local slot = slots[i]
		local pos = slot.Position
		slot:Destroy()
		local revealed = card(def, grid, pos, UDim2.fromOffset(w, h))
		slots[i] = revealed
		Kit.bounce(revealed)
		Kit.sound(0.35, 1 + rarity.order * 0.12)
		if BIG[def.rarity] then
			screenFlash(rarity.color)
		end
		if score > bestScore then
			best, bestScore = revealed, score
		end
		wait(GameConfig.Reveal.FlipSeconds * speed() * (if BIG[def.rarity] then 2 else 1))
	end

	skip = false
	wait(0.3)
	for i, result in results do
		local mutation = Mutations.byId[result.mutation]
		if result.mutation ~= "Normal" then
			local tag = Kit.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.08), Size = UDim2.new(1.1, 0, 0, 34), Text = string.upper(mutation.name) .. " x" .. mutation.mult, TextScaled = true, TextColor3 = mutation.color, TextStrokeTransparency = 0, Rotation = -8, ZIndex = 4, Parent = slots[i] })
			Kit.bounce(tag)
			Kit.sound(0.6, 0.9 + mutation.order * 0.1)
			if mutation.order >= Mutations.byId.Rainbow.order then
				screenFlash(mutation.color)
			end
			wait(0.35)
		end
	end
	for i, result in results do
		if result.autoSold then
			local sold = Kit.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 30), Text = "SOLD", TextScaled = true, TextColor3 = Color3.fromRGB(220, 220, 220), TextStrokeTransparency = 0, Rotation = 12, ZIndex = 5, Parent = slots[i] })
			sold.BackgroundTransparency = 0.4
			sold.BackgroundColor3 = Color3.new(0, 0, 0)
		end
	end
	if best then
		local stroke = best:FindFirstChildOfClass("UIStroke")
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Thickness = 7
		Kit.bounce(best)
	end
end

--------------------------------------------------------------------------------

local function playNext()
	if playing or #queue == 0 then
		return
	end
	playing = true
	local job = table.remove(queue, 1)
	local pack = Packs.byId[job.packId]
	skip = false
	skippable = hasFastRoll()
	clearStage()
	overlay.Visible = true
	upsell.Visible = not hasFastRoll() and GamePasses.FastRoll.id ~= 0
	if #job.results == 1 then
		playSingle(pack, job.results[1])
	else
		playMulti(pack, job.results)
	end
	addPending(job.results, -1) -- reveal is over: show the seeds in the hotbar now
	local hint = bigText("Seeds added to your hotbar!  (click to continue)", Color3.fromRGB(200, 255, 200), 600, 30)
	hint.TextTransparency = 0.1
	skip = false
	skippable = true
	wait(2.5)
	overlay.Visible = false
	clearStage()
	playing = false
	playNext()
end

function PackRevealController.start()
	gui = Kit.screen("PackReveal", 20)
	overlay = Kit.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		Parent = gui,
	})
	overlay.Activated:Connect(function()
		if skippable then
			skip = true
		end
	end)
	stage = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1000, 660),
		BackgroundTransparency = 1,
		Parent = overlay,
	}))
	flash = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10, Parent = gui })
	local upsellHolder = Kit.autoScale(Kit.new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(300, 56), BackgroundTransparency = 1, ZIndex = 11, Parent = gui }))
	upsell = Kit.button({ Size = UDim2.fromScale(1, 1), Text = GamePasses.FastRoll.name .. " + Skip", TextSize = 22, BackgroundColor3 = Color3.fromRGB(255, 180, 40), Visible = false, ZIndex = 11, Parent = upsellHolder })
	upsell.Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, GamePasses.FastRoll.id)
	end)
	overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		if not overlay.Visible then
			upsell.Visible = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input)
		if overlay.Visible and skippable and input.KeyCode == Enum.KeyCode.Space then
			skip = true
		end
	end)

	Remotes.get("Fx").OnClientEvent:Connect(function(kind, packId, results)
		if kind == "PackOpened" and Packs.byId[packId] and type(results) == "table" then
			addPending(results, 1)
			table.insert(queue, { packId = packId, results = results })
			task.spawn(playNext)
		end
	end)
end

return PackRevealController
