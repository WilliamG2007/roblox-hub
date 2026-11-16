-- Seed hotbar + planting: pick a seed, then click an empty tile in your garden.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Seeds = require(Shared.Seeds)
local Kit = require(script.Parent.Parent.UI.Kit)

local PlantController = {}

local player = Players.LocalPlayer
local State
local plantRemote
local bar, hint
local buttons = {}
local selected = nil
local highlight
local pending = {}

local function myPlot()
	local data = State.data
	if not data or not data.plotIndex then
		return nil
	end
	local world = workspace:FindFirstChild("GrowABrainrotWorld")
	local plots = world and world:FindFirstChild("Plots")
	return plots and plots:FindFirstChild("Plot" .. data.plotIndex)
end

local function tileUnder(screenPosition: Vector2)
	local plot = myPlot()
	if not plot then
		return nil
	end
	local ray = workspace.CurrentCamera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { plot }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	local hit = result and result.Instance
	if hit and hit:GetAttribute("TileIndex") and not hit:GetAttribute("State") then
		return hit
	end
	return nil
end

local function select(id)
	selected = if selected == id then nil else id
	for seedId, button in buttons do
		local stroke = button:FindFirstChildOfClass("UIStroke")
		stroke.Color = if seedId == selected then Color3.fromRGB(255, 255, 255) else Color3.new(0, 0, 0)
		stroke.Thickness = if seedId == selected then 4 else 2.5
	end
	hint.Visible = selected ~= nil
end

local function rebuild()
	local data = State.data
	if not data then
		return
	end
	-- seed keys are "<brainrotId>|<mutation>"; best seeds first
	local keys = {}
	local parsed = {}
	local counts = {}
	for key, count in data.seeds do
		-- hide seeds whose pack reveal is still playing
		count -= pending[key] or 0
		counts[key] = count
		local id, mutation = Seeds.parse(key)
		if count > 0 and Brainrots.byId[id] and Mutations.byId[mutation] then
			table.insert(keys, key)
			parsed[key] = { def = Brainrots.byId[id], mutation = Mutations.byId[mutation] }
		end
	end
	table.sort(keys, function(a, b)
		local pa, pb = parsed[a], parsed[b]
		if pa.def.order ~= pb.def.order then
			return pa.def.order > pb.def.order
		end
		return pa.mutation.order > pb.mutation.order
	end)

	local wanted = {}
	for i, key in keys do
		wanted[key] = true
		local def, mutation = parsed[key].def, parsed[key].mutation
		local button = buttons[key]
		if not button then
			button = Kit.button({
				Size = UDim2.fromOffset(96, 96),
				BackgroundColor3 = if mutation.id ~= "Normal" then mutation.color else def.colors[1],
				Text = "",
				Parent = bar,
			})
			Kit.label({ Name = "Name", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 40), Text = def.name, TextScaled = true, TextWrapped = true, TextStrokeTransparency = 0, Parent = button })
			if mutation.id ~= "Normal" then
				Kit.label({ Name = "Mutation", Position = UDim2.fromOffset(4, 44), Size = UDim2.new(1, -8, 0, 20), Text = string.upper(mutation.name), TextScaled = true, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, Parent = button })
			end
			Kit.label({ Name = "Count", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -4), Size = UDim2.fromOffset(60, 30), Text = "", TextSize = 26, TextXAlignment = Enum.TextXAlignment.Right, TextStrokeTransparency = 0, Parent = button })
			Kit.new("Frame", { Name = "RarityBar", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 1, -6), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Rarities.byName[def.rarity].color, Parent = button })
			button.Activated:Connect(function()
				select(key)
			end)
			buttons[key] = button
		end
		button.LayoutOrder = i
		button.Count.Text = "x" .. counts[key]
	end
	for id, button in buttons do
		if not wanted[id] then
			button:Destroy()
			buttons[id] = nil
			if selected == id then
				select(id) -- deselect
			end
		end
	end
end

local function tryPlant(screenPosition: Vector2)
	if not selected then
		return
	end
	local tile = tileUnder(screenPosition)
	if tile then
		plantRemote:FireServer(tile:GetAttribute("TileIndex"), selected)
	end
end

function PlantController.start(controllers)
	State = controllers.State
	plantRemote = Remotes.get("Plant")
	local gui = Kit.screen("Hotbar", 2)

	bar = Kit.autoScale(Kit.new("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(900, 112),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
		Parent = gui,
	}))
	Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })

	hint = Kit.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -130),
		Size = UDim2.fromOffset(600, 34),
		Text = "Click an empty dirt tile in your garden to plant!",
		TextSize = 26,
		Visible = false,
		Parent = gui,
	})

	highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(120, 255, 120)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = workspace.CurrentCamera

	pending = controllers.PackRevealController.pending
	State.Changed:Connect(rebuild)
	controllers.PackRevealController.PendingChanged:Connect(rebuild)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tryPlant(Vector2.new(input.Position.X, input.Position.Y))
		elseif input.KeyCode == Enum.KeyCode.Q then
			if selected then
				select(selected)
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local tile = selected and tileUnder(UserInputService:GetMouseLocation())
		highlight.Adornee = tile
		highlight.Enabled = tile ~= nil
	end)
end

return PlantController
