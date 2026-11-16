-- Juice: toasts, pops, cash popups, coins flying to the counter, night effects.
-- Every server Fx event that's purely visual/audio is handled here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Format = require(Shared.Format)
local Kit = require(script.Parent.Parent.UI.Kit)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local EffectsController = {}

local player = Players.LocalPlayer
local gui, toastList, flyLayer
local toastCount = 0
local controllers

local BIG_RARITIES = { Rare = true, Epic = true, Legendary = true, Mythic = true, Secret = true }
local GOLD = Color3.fromRGB(255, 205, 60)

--------------------------------------------------------------------------------
-- Toasts: colored pill that slides in from above, then fades

function EffectsController.toast(text: string, color: Color3?, duration: number?)
	toastCount += 1
	color = color or Kit.Theme.Text
	local holder = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = toastCount,
		Parent = toastList,
	})
	local pill = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Kit.Theme.PanelDark,
		BackgroundTransparency = 0.05,
		Position = UDim2.fromOffset(0, -20),
		Parent = holder,
	})
	Kit.corner(pill, 14)
	local stroke = Kit.stroke(pill, Kit.Theme.Outline, 3)
	local bar = Kit.new("Frame", { Size = UDim2.new(0, 8, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = pill })
	Kit.corner(bar, 14)
	local label = Kit.label({
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -28, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextWrapped = true,
		TextSize = 22,
		TextColor3 = color,
		Parent = pill,
	})
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), Parent = label })
	TweenService:Create(pill, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()
	task.delay(duration or 4, function()
		Kit.fadeOut(label, 0.4)
		TweenService:Create(pill, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(bar, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.wait(0.45)
		holder:Destroy()
	end)
	-- never more than 5 on screen
	local children = {}
	for _, child in toastList:GetChildren() do
		if child:IsA("Frame") then
			table.insert(children, child)
		end
	end
	table.sort(children, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #children - 5 do
		children[i]:Destroy()
	end
end

--------------------------------------------------------------------------------
-- World effects

local function anchorAt(position: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace
	return anchor
end

local function worldPopup(position: Vector3, text: string, color: Color3, size: number)
	local anchor = anchorAt(position)
	local bb = Kit.new("BillboardGui", { Size = UDim2.fromOffset(320, size), AlwaysOnTop = true, LightInfluence = 0, Parent = anchor })
	local label = Kit.label({ Size = UDim2.fromScale(1, 1), Text = text, TextScaled = true, TextColor3 = color, Parent = bb })
	local scale = Kit.new("UIScale", { Scale = 0.4, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(anchor, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = position + Vector3.new(0, 7, 0) }):Play()
	task.delay(0.8, function()
		Kit.fadeOut(label, 0.5)
	end)
	task.delay(1.35, function()
		anchor:Destroy()
	end)
end

local function burst(position: Vector3, color: Color3, count: number, speed: number)
	local anchor = anchorAt(position)
	local emitter = Kit.new("ParticleEmitter", {
		Rate = 0,
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(speed * 0.5, speed),
		SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, -40, 0),
		Drag = 2,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-300, 300),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
		LightEmission = 0.5,
		EmissionDirection = Enum.NormalId.Top,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, color),
		}),
		Parent = anchor,
	})
	emitter:Emit(count)
	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

-- expanding ring on the ground (pops, collects, stomps)
local function ring(position: Vector3, color: Color3, size: number, duration: number)
	local r = Instance.new("Part")
	r.Anchored = true
	r.CanCollide = false
	r.CanQuery = false
	r.CastShadow = false
	r.Shape = Enum.PartType.Cylinder
	r.Material = Enum.Material.Neon
	r.Color = color
	r.Transparency = 0.25
	r.Size = Vector3.new(0.3, 2, 2)
	r.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	r.Parent = workspace
	TweenService:Create(r, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, size, size), Transparency = 1 }):Play()
	task.delay(duration, function()
		r:Destroy()
	end)
end

local function lightBeam(position: Vector3, color: Color3)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.25
	beam.Size = Vector3.new(60, 3, 3)
	beam.CFrame = CFrame.new(position + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	beam.Parent = workspace
	TweenService:Create(beam, TweenInfo.new(1.6), { Transparency = 1, Size = Vector3.new(60, 0.2, 0.2) }):Play()
	task.delay(1.6, function()
		beam:Destroy()
	end)
end

-- coins fly from a world position to the cash counter at the top of the screen
local function flyCoins(position: Vector3, count: number)
	local camera = workspace.CurrentCamera
	local screenPos, onScreen = camera:WorldToViewportPoint(position)
	if not onScreen then
		return
	end
	local target = controllers.HudController and controllers.HudController.cashTarget and controllers.HudController.cashTarget()
	if not target then
		return
	end
	for i = 1, count do
		local coin = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(screenPos.X + math.random(-30, 30), screenPos.Y + math.random(-20, 20)),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = GOLD,
			ZIndex = 20,
			Parent = flyLayer,
		})
		Kit.corner(coin, 999)
		Kit.stroke(coin, Color3.fromRGB(150, 100, 0), 2.5)
		Kit.label({ Size = UDim2.fromScale(1, 1), Text = "$", TextScaled = true, TextColor3 = Color3.fromRGB(255, 250, 220), Outline = false, ZIndex = 21, Parent = coin })
		task.delay(i * 0.04, function()
			local tween = TweenService:Create(coin, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(16, 16) })
			tween:Play()
			tween.Completed:Wait()
			coin:Destroy()
			Sfx.play("cash_small")
			if controllers.HudController.pulseCash then
				controllers.HudController.pulseCash()
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- Server events

local handlers = {}

function handlers.Toast(text, color)
	EffectsController.toast(text, color)
	-- red-ish toasts are warnings ("Not enough cash!")
	local warning = color and color.R > 0.9 and color.G < 0.6
	Sfx.play(if warning then "ui_error" else "notify")
end

function handlers.Announce(text, color)
	EffectsController.toast(text, color, 6)
	Sfx.play("announce")
end

function handlers.Planted(position)
	burst(position, Color3.fromRGB(140, 95, 60), 14, 12)
	ring(position + Vector3.new(0, 0.2, 0), Color3.fromRGB(180, 130, 80), 8, 0.4)
	Sfx.playAt("plant", position)
end

function handlers.Pop(position, rarityName, ownerId, mutationId, size)
	local rarity = Rarities.byName[rarityName]
	local mutation = Mutations.byId[mutationId or "Normal"]
	local mutated = mutation and mutation.id ~= "Normal"
	local color = if mutated then mutation.color else rarity.color
	local big = BIG_RARITIES[rarityName] or mutated
	burst(position + Vector3.new(0, 1, 0), color, if big then 60 else 28, 28)
	ring(position + Vector3.new(0, 0.3, 0), color, if big then 22 else 12, 0.6)
	if big then
		lightBeam(position, color)
	end
	local mine = ownerId == player.UserId
	if mine then
		Sfx.play(if big then "pop_rare" else "pop", { pitch = 1 + (rarity.order - 1) * 0.04 })
		local title = (if mutated then string.upper(mutation.name) .. " " else "") .. string.upper(rarityName) .. "!"
		worldPopup(position + Vector3.new(0, 7, 0), title, color, 54)
		if size then
			local huge = size >= 2
			task.delay(0.35, function()
				worldPopup(position + Vector3.new(0, 4, 0), string.format("SIZE %.2fx%s", size, if huge then "  HUGE!" else ""), if huge then Kit.Theme.Orange else Color3.fromRGB(230, 230, 255), 40)
			end)
		end
	else
		Sfx.playAt(if big then "pop_rare" else "pop", position, { volume = 0.7 })
	end
end

function handlers.Cash(amount, position, verb)
	worldPopup(position + Vector3.new(0, 3, 0), "+" .. Format.cash(amount), Kit.Theme.Cash, 64)
	burst(position, GOLD, 30, 22)
	ring(position + Vector3.new(0, 0.3, 0), GOLD, 14, 0.5)
	Sfx.play(if verb == "SOLD" then "sell" else "collect")
	flyCoins(position, math.clamp(math.floor(math.log10(math.max(amount, 1)) * 2) + 3, 3, 12))
end

function handlers.Bought()
	Sfx.play("purchase")
end

function handlers.Restock()
	EffectsController.toast("The PACK SHOP just restocked!", Color3.fromRGB(150, 255, 150), 5)
	Sfx.play("restock")
end

function handlers.Burst(position, color)
	burst(position + Vector3.new(0, 2, 0), color, 50, 30)
	ring(position + Vector3.new(0, 0.3, 0), color, 18, 0.6)
	lightBeam(position, color)
	Sfx.playAt("monster_die", position)
end

function handlers.LuckEvent(name, luck, mutationLuck, duration)
	EffectsController.toast(string.format("%s!  x%s luck, x%s mutations for %ds!", name, tostring(luck), tostring(mutationLuck), duration), Kit.Theme.Accent, 7)
	Sfx.play("luck_event")
end

function handlers.Phase(phase, night, isBoss)
	if phase == "Night" then
		EffectsController.toast(if isBoss then "67 NIGHT HAS BEGUN... THE 67 IS AWAKE!" else string.format("NIGHT %d: the Grumblers are coming! Grab your Giant Spoon!", night), if isBoss then Color3.fromRGB(90, 170, 255) else Color3.fromRGB(190, 160, 255), 6)
		Sfx.play("night_start")
		Sfx.music("music_night")
	else
		EffectsController.toast("The sun is up! Your garden is safe.", Color3.fromRGB(255, 230, 120), 4)
		Sfx.play("day_start")
		Sfx.music("music_day")
	end
end

function handlers.Zaps(zaps)
	for _, zap in zaps do
		local from, to, color = zap[1], zap[2], zap[3]
		local distance = (to - from).Magnitude
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CastShadow = false
		beam.Material = Enum.Material.Neon
		beam.Color = color
		beam.Size = Vector3.new(0.35, 0.35, distance)
		beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2)
		beam.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.05, 0.05, distance) }):Play()
		task.delay(0.25, function()
			beam:Destroy()
		end)
	end
	if zaps[1] then
		Sfx.playAt("zap", zaps[1][2])
	end
end

function handlers.Bonk(position)
	burst(position, Color3.new(1, 1, 1), 12, 16)
	worldPopup(position + Vector3.new(0, 3, 0), "BONK!", Color3.fromRGB(255, 240, 120), 40)
	Sfx.playAt("bonk", position)
end

function handlers.Shards(amount, position)
	worldPopup(position + Vector3.new(0, 5, 0), "+" .. amount .. " Moon Shard" .. (if amount == 1 then "" else "s"), Kit.Theme.Shards, 46)
	burst(position, Kit.Theme.Shards, 20, 18)
	Sfx.play("shards")
end

function handlers.Stomp(position)
	ring(position + Vector3.new(0, 0.6, 0), Color3.fromRGB(60, 150, 255), 60, 0.6)
	Sfx.playAt("stomp", position)
	local camera = workspace.CurrentCamera
	if (camera.CFrame.Position - position).Magnitude < 90 then
		task.spawn(function()
			for i = 1, 10 do
				local intensity = (10 - i) * 0.04
				camera.CFrame *= CFrame.Angles(math.random(-10, 10) / 100 * intensity, math.random(-10, 10) / 100 * intensity, 0)
				task.wait()
			end
		end)
	end
end

--------------------------------------------------------------------------------

function EffectsController.start(c)
	controllers = c
	gui = Kit.screen("Effects", 10)
	toastList = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.fromOffset(560, 400),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	Kit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastList })
	flyLayer = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })

	Remotes.get("Fx").OnClientEvent:Connect(function(kind, ...)
		local handler = handlers[kind]
		if handler then
			handler(...)
		end
	end)

	-- start the right music for the current phase
	Sfx.music(if ReplicatedStorage:GetAttribute("Phase") == "Night" then "music_night" else "music_day")
end

return EffectsController
