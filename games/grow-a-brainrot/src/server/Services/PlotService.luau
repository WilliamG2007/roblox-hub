-- Builds the garden plots and hands one to each player.
-- Plots face the central plaza; tiles are Parts named "Tile<i>" with a TileIndex attribute.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

local PlotService = {}

local services
local plots = {}
local byPlayer = {}

local PLOT_COLORS = {
	Color3.fromRGB(255, 90, 110), Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 200, 50), Color3.fromRGB(170, 100, 255),
	Color3.fromRGB(60, 210, 160), Color3.fromRGB(255, 140, 60), Color3.fromRGB(240, 100, 220), Color3.fromRGB(120, 220, 80),
}

local function plotPositions()
	local positions = {}
	for _, z in { -80, 80 } do
		for _, x in { -120, -40, 40, 120 } do
			table.insert(positions, Vector3.new(x, 0.5, z))
		end
	end
	return positions
end

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function label(parent, name, text, size, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = size
	gui.StudsOffset = offset
	gui.MaxDistance = 200
	gui.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0
	l.Parent = gui
	gui.Parent = parent
	return gui
end

local function buildPlot(index, position, parent)
	local cols, rows, T = GameConfig.PlotCols, GameConfig.PlotRows, GameConfig.TileSize
	local width, depth = cols * T + 8, rows * T + 8
	local color = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]
	-- local -Z points at the plaza
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))

	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	plot.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local floor = part(plot, { Name = "Floor", Size = Vector3.new(width, 1, depth), CFrame = base, Color = Color3.fromRGB(130, 215, 110), Material = Enum.Material.Grass })
	-- colored rim
	for _, side in { { 0, depth / 2, width, 1 }, { 0, -depth / 2, width, 1 }, { width / 2, 0, 1, depth }, { -width / 2, 0, 1, depth } } do
		part(plot, { Name = "Rim", Size = Vector3.new(side[3], 1.6, side[4]), CFrame = base * CFrame.new(side[1], 0.8, side[2]), Color = color })
	end

	for r = 1, rows do
		for c = 1, cols do
			local i = (r - 1) * cols + c
			local x = (c - (cols + 1) / 2) * T
			local z = ((rows + 1) / 2 - r) * T -- row 1 at the back
			local tile = part(plot, {
				Name = "Tile" .. i,
				Size = Vector3.new(T - 1, 0.6, T - 1),
				CFrame = base * CFrame.new(x, 0.8, z),
				Color = Color3.fromRGB(125, 85, 55),
				Material = Enum.Material.Ground,
			})
			tile:SetAttribute("TileIndex", i)
		end
	end

	local pad = part(plot, {
		Name = "CollectPad",
		Size = Vector3.new(10, 0.6, 5),
		CFrame = base * CFrame.new(0, 0.8, -depth / 2 - 4),
		Color = Color3.fromRGB(90, 255, 120),
		Material = Enum.Material.Neon,
	})
	label(pad, "Stored", "COLLECT $0", UDim2.fromOffset(240, 50), Vector3.new(0, 3.5, 0), Color3.fromRGB(150, 255, 160))

	local signPost = part(plot, { Name = "SignPost", Size = Vector3.new(14, 6, 1), CFrame = base * CFrame.new(0, 4, depth / 2 + 1), Color = color })
	label(signPost, "Owner", "Empty Garden", UDim2.fromOffset(320, 70), Vector3.new(0, 5, 0), Color3.new(1, 1, 1))

	plot:SetAttribute("Index", index)
	plot:SetAttribute("Owner", 0)
	plot:SetAttribute("OwnerName", "")
	plot:SetAttribute("Spawn", base * CFrame.new(0, 3.5, -depth / 2 - 10) * CFrame.Angles(0, math.pi, 0))
	plot.PrimaryPart = floor
	plot.Parent = parent
	return plot
end

function PlotService.init(s)
	services = s
end

function PlotService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	for i, position in plotPositions() do
		if i > GameConfig.MaxPlots then
			break
		end
		plots[i] = buildPlot(i, position, folder)
	end
	folder.Parent = services.MapService.Root
end

function PlotService.claim(player)
	for _, plot in plots do
		if plot:GetAttribute("Owner") == 0 then
			plot:SetAttribute("Owner", player.UserId)
			plot:SetAttribute("OwnerName", player.DisplayName)
			plot.SignPost.Owner.Text.Text = player.DisplayName .. "'s Garden"
			byPlayer[player] = plot
			return plot
		end
	end
	return nil
end

function PlotService.release(player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	byPlayer[player] = nil
	plot:SetAttribute("Owner", 0)
	plot:SetAttribute("OwnerName", "")
	plot.SignPost.Owner.Text.Text = "Empty Garden"
	plot.CollectPad.Stored.Text.Text = "COLLECT $0"
end

function PlotService.getPlot(player)
	return byPlayer[player]
end

function PlotService.getPlotIndex(player)
	local plot = byPlayer[player]
	return plot and plot:GetAttribute("Index")
end

function PlotService.getTile(plot, index: number)
	return plot:FindFirstChild("Tile" .. index)
end

function PlotService.tileCount()
	return GameConfig.PlotCols * GameConfig.PlotRows
end

function PlotService.sendHome(player)
	local plot = byPlayer[player]
	local character = player.Character
	if plot and character then
		character:PivotTo(plot:GetAttribute("Spawn"))
	end
end

return PlotService
