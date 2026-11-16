-- Admin panel: quick-action buttons, a command box for anything custom, and the
-- full command list. Only shown to admins (server sets the IsAdmin attribute and
-- re-checks every command anyway).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local AdminCommands = require(Shared.AdminCommands)
local Kit = require(script.Parent.Parent.UI.Kit)

local AdminController = {}

local player = Players.LocalPlayer

local QUICK = {
	{ "Luck x3 (60s)", "luck 3 60" },
	{ "Luck x10 (30s)", "luck 10 30" },
	{ "Mutations x6.7", "mutluck 6.7 67" },
	{ "End event", "endevent" },
	{ "Basic x10 for ALL", "givepack 1 10 all" },
	{ "Sigma x5 for ALL", "givepack 3 5 all" },
	{ "Cosmic x3 for ALL", "givepack 10 3 all" },
	{ "Restock shop", "restock" },
	{ "Cosmic in stock", "stock 10 5" },
	{ "+$1M (me)", "cash 1000000" },
	{ "+$1B (me)", "cash 1000000000" },
	{ "Grow all (me)", "grow" },
	{ "Grow all (ALL)", "grow all" },
	{ "Clear garden (me)", "clear" },
	{ "Speed 50 (me)", "speed 50" },
	{ "Speed 16 (me)", "speed 16" },
	{ "Start night", "night" },
	{ "67 NIGHT", "night boss" },
	{ "Skip to day", "day" },
	{ "Spawn 5 Grumblers", "spawn 5" },
	{ "Spawn THE 67", "boss" },
	{ "+100 Moon Shards", "shards 100" },
	{ "Toggle 2x Roll (me)", "pass FastRoll" },
	{ "Wild brainrot", "wander" },
}

function AdminController.start()
	local remote = Remotes.get("Admin")
	local gui = Kit.screen("Admin", 15)
	gui.Enabled = false

	local holder = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.fromOffset(110, 46),
		BackgroundTransparency = 1,
		Parent = gui,
	}))
	local toggle = Kit.button({ Size = UDim2.fromScale(1, 1), Text = "ADMIN", TextSize = 22, BackgroundColor3 = Color3.fromRGB(220, 60, 60), Parent = holder })

	local panel = Kit.autoScale(Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -72),
		Size = UDim2.fromOffset(460, 600),
		BackgroundColor3 = Kit.Theme.Panel,
		Visible = false,
		Parent = gui,
	}))
	Kit.corner(panel, 16)
	Kit.stroke(panel, Color3.fromRGB(220, 60, 60), 3)
	Kit.label({ Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 32), Text = "ADMIN PANEL", TextSize = 30, TextColor3 = Color3.fromRGB(255, 120, 120), Parent = panel })

	-- command box
	local box = Kit.new("TextBox", {
		Position = UDim2.fromOffset(12, 48),
		Size = UDim2.new(1, -110, 0, 40),
		BackgroundColor3 = Color3.fromRGB(20, 18, 40),
		Text = "",
		PlaceholderText = "type a command, e.g. event 5 5 120 MEGA LUCK",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 170),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Kit.Theme.Body,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = panel,
	})
	Kit.corner(box, 8)
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = box })
	local run = Kit.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 48), Size = UDim2.fromOffset(86, 40), Text = "RUN", TextSize = 20, BackgroundColor3 = Kit.Theme.Good, Parent = panel })
	local function submit()
		if box.Text ~= "" then
			remote:FireServer(box.Text)
		end
	end
	run.Activated:Connect(submit)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end)

	-- quick actions
	local grid = Kit.new("ScrollingFrame", { Position = UDim2.fromOffset(12, 98), Size = UDim2.new(1, -24, 0, 300), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel })
	Kit.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 32), CellPadding = UDim2.fromOffset(8, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for i, quick in QUICK do
		local button = Kit.button({ Text = quick[1], TextSize = 16, BackgroundColor3 = Color3.fromRGB(70, 60, 130), LayoutOrder = i, Parent = grid })
		button.Activated:Connect(function()
			remote:FireServer(quick[2])
		end)
	end

	-- command reference (click one to put it in the box)
	local help = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 400),
		Size = UDim2.new(1, -24, 1, -410),
		BackgroundColor3 = Color3.fromRGB(20, 18, 40),
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Kit.corner(help, 8)
	Kit.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = help })
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), Parent = help })
	for i, cmd in AdminCommands do
		local line = Kit.new("TextButton", {
			Size = UDim2.new(1, -10, 0, 34),
			BackgroundTransparency = 1,
			Text = cmd.usage .. "\n" .. cmd.desc,
			Font = Kit.Theme.Body,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(220, 220, 240),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = i,
			Parent = help,
		})
		line.Activated:Connect(function()
			box.Text = cmd.name .. " "
			box:CaptureFocus()
		end)
	end

	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F2 and gui.Enabled then
			panel.Visible = not panel.Visible
		end
	end)

	local function refresh()
		gui.Enabled = player:GetAttribute("IsAdmin") == true
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(refresh)
	refresh()
end

return AdminController
