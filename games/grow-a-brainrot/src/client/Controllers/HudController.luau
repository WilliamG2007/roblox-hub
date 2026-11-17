-- HUD (left stack): cash pill + income chip, Moon Shards, day/night chip,
-- chunky menu buttons (Shop / Bag / Home), luck banner, claim-a-garden banner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Kit = require(script.Parent.Parent.UI.Kit)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local HudController = {}

local player = Players.LocalPlayer
local cashIcon
local cashPulse

-- screen position coins fly to (for EffectsController)
function HudController.cashTarget()
	if not cashIcon then
		return nil
	end
	local pos, size = cashIcon.AbsolutePosition, cashIcon.AbsoluteSize
	return Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2) -- both ScreenGuis ignore the top-bar inset
end

function HudController.pulseCash()
	if cashPulse then
		cashPulse.Scale = 1.12
		TweenService:Create(cashPulse, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function menuButton(parent, icon, name, color, order, onClick)
	local holder = Kit.new("Frame", { Size = UDim2.fromOffset(150, 56), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local button = Kit.button({ Size = UDim2.fromScale(1, 1), Text = "", BackgroundColor3 = color, Parent = holder })
	local face = Kit.face(button)
	Kit.label({ Position = UDim2.fromOffset(8, 4), Size = UDim2.new(0, 40, 1, -8), Text = icon, TextScaled = true, Outline = false, Parent = face })
	Kit.label({ Position = UDim2.fromOffset(50, 6), Size = UDim2.new(1, -58, 1, -12), Text = name, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = face })
	button.Activated:Connect(onClick)
	return button
end

local function myPlot(data)
	local world = workspace:FindFirstChild("GrowABrainrotWorld")
	local plots = world and world:FindFirstChild("Plots")
	return data.plotIndex and plots and plots:FindFirstChild("Plot" .. data.plotIndex)
end

function HudController.start(controllers)
	local State = controllers.State
	local gui = Kit.screen("Hud", 1)

	local stack = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 18, 0.5, 10),
		Size = UDim2.fromOffset(320, 520),
		BackgroundTransparency = 1,
		Parent = gui,
	}))

	-- cash
	local cashPill, cashLabel, icon = Kit.pill({ Parent = stack, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(300, 60), Color = Kit.Theme.Cash, Icon = "$" })
	cashIcon = icon
	cashPulse = Kit.new("UIScale", { Parent = cashPill })
	local _, incomeLabel = Kit.chip({ Parent = stack, Position = UDim2.fromOffset(78, 64), Text = "+$0/s", Color = Kit.Theme.Good })

	-- shards
	local shardsPill = Kit.new("Frame", { Position = UDim2.fromOffset(8, 100), Size = UDim2.fromOffset(190, 36), BackgroundColor3 = Kit.Theme.Panel, Parent = stack })
	Kit.corner(shardsPill, 999)
	Kit.stroke(shardsPill)
	local shardIcon = Kit.new("Frame", { Position = UDim2.fromOffset(-4, -4), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Kit.Theme.Shards, Parent = shardsPill })
	Kit.corner(shardIcon, 999)
	Kit.stroke(shardIcon)
	Kit.gloss(shardIcon, 0.25)
	Kit.label({ Size = UDim2.fromScale(1, 1), Text = "🌙", TextScaled = true, Outline = false, Parent = shardIcon })
	local shardsValue = Kit.label({ Position = UDim2.fromOffset(48, 2), Size = UDim2.new(1, -56, 1, -4), Text = "0", TextScaled = true, Font = Kit.Theme.Heavy, TextColor3 = Kit.Theme.Shards, TextXAlignment = Enum.TextXAlignment.Left, Parent = shardsPill })

	-- day / night chip
	local phaseChip = Kit.new("Frame", { Position = UDim2.fromOffset(8, 146), Size = UDim2.fromOffset(300, 38), BackgroundColor3 = Kit.Theme.Yellow, Parent = stack })
	Kit.corner(phaseChip, 999)
	Kit.stroke(phaseChip)
	Kit.gloss(phaseChip, 0.15)
	local phaseLabel = Kit.label({ Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -28, 1, -8), Text = "", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = phaseChip })

	-- menu buttons (2 columns)
	local grid = Kit.new("Frame", { Position = UDim2.fromOffset(8, 196), Size = UDim2.fromOffset(310, 280), BackgroundTransparency = 1, Parent = stack })
	Kit.new("UIGridLayout", { CellSize = UDim2.fromOffset(148, 58), CellPadding = UDim2.fromOffset(8, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	menuButton(grid, "🛒", "Shop", Kit.Theme.Pink, 1, function()
		controllers.ShopController.toggle()
	end)
	menuButton(grid, "🎒", "Bag", Kit.Theme.Teal, 2, function()
		controllers.InventoryController.toggle()
	end)
	menuButton(grid, "🏡", "Home", Kit.Theme.Blue, 3, function()
		local data = State.data
		local plot = data and myPlot(data)
		local character = player.Character
		if plot and character then
			character:PivotTo(plot:GetAttribute("Spawn"))
			Sfx.play("ui_select")
		else
			controllers.EffectsController.toast("Claim a garden first! Walk up to an empty plot.", Kit.Theme.Orange, 3)
			Sfx.play("ui_error")
		end
	end)
	local questButton = menuButton(grid, "📜", "Quests", Kit.Theme.Orange, 4, function()
		controllers.ProgressController.openQuests()
	end)
	menuButton(grid, "📖", "Index", Kit.Theme.Purple, 5, function()
		controllers.IndexController.toggle()
	end)
	menuButton(grid, "♻️", "Rebirth", Color3.fromRGB(190, 90, 255), 6, function()
		controllers.RebirthController.toggle()
	end)
	menuButton(grid, "💎", "Store", Kit.Theme.Yellow, 7, function()
		controllers.StoreController.toggle()
	end)
	-- red notification dot on Quests (claimable quests / login reward)
	local badge = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Kit.Theme.Red, Visible = false, ZIndex = 5, Parent = questButton })
	Kit.corner(badge, 999)
	Kit.stroke(badge, Kit.Theme.Outline, 2)
	local badgeLabel = Kit.label({ Size = UDim2.fromScale(1, 1), Text = "1", TextScaled = true, ZIndex = 6, Parent = badge })

	local restockChip, restockLabel = Kit.chip({ Parent = stack, Position = UDim2.fromOffset(8, 478), Text = "restock 5:00" })
	restockChip.Visible = true

	-- top center: luck event banner + claim banner
	local top = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(620, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	local luckBanner = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(560, 44), BackgroundColor3 = Kit.Theme.Purple, Visible = false, Parent = top })
	Kit.corner(luckBanner, 999)
	Kit.stroke(luckBanner)
	Kit.gloss(luckBanner, 0.15)
	local luckLabel = Kit.label({ Position = UDim2.fromOffset(16, 5), Size = UDim2.new(1, -32, 1, -10), Text = "", TextScaled = true, Parent = luckBanner })
	local claimBanner = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), Size = UDim2.fromOffset(520, 46), BackgroundColor3 = Kit.Theme.Orange, Visible = false, Parent = top })
	Kit.corner(claimBanner, 999)
	Kit.stroke(claimBanner)
	Kit.gloss(claimBanner, 0.15)
	Kit.label({ Position = UDim2.fromOffset(16, 5), Size = UDim2.new(1, -32, 1, -10), Text = "🌱 Walk to an empty garden and CLAIM it!", TextScaled = true, Parent = claimBanner })

	local shown = 0
	local lastCash = nil
	State.Changed:Connect(function(data)
		if lastCash and data.cash > lastCash then
			HudController.pulseCash()
		end
		lastCash = data.cash
	end)

	RunService.RenderStepped:Connect(function(dt)
		local data = State.data
		if not data then
			return
		end
		shown += (data.cash - shown) * math.min(1, dt * 10)
		if math.abs(data.cash - shown) < 0.5 then
			shown = data.cash
		end
		cashLabel.Text = Format.cash(shown)
		incomeLabel.Text = "+" .. Format.cash(data.income) .. "/s"
		shardsValue.Text = tostring(data.shards or 0) .. (if (data.lostCount or 0) > 0 then string.format("  · %d lost!", data.lostCount) else "")

		local now = workspace:GetServerTimeNow()
		restockLabel.Text = "📦 restock in " .. Format.time(data.shop.endsAt - now)

		local phase = ReplicatedStorage:GetAttribute("Phase") or "Day"
		local phaseLeft = Format.time((ReplicatedStorage:GetAttribute("PhaseEndsAt") or now) - now)
		if phase == "Night" then
			local boss = ReplicatedStorage:GetAttribute("BossNight")
			phaseLabel.Text = string.format("%s %s %d · %s", if boss then "👹" else "🌙", if boss then "67 NIGHT" else "Night", ReplicatedStorage:GetAttribute("NightNumber") or 1, phaseLeft)
			phaseChip.BackgroundColor3 = if boss then Kit.Theme.Blue else Kit.Theme.Purple
		else
			phaseLabel.Text = "☀️ Night in " .. phaseLeft
			phaseChip.BackgroundColor3 = Kit.Theme.Yellow
		end

		local luckEnds = ReplicatedStorage:GetAttribute("LuckEndsAt") or 0
		luckBanner.Visible = luckEnds > now
		if luckBanner.Visible then
			luckLabel.Text = string.format("🍀 %s · x%s luck · x%s mutations · %s",
				ReplicatedStorage:GetAttribute("LuckEventName") or "LUCK",
				tostring(ReplicatedStorage:GetAttribute("Luck") or 1),
				tostring(ReplicatedStorage:GetAttribute("MutationLuck") or 1),
				Format.time(luckEnds - now))
		end
		local count = controllers.ProgressController.badgeCount()
		badge.Visible = count > 0
		badgeLabel.Text = tostring(count)
		if badge.Visible then
			badge.Rotation = math.sin(os.clock() * 6) * 10
		end
		claimBanner.Visible = data.plotIndex == nil
		if claimBanner.Visible then
			claimBanner.Rotation = math.sin(os.clock() * 3) * 1.5
		end
	end)
end

return HudController
