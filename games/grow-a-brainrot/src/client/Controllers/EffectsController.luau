-- Juice: pop bursts, cash popups, toasts and server announcements.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Format = require(Shared.Format)
local Kit = require(script.Parent.Parent.UI.Kit)

local EffectsController = {}

local player = Players.LocalPlayer
local gui, toastList
local toastCount = 0

local BIG_RARITIES = { Rare = true, Epic = true, Legendary = true, Mythic = true, Secret = true }

function EffectsController.toast(text: string, color: Color3?, duration: number?)
	toastCount += 1
	local label = Kit.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Kit.Theme.Panel,
		BackgroundTransparency = 0.1,
		Text = text,
		TextWrapped = true,
		Font = Kit.Theme.Title,
		TextSize = 22,
		TextColor3 = color or Kit.Theme.Text,
		LayoutOrder = toastCount,
		Parent = toastList,
	})
	Kit.corner(label, 10)
	Kit.stroke(label, Color3.new(0, 0, 0), 2)
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = label })
	Kit.bounce(label)
	task.delay(duration or 4, function()
		TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.5)
		label:Destroy()
	end)
end

local function worldPopup(position: Vector3, text: string, color: Color3, size: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace
	local bb = Kit.new("BillboardGui", { Size = UDim2.fromOffset(300, size), AlwaysOnTop = true, LightInfluence = 0, Parent = anchor })
	local label = Kit.label({ Size = UDim2.fromScale(1, 1), Text = text, TextScaled = true, TextColor3 = color, TextStrokeTransparency = 0, Parent = bb })
	TweenService:Create(anchor, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = position + Vector3.new(0, 7, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

local function burst(position: Vector3, color: Color3, count: number, speed: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace
	local emitter = Kit.new("ParticleEmitter", {
		Rate = 0,
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(speed * 0.6, speed),
		SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, -35, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-300, 300),
		Size = NumberSequence.new(0.5),
		LightEmission = 0.4,
		EmissionDirection = Enum.NormalId.Top,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, color),
		}),
		Parent = anchor,
	})
	emitter:Emit(count)
	task.delay(2, function()
		anchor:Destroy()
	end)
end

local function lightBeam(position: Vector3, color: Color3)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.2
	beam.Size = Vector3.new(60, 3, 3)
	beam.CFrame = CFrame.new(position + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	beam.Parent = workspace
	TweenService:Create(beam, TweenInfo.new(1.6), { Transparency = 1, Size = Vector3.new(60, 0.2, 0.2) }):Play()
	task.delay(1.6, function()
		beam:Destroy()
	end)
end

local handlers = {}

function handlers.Toast(text, color)
	EffectsController.toast(text, color)
end

function handlers.Announce(text, color)
	EffectsController.toast(text, color, 6)
	Kit.sound(0.6, 0.8)
end

function handlers.Burst(position, color)
	burst(position + Vector3.new(0, 2, 0), color, 50, 30)
	lightBeam(position, color)
end

function handlers.Phase(phase, night, isBoss)
	if phase == "Night" then
		EffectsController.toast(if isBoss then "67 NIGHT HAS BEGUN... THE 67 IS AWAKE!" else string.format("NIGHT %d: the Grumblers are coming! Grab your Giant Spoon!", night), if isBoss then Color3.fromRGB(90, 170, 255) else Color3.fromRGB(190, 160, 255), 6)
		Kit.sound(0.8, 0.5)
	else
		EffectsController.toast("The sun is up! Your garden is safe.", Color3.fromRGB(255, 230, 120), 4)
		Kit.sound(0.6, 1.3)
	end
end

-- brainrots zapping monsters: short neon beams
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
		beam.Size = Vector3.new(0.3, 0.3, distance)
		beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2)
		beam.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.05, 0.05, distance) }):Play()
		task.delay(0.25, function()
			beam:Destroy()
		end)
	end
end

function handlers.Bonk(position)
	burst(position, Color3.fromRGB(255, 255, 255), 10, 15)
	Kit.sound(0.5, 0.6 + math.random() * 0.2)
end

function handlers.Shards(amount, position)
	worldPopup(position + Vector3.new(0, 5, 0), "+" .. amount .. " Moon Shard" .. (if amount == 1 then "" else "s"), Color3.fromRGB(170, 200, 255), 44)
	burst(position, Color3.fromRGB(170, 200, 255), 20, 18)
end

function handlers.Stomp(position)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(60, 150, 255)
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.4, 4, 4)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.4, 60, 60), Transparency = 1 }):Play()
	task.delay(0.6, function()
		ring:Destroy()
	end)
	Kit.sound(0.9, 0.3)
	-- camera shake if close
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

function handlers.Planted(position)
	burst(position, Color3.fromRGB(140, 95, 60), 12, 10)
end

function handlers.Pop(position, rarityName, ownerId, mutationId, size)
	local rarity = Rarities.byName[rarityName]
	local mutation = Mutations.byId[mutationId or "Normal"]
	local mutated = mutation and mutation.id ~= "Normal"
	local color = if mutated then mutation.color else rarity.color
	local big = BIG_RARITIES[rarityName] or mutated
	burst(position + Vector3.new(0, 1, 0), color, if big then 60 else 25, 25)
	if big then
		lightBeam(position, color)
	end
	if ownerId == player.UserId then
		Kit.sound(0.5, 1.1 + rarity.order * 0.08)
		local title = (if mutated then string.upper(mutation.name) .. " " else "") .. string.upper(rarityName) .. "!"
		worldPopup(position + Vector3.new(0, 7, 0), title, color, 50)
		if size then
			local sizeColor = if size >= 2 then Color3.fromRGB(255, 120, 60) else Color3.fromRGB(230, 230, 255)
			task.delay(0.35, function()
				worldPopup(position + Vector3.new(0, 4, 0), string.format("SIZE %.2fx%s", size, if size >= 2 then "  HUGE!" else ""), sizeColor, 40)
			end)
		end
	end
end

function handlers.LuckEvent(name, luck, mutationLuck, duration)
	EffectsController.toast(string.format("%s!  x%s luck, x%s mutations for %ds!", name, tostring(luck), tostring(mutationLuck), duration), Color3.fromRGB(255, 220, 80), 7)
	Kit.sound(0.7, 0.7)
end

function handlers.Cash(amount, position, verb)
	worldPopup(position + Vector3.new(0, 3, 0), "+" .. Format.cash(amount), Kit.Theme.Cash, 60)
	burst(position, Color3.fromRGB(255, 220, 60), 30, 20)
	Kit.sound(0.5, 1.4)
	if verb == "SOLD" then
		EffectsController.toast("Sold for " .. Format.cash(amount) .. "!", Kit.Theme.Cash, 2.5)
	end
end

function handlers.Bought()
	Kit.sound(0.4, 1.7)
end

function handlers.Restock()
	EffectsController.toast("The SEED SHOP just restocked!", Color3.fromRGB(150, 255, 150), 5)
	Kit.sound(0.5, 1.2)
end

function EffectsController.start()
	gui = Kit.screen("Effects", 10)
	toastList = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(560, 400),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	Kit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastList })

	Remotes.get("Fx").OnClientEvent:Connect(function(kind, ...)
		local handler = handlers[kind]
		if handler then
			handler(...)
		end
	end)
end

return EffectsController
