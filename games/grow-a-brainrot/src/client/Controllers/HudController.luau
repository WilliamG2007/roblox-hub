-- HUD: cash pill (rolls up + pulses), income, Moon Shards, day/night badge,
-- luck banner, and the big menu buttons (SHOP / BAG).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Kit = require(script.Parent.Parent.UI.Kit)

local HudController = {}

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
		TweenService:Create(cashPulse, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function menuButton(parent, text, color, order, onClick)
	local holder = Kit.new("Frame", { Size = UDim2.fromOffset(120, 84), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local button = Kit.button({ Size = UDim2.fromScale(1, 1), Text = "", BackgroundColor3 = color, Parent = holder }, { sound = false })
	Kit.label({ Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0.62, 0), Text = text.icon, TextScaled = true, Parent = button })
	Kit.label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0.32, 0), Text = text.name, TextScaled = true, Parent = button })
	button.Activated:Connect(onClick)
	return button
end

function HudController.start(controllers)
	local State = controllers.State
	local gui = Kit.screen("Hud", 1)

	-- top center: cash
	local top = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(360, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	local cashPill, cashLabel, icon = Kit.pill({ Parent = top, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -40, 0, 58), Color = Kit.Theme.Cash, Icon = "$" })
	cashIcon = icon
	cashPulse = Kit.new("UIScale", { Parent = cashPill })
	local incomeLabel = Kit.label({ Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 26), Text = "+$0/s", TextSize = 24, TextColor3 = Color3.fromRGB(200, 255, 200), Parent = top })
	local luckBanner = Kit.label({ Position = UDim2.fromOffset(-120, 90), Size = UDim2.new(1, 240, 0, 28), Text = "", TextSize = 26, TextColor3 = Kit.Theme.Accent, Visible = false, Parent = top })

	-- top left: day/night badge + shards
	local side = Kit.autoScale(Kit.new("Frame", {
		Position = UDim2.fromOffset(16, 60),
		Size = UDim2.fromOffset(300, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	local badge = Kit.new("Frame", { Size = UDim2.fromOffset(280, 46), BackgroundColor3 = Kit.Theme.PanelDark, BackgroundTransparency = 0.1, Parent = side })
	Kit.corner(badge, 999)
	Kit.stroke(badge, Kit.Theme.Outline, 3)
	local badgeIcon = Kit.new("Frame", { Position = UDim2.fromOffset(-2, -2), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = Color3.fromRGB(255, 210, 70), Parent = badge })
	Kit.corner(badgeIcon, 999)
	Kit.stroke(badgeIcon, Kit.Theme.Outline, 3)
	Kit.gloss(badgeIcon, 0.35)
	local phaseLabel = Kit.label({ Position = UDim2.fromOffset(58, 4), Size = UDim2.new(1, -66, 1, -8), Text = "", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = badge })
	local _, shardsValue = Kit.pill({ Parent = side, Position = UDim2.fromOffset(4, 58), Size = UDim2.fromOffset(200, 38), Color = Kit.Theme.Shards, Icon = "*" })
	local lostLabel = Kit.label({ Position = UDim2.fromOffset(4, 100), Size = UDim2.fromOffset(300, 20), Text = "", TextSize = 16, TextColor3 = Color3.fromRGB(255, 190, 150), TextXAlignment = Enum.TextXAlignment.Left, Parent = side })

	-- left: menu buttons
	local menu = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 20),
		Size = UDim2.fromOffset(120, 300),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	Kit.new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	local shopButton = menuButton(menu, { icon = "$", name = "SHOP" }, Kit.Theme.Pink, 1, function()
		controllers.ShopController.toggle()
	end)
	menuButton(menu, { icon = "[ ]", name = "BAG" }, Kit.Theme.Blue, 2, function()
		controllers.InventoryController.toggle()
	end)
	local restockLabel = Kit.label({ Position = UDim2.new(0, -10, 1, 2), Size = UDim2.new(1, 20, 0, 20), Text = "", TextSize = 16, Parent = shopButton })

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
		-- roll the number toward the real value so gains feel juicy
		shown += (data.cash - shown) * math.min(1, dt * 10)
		if math.abs(data.cash - shown) < 0.5 then
			shown = data.cash
		end
		cashLabel.Text = Format.cash(shown)
		incomeLabel.Text = "+" .. Format.cash(data.income) .. " / sec"
		shardsValue.Text = tostring(data.shards or 0)
		lostLabel.Text = if (data.lostCount or 0) > 0 then string.format("%d brainrot%s at the Lost & Found!", data.lostCount, if data.lostCount == 1 then "" else "s") else ""

		local now = workspace:GetServerTimeNow()
		restockLabel.Text = "restock " .. Format.time(data.shop.endsAt - now)

		local phase = ReplicatedStorage:GetAttribute("Phase") or "Day"
		local phaseLeft = Format.time((ReplicatedStorage:GetAttribute("PhaseEndsAt") or now) - now)
		if phase == "Night" then
			local boss = ReplicatedStorage:GetAttribute("BossNight")
			phaseLabel.Text = string.format("%s %d  ·  %s", if boss then "67 NIGHT" else "NIGHT", ReplicatedStorage:GetAttribute("NightNumber") or 1, phaseLeft)
			phaseLabel.TextColor3 = if boss then Color3.fromRGB(120, 190, 255) else Color3.fromRGB(205, 180, 255)
			badgeIcon.BackgroundColor3 = if boss then Color3.fromRGB(60, 150, 255) else Color3.fromRGB(150, 120, 255)
		else
			phaseLabel.Text = "Day  ·  night in " .. phaseLeft
			phaseLabel.TextColor3 = Color3.fromRGB(255, 235, 140)
			badgeIcon.BackgroundColor3 = Color3.fromRGB(255, 210, 70)
		end

		local luckEnds = ReplicatedStorage:GetAttribute("LuckEndsAt") or 0
		luckBanner.Visible = luckEnds > now
		if luckBanner.Visible then
			luckBanner.Text = string.format("%s  ·  x%s luck  ·  x%s mutations  ·  %s",
				ReplicatedStorage:GetAttribute("LuckEventName") or "LUCK",
				tostring(ReplicatedStorage:GetAttribute("Luck") or 1),
				tostring(ReplicatedStorage:GetAttribute("MutationLuck") or 1),
				Format.time(luckEnds - now))
			luckBanner.TextTransparency = 0.1 + 0.15 * math.sin(os.clock() * 6)
		end
	end)
end

return HudController
