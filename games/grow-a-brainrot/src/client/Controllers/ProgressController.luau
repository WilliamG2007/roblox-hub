-- Tutorial guide (quest card + bouncing arrow + beam to the target), daily
-- login calendar (pops up when claimable), and the daily quests window.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Format)
local Progress = require(Shared.Config.Progress)
local Packs = require(Shared.Config.Packs)
local Kit = require(script.Parent.Parent.UI.Kit)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local ProgressController = {}

local player = Players.LocalPlayer
local State
local remote
local questWindow, questList, streakLabel, resetLabel
local dailyWindow, dayCards, dailyButton
local tutorialCard, tutorialTitle, tutorialHint, tutorialBar
local arrowGui, beam, beamA0, beamA1
local dailyShownFor = nil

local function world()
	return workspace:FindFirstChild("GrowABrainrotWorld")
end

local function myPlot(data)
	local w = world()
	local plots = w and w:FindFirstChild("Plots")
	return data.plotIndex and plots and plots:FindFirstChild("Plot" .. data.plotIndex)
end

local function rewardText(reward)
	local parts = {}
	if reward.cash then
		table.insert(parts, "💵 Cash")
	end
	if reward.shards then
		table.insert(parts, "🌙 " .. reward.shards)
	end
	if reward.pack then
		table.insert(parts, "📦 " .. ((reward.packCount or 1) > 1 and reward.packCount .. "x " or "") .. Packs.byId[reward.pack].name)
	end
	return table.concat(parts, " + ")
end

--------------------------------------------------------------------------------
-- tutorial target finding

local function tutorialTarget(stepId, data)
	local w = world()
	if not w then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if stepId == "claim" then
		local best, bestDist = nil, math.huge
		local plots = w:FindFirstChild("Plots")
		for _, plot in (plots and plots:GetChildren() or {}) do
			local prompt = plot:FindFirstChild("ClaimPrompt", true)
			if prompt and prompt.Enabled and prompt.Parent:IsA("BasePart") then
				local d = if root then (prompt.Parent.Position - root.Position).Magnitude else 0
				if d < bestDist then
					best, bestDist = prompt.Parent.Position, d
				end
			end
		end
		return best
	elseif stepId == "shop" then
		local prompt = w:FindFirstChild("ShopPrompt", true)
		return prompt and prompt.Parent:IsA("BasePart") and prompt.Parent.Position
	end
	local plot = myPlot(data)
	if not plot then
		return nil
	end
	if stepId == "plant" then
		for i = 1, 12 do
			local tile = plot:FindFirstChild("Tile" .. i)
			if tile and not tile:GetAttribute("State") then
				return tile.Position
			end
		end
	elseif stepId == "grow" then
		for i = 1, 12 do
			local tile = plot:FindFirstChild("Tile" .. i)
			if tile and tile:GetAttribute("State") == "growing" then
				return tile.Position
			end
		end
	elseif stepId == "collect" then
		return plot.CollectPad.Position
	end
	return nil
end

--------------------------------------------------------------------------------
-- windows

local function renderQuests()
	local data = State.data
	local progress = data and data.progress
	if not progress or not questWindow.isOpen() then
		return
	end
	for _, child in questList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	streakLabel.Text = string.format("🔥 Login streak: day %d", progress.streak)
	resetLabel.Text = "New quests in " .. Format.time(progress.questsResetIn)
	for i, quest in progress.quests do
		local row = Kit.card({ Size = UDim2.new(1, -8, 0, 92), LayoutOrder = i, Parent = questList })
		Kit.label({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -170, 0, 28), Text = quest.text, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Outline = false, Parent = row })
		local back = Kit.new("Frame", { Position = UDim2.fromOffset(16, 50), Size = UDim2.new(1, -180, 0, 22), BackgroundColor3 = Kit.Theme.PanelInset, Parent = row })
		Kit.corner(back, 999)
		Kit.stroke(back, Kit.Theme.Outline, 2)
		local fill = Kit.new("Frame", { Size = UDim2.fromScale(math.clamp(quest.progress / quest.goal, 0, 1), 1), BackgroundColor3 = if quest.done then Kit.Theme.Good else Kit.Theme.Teal, Parent = back })
		Kit.corner(fill, 999)
		Kit.gloss(fill, 0.2)
		Kit.label({ Size = UDim2.fromScale(1, 1), Text = string.format("%d / %d", quest.progress, quest.goal), TextSize = 16, Parent = back })
		local button = Kit.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(140, 52),
			Text = if quest.claimed then "DONE ✓" elseif quest.done then "CLAIM!" else "...",
			TextSize = 22,
			BackgroundColor3 = if quest.claimed then Kit.Theme.Disabled elseif quest.done then Kit.Theme.Good else Kit.Theme.Disabled,
			Parent = row,
		}, { sound = false })
		button.Activated:Connect(function()
			if quest.done and not quest.claimed then
				remote:FireServer("ClaimQuest", i)
				Sfx.play("unlock")
			else
				Sfx.play("ui_error")
			end
		end)
	end
end

local function renderDaily()
	local progress = State.data and State.data.progress
	if not progress then
		return
	end
	for day, card in dayCards do
		local isToday = day == progress.streak
		local past = day < progress.streak or (isToday and not progress.dailyClaimable)
		card.frame.BackgroundColor3 = if isToday then Kit.Theme.Yellow elseif past then Kit.Theme.Good else Kit.Theme.Panel
		card.check.Visible = past
	end
	dailyButton.Text = if progress.dailyClaimable then "CLAIM DAY " .. progress.streak .. "!" else "Come back tomorrow!"
	dailyButton.BackgroundColor3 = if progress.dailyClaimable then Kit.Theme.Good else Kit.Theme.Disabled
end

local function buildQuestWindow(gui)
	questWindow = Kit.window(gui, { title = "📜 DAILY QUESTS", accent = Kit.Theme.Orange, size = Vector2.new(560, 470) })
	local frame = questWindow.frame
	streakLabel = Kit.label({ Position = UDim2.fromOffset(18, 66), Size = UDim2.new(0.5, -20, 0, 28), Text = "", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Kit.Theme.Orange, Parent = frame })
	resetLabel = Kit.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 70), Size = UDim2.new(0.5, -20, 0, 22), Text = "", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right, Outline = false, TextColor3 = Kit.Theme.TextMuted, Parent = frame })
	questList = Kit.new("Frame", { Position = UDim2.fromOffset(14, 104), Size = UDim2.new(1, -28, 1, -180), BackgroundTransparency = 1, Parent = frame })
	Kit.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = questList })
	local calendar = Kit.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(300, 54), Text = "🎁 Login Rewards", TextSize = 24, BackgroundColor3 = Kit.Theme.Pink, Parent = frame })
	calendar.Activated:Connect(function()
		questWindow.close()
		dailyWindow.open()
	end)
	questWindow.onOpen = function()
		task.defer(renderQuests)
	end
end

local function buildDailyWindow(gui)
	dailyWindow = Kit.window(gui, { title = "🎁 LOGIN REWARDS", accent = Kit.Theme.Pink, size = Vector2.new(720, 380) })
	local frame = dailyWindow.frame
	Kit.label({ Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 24), Text = "Come back every day! Miss a day and the streak restarts.", TextSize = 18, Outline = false, Parent = frame })
	local row = Kit.new("Frame", { Position = UDim2.fromOffset(16, 104), Size = UDim2.new(1, -32, 0, 160), BackgroundTransparency = 1, Parent = frame })
	Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	dayCards = {}
	for day, reward in Progress.LoginRewards do
		local card = Kit.new("Frame", { Size = UDim2.fromOffset(88, 150), BackgroundColor3 = Kit.Theme.Panel, LayoutOrder = day, Parent = row })
		Kit.corner(card)
		Kit.stroke(card)
		Kit.gloss(card, 0.12)
		Kit.label({ Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 26), Text = "DAY " .. day, TextSize = 22, Font = Kit.Theme.Heavy, Parent = card })
		Kit.label({ Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 50), Text = if reward.pack then "📦" elseif reward.shards and not reward.cash then "🌙" else "💵", TextScaled = true, Outline = false, Parent = card })
		Kit.label({ Position = UDim2.fromOffset(4, 92), Size = UDim2.new(1, -8, 0, 50), Text = reward.label, TextScaled = true, TextWrapped = true, Outline = false, Parent = card })
		local check = Kit.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 2), Size = UDim2.fromOffset(28, 28), Text = "✓", TextScaled = true, TextColor3 = Kit.Theme.Good, Visible = false, Parent = card })
		dayCards[day] = { frame = card, check = check }
	end
	dailyButton = Kit.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(320, 60), Text = "", TextSize = 28, Parent = frame }, { sound = false })
	dailyButton.Activated:Connect(function()
		local progress = State.data and State.data.progress
		if progress and progress.dailyClaimable then
			remote:FireServer("ClaimDaily")
			Sfx.play("unlock")
			task.delay(1.2, dailyWindow.close)
		else
			Sfx.play("ui_error")
		end
	end)
	dailyWindow.onOpen = function()
		task.defer(renderDaily)
	end
end

local function buildTutorial(gui)
	local holder = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 70),
		Size = UDim2.fromOffset(360, 130),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	tutorialCard = Kit.card({ Size = UDim2.fromScale(1, 1), Visible = false, Parent = holder })
	local header = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Kit.Theme.Teal, Parent = tutorialCard })
	Kit.corner(header)
	Kit.gloss(header, 0.15)
	Kit.label({ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -90, 1, -8), Text = "⭐ GETTING STARTED", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = header })
	local skip = Kit.new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(60, 24), BackgroundTransparency = 1, Text = "skip", Font = Kit.Theme.Body, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), Parent = header })
	skip.Activated:Connect(function()
		remote:FireServer("SkipTutorial")
	end)
	tutorialTitle = Kit.label({ Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -28, 0, 30), Text = "", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Outline = false, Parent = tutorialCard })
	tutorialHint = Kit.label({ Position = UDim2.fromOffset(14, 72), Size = UDim2.new(1, -28, 0, 20), Text = "", Font = Kit.Theme.Body, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Outline = false, TextColor3 = Kit.Theme.TextMuted, Parent = tutorialCard })
	local back = Kit.new("Frame", { Position = UDim2.fromOffset(14, 100), Size = UDim2.new(1, -28, 0, 16), BackgroundColor3 = Kit.Theme.PanelInset, Parent = tutorialCard })
	Kit.corner(back, 999)
	Kit.stroke(back, Kit.Theme.Outline, 2)
	tutorialBar = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Kit.Theme.Teal, Parent = back })
	Kit.corner(tutorialBar, 999)

	-- 3D guide: bouncing arrow over the target + a beam from you to it
	local anchor = Instance.new("Part")
	anchor.Name = "TutorialTarget"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Parent = workspace
	arrowGui = Kit.new("BillboardGui", { Size = UDim2.fromOffset(90, 90), AlwaysOnTop = true, LightInfluence = 0, Enabled = false, Parent = anchor })
	Kit.label({ Size = UDim2.fromScale(1, 1), Text = "⬇️", TextScaled = true, Outline = false, Parent = arrowGui })
	beamA1 = Instance.new("Attachment")
	beamA1.Parent = anchor
	beamA0 = Instance.new("Attachment")
	beam = Instance.new("Beam")
	beam.Attachment1 = beamA1
	beam.Color = ColorSequence.new(Kit.Theme.Yellow)
	beam.Transparency = NumberSequence.new(0.3, 0.6)
	beam.Width0 = 0.8
	beam.Width1 = 0.8
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Segments = 1
	beam.Enabled = false
	beam.Parent = anchor
	ProgressController.anchor = anchor
end

local function updateTutorial()
	local data = State.data
	local progress = data and data.progress
	local step = progress and Progress.Tutorial[progress.tutorial]
	tutorialCard.Visible = step ~= nil
	if not step then
		arrowGui.Enabled = false
		beam.Enabled = false
		return
	end
	tutorialTitle.Text = string.format("%d/%d  %s", progress.tutorial, #Progress.Tutorial, step.text)
	tutorialHint.Text = step.hint .. "   (reward: " .. rewardText(step.reward) .. ")"
	tutorialBar.Size = UDim2.fromScale((progress.tutorial - 1) / #Progress.Tutorial, 1)
	local target = tutorialTarget(step.id, data)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if target and root then
		ProgressController.anchor.Position = target + Vector3.new(0, 6 + math.abs(math.sin(os.clock() * 4)) * 1.5, 0)
		arrowGui.Enabled = true
		beamA0.Parent = root
		beam.Attachment0 = beamA0
		beam.Enabled = (target - root.Position).Magnitude > 12
	else
		arrowGui.Enabled = false
		beam.Enabled = false
	end
end

--------------------------------------------------------------------------------

function ProgressController.openQuests()
	questWindow.toggle()
end

function ProgressController.openDaily()
	dailyWindow.toggle()
end

-- red-dot count for the HUD button
function ProgressController.badgeCount()
	local progress = State.data and State.data.progress
	if not progress then
		return 0
	end
	local n = if progress.dailyClaimable then 1 else 0
	for _, quest in progress.quests do
		if quest.done and not quest.claimed then
			n += 1
		end
	end
	return n
end

function ProgressController.start(controllers)
	State = controllers.State
	remote = Remotes.get("Progress")
	local gui = Kit.screen("Progress", 7)
	buildQuestWindow(gui)
	buildDailyWindow(gui)
	buildTutorial(gui)

	State.Changed:Connect(function(data)
		renderQuests()
		if dailyWindow.isOpen() then
			renderDaily()
		end
		-- pop the login calendar once per session when there's something to claim
		local progress = data.progress
		if progress and progress.dailyClaimable and dailyShownFor ~= progress.streak and progress.tutorial > #Progress.Tutorial then
			dailyShownFor = progress.streak
			task.delay(2, dailyWindow.open)
		end
	end)

	Remotes.get("Fx").OnClientEvent:Connect(function(kind, stepIndex, text, done)
		if kind == "TutorialStep" then
			local step = Progress.Tutorial[stepIndex]
			controllers.EffectsController.toast(string.format("✅ %s!  %s", step and step.text or "Step done", text or ""), Kit.Theme.Good, 4)
			Sfx.play("unlock")
			if done then
				controllers.EffectsController.toast("🎉 Tutorial complete! You're a real brainrot farmer now.", Kit.Theme.Yellow, 6)
			end
		end
	end)

	RunService.RenderStepped:Connect(updateTutorial)
end

return ProgressController
