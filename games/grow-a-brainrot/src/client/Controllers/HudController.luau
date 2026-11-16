-- Top-of-screen cash counter (rolls up smoothly) + income per second + shop button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Kit = require(script.Parent.Parent.UI.Kit)

local HudController = {}

function HudController.start(controllers)
	local State = controllers.State
	local gui = Kit.screen("Hud", 1)

	local top = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(420, 100),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	local cashLabel = Kit.label({ Size = UDim2.new(1, 0, 0, 64), Text = "$0", TextSize = 60, TextColor3 = Kit.Theme.Cash, TextStrokeTransparency = 0, Parent = top })
	Kit.new("UIStroke", { Thickness = 3, Color = Color3.fromRGB(20, 60, 25), Parent = cashLabel })
	local incomeLabel = Kit.label({ Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 28), Text = "+$0/s", TextSize = 26, Parent = top })
	local luckBanner = Kit.label({ Position = UDim2.fromOffset(-100, 94), Size = UDim2.new(1, 200, 0, 30), Text = "", TextSize = 28, TextColor3 = Kit.Theme.Accent, TextStrokeTransparency = 0, Visible = false, Parent = top })

	local holder = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, -40),
		Size = UDim2.fromOffset(130, 100),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	local shopButton = Kit.button({
		Size = UDim2.fromOffset(130, 70),
		BackgroundColor3 = Color3.fromRGB(255, 120, 150),
		Text = "SHOP",
		TextSize = 32,
		Parent = holder,
	})
	local restockLabel = Kit.label({ Position = UDim2.new(0, 0, 1, 4), Size = UDim2.new(1, 0, 0, 22), Text = "", TextSize = 18, Parent = shopButton })
	shopButton.Activated:Connect(function()
		controllers.ShopController.toggle()
	end)

	local shown = 0
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
		incomeLabel.Text = "+" .. Format.cash(data.income) .. "/s"
		local now = workspace:GetServerTimeNow()
		restockLabel.Text = "Restock " .. Format.time(data.shop.endsAt - now)

		local luckEnds = ReplicatedStorage:GetAttribute("LuckEndsAt") or 0
		luckBanner.Visible = luckEnds > now
		if luckBanner.Visible then
			luckBanner.Text = string.format("%s  ·  x%s luck  ·  x%s mutations  ·  %s",
				ReplicatedStorage:GetAttribute("LuckEventName") or "LUCK",
				tostring(ReplicatedStorage:GetAttribute("Luck") or 1),
				tostring(ReplicatedStorage:GetAttribute("MutationLuck") or 1),
				Format.time(luckEnds - now))
			luckBanner.TextTransparency = 0.15 + 0.15 * math.sin(os.clock() * 6)
		end
	end)
end

return HudController
