-- Rebirth window: current rebirths and multiplier, what you keep and lose,
-- the next pack unlock, and a two-click confirm.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Format)
local Progress = require(Shared.Config.Progress)
local Packs = require(Shared.Config.Packs)
local Kit = require(script.Parent.Parent.UI.Kit)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local RebirthController = {}

local State
local remote
local window, countLabel, multLabel, costLabel, unlockLabel, button
local armedUntil = 0

local function render()
	local data = State.data
	local progress = data and data.progress
	if not progress or not window.isOpen() then
		return
	end
	countLabel.Text = "Rebirths: " .. progress.rebirths
	multLabel.Text = string.format("Your income: x%.2f  →  after rebirth: +%d%% more", progress.multiplier, Progress.Rebirth.IncomeBonus * 100)
	costLabel.Text = "Costs " .. Format.cash(progress.rebirthCost) .. " (you have " .. Format.cash(data.cash) .. ")"
	local nextUnlock
	for _, pack in Packs.list do
		if (pack.rebirth or 0) > progress.rebirths and (not nextUnlock or pack.rebirth < nextUnlock.rebirth) then
			nextUnlock = pack
		end
	end
	unlockLabel.Text = if nextUnlock then string.format("🔓 Rebirth %d unlocks the %s", nextUnlock.rebirth, nextUnlock.name) else "🔓 Every pack is unlocked!"
	local canAfford = data.cash >= progress.rebirthCost
	local armed = os.clock() < armedUntil
	button.Text = if armed then "ARE YOU SURE?!" elseif canAfford then "♻️ REBIRTH!" else "Not enough cash"
	button.BackgroundColor3 = if armed then Kit.Theme.Red elseif canAfford then Kit.Theme.Purple else Kit.Theme.Disabled
end

function RebirthController.toggle()
	window.toggle()
end

function RebirthController.start(controllers)
	State = controllers.State
	remote = Remotes.get("Progress")
	local gui = Kit.screen("Rebirth", 6)
	window = Kit.window(gui, { title = "♻️ REBIRTH", accent = Kit.Theme.Purple, size = Vector2.new(540, 450) })
	local frame = window.frame
	countLabel = Kit.label({ Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 46), Text = "", TextSize = 40, Font = Kit.Theme.Heavy, TextColor3 = Kit.Theme.Purple, Parent = frame })
	multLabel = Kit.label({ Position = UDim2.fromOffset(20, 122), Size = UDim2.new(1, -40, 0, 26), Text = "", TextSize = 19, Outline = false, Parent = frame })
	local info = Kit.card({ Position = UDim2.fromOffset(20, 158), Size = UDim2.new(1, -40, 0, 120), Parent = frame })
	Kit.label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 50), Text = "✅ You KEEP: Index, Moon Shards, gamepasses, rebirth bonus", TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Outline = false, TextColor3 = Color3.fromRGB(40, 150, 60), Parent = info })
	Kit.label({ Position = UDim2.fromOffset(14, 60), Size = UDim2.new(1, -28, 0, 50), Text = "❌ You LOSE: cash, seeds, everything in your garden", TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Outline = false, TextColor3 = Color3.fromRGB(200, 60, 70), Parent = info })
	unlockLabel = Kit.label({ Position = UDim2.fromOffset(20, 288), Size = UDim2.new(1, -40, 0, 26), Text = "", TextSize = 19, TextColor3 = Kit.Theme.Orange, Parent = frame })
	costLabel = Kit.label({ Position = UDim2.fromOffset(20, 318), Size = UDim2.new(1, -40, 0, 22), Text = "", TextSize = 16, Outline = false, TextColor3 = Kit.Theme.TextMuted, Parent = frame })
	button = Kit.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(320, 64), Text = "", TextSize = 30, Parent = frame }, { sound = false })
	button.Activated:Connect(function()
		local data = State.data
		local progress = data and data.progress
		if not progress or data.cash < progress.rebirthCost then
			Sfx.play("ui_error")
			return
		end
		if os.clock() < armedUntil then
			armedUntil = 0
			remote:FireServer("Rebirth")
			window.close()
		else
			armedUntil = os.clock() + 3
			Sfx.play("ui_select")
			task.delay(3.05, render)
		end
		render()
	end)
	window.onOpen = function()
		task.defer(render)
	end
	State.Changed:Connect(render)
end

return RebirthController
