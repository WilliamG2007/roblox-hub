-- Builds the garden plots and hands one to each player.
-- Plots face the central plaza; tiles are Parts named "Tile<i>" with a TileIndex attribute.
-- Names other code relies on: Floor, Tile<i>, CollectPad.Stored.Text, SignPost.Owner.Text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Style = require(ReplicatedStorage.Shared.Style)

local PlotService = {}

local P = Style.Palette
local services
local plots = {}
local byPlayer = {}

local PLOT_COLORS = {
	Color3.fromRGB(255, 95, 130), Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 200, 50), Color3.fromRGB(170, 105, 255),
	Color3.fromRGB(60, 210, 165), Color3.fromRGB(255, 145, 60), Color3.fromRGB(240, 105, 220), Color3.fromRGB(130, 220, 80),
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
	l.TextStrokeTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(25, 18, 45)
	stroke.Thickness = 3
	stroke.Parent = l
	l.Parent = gui
	gui.Parent = parent
	return gui
end

local function buildPlot(index, position, parent)
	local cols, rows, T = GameConfig.PlotCols, GameConfig.PlotRows, GameConfig.TileSize
	local width, depth = cols * T + 8, rows * T + 8
	local color = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]
	-- local -Z points at the plaza; y = 0 is the ground surface
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))

	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	plot.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- colored ledge with a rounded grass bed on top
	Style.roundedBox(plot, Vector3.new(width + 3, 1.2, depth + 3), base * CFrame.new(0, -0.1, 0), color, 3)
	local floor = Style.roundedBox(plot, Vector3.new(width, 1, depth), base * CFrame.new(0, 0.15, 0), P.GrassLight, 2.5)
	floor.Name = "Floor"
	-- stud strip along the front ledge (brick accent)
	Style.studs(plot, base * CFrame.new(0, 0.5, -(depth / 2 + 0.75)), 10, 1, 1.5, color:Lerp(Color3.new(1, 1, 1), 0.25))

	-- corner posts with glowing floating orbs
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local corner = base * CFrame.new(sx * (width / 2 + 0.2), 0.5, sz * (depth / 2 + 0.2))
			Style.cylinder(plot, 3, 1.4, corner, color)
			Style.cylinder(plot, 0.4, 2, corner * CFrame.new(0, 3, 0), P.White)
			local orb = Style.ball(plot, 1.6, corner * CFrame.new(0, 4.6, 0), color:Lerp(Color3.new(1, 1, 1), 0.35), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			Style.float(orb, 0.35, 2, index + sx + sz * 0.5)
		end
	end

	-- dirt beds: dark rim + the clickable tile on top
	for r = 1, rows do
		for c = 1, cols do
			local i = (r - 1) * cols + c
			local x = (c - (cols + 1) / 2) * T
			local z = ((rows + 1) / 2 - r) * T -- row 1 at the back
			Style.part(plot, { Name = "TileRim", Size = Vector3.new(T - 0.6, 0.3, T - 0.6), CFrame = base * CFrame.new(x, 0.75, z), Color = P.DirtDark, CanQuery = false })
			local tile = Style.part(plot, {
				Name = "Tile" .. i,
				Size = Vector3.new(T - 1.8, 0.35, T - 1.8),
				CFrame = base * CFrame.new(x, 0.85, z),
				Color = P.Dirt,
				Reflectance = 0,
			})
			tile:SetAttribute("TileIndex", i)
		end
	end

	-- collect pad: glowing disc with a spinning coin above it
	local padCFrame = base * CFrame.new(0, 0.6, -depth / 2 - 6)
	Style.cylinder(plot, 0.35, 11, padCFrame * CFrame.new(0, -0.35, 0), P.White)
	local pad = Style.part(plot, {
		Name = "CollectPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 9, 9),
		CFrame = padCFrame * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(90, 255, 120),
		Material = Enum.Material.Neon,
	})
	local coin = Style.part(plot, {
		Name = "Coin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 3, 3),
		CFrame = padCFrame * CFrame.new(0, 4.5, 0),
		Color = P.Gold,
		Reflectance = 0.15,
		CanCollide = false,
		CastShadow = false,
	})
	Style.spin(coin, 90)
	Style.float(coin, 0.4, 2)
	label(pad, "Stored", "COLLECT $0", UDim2.fromOffset(250, 50), Vector3.new(0, 7.5, 0), Color3.fromRGB(150, 255, 160))

	-- sign board on two posts behind the garden
	local signCFrame = base * CFrame.new(0, 0, depth / 2 + 2.5)
	for _, x in { -6, 6 } do
		Style.cylinder(plot, 6, 0.9, signCFrame * CFrame.new(x, 0.5, 0), P.WoodDark)
	end
	local signPost = Style.roundedBox(plot, Vector3.new(16, 4.5, 1), signCFrame * CFrame.new(0, 6, 0), color, 1.5)
	signPost.Name = "SignPost"
	label(signPost, "Owner", "Empty Garden", UDim2.fromOffset(320, 70), Vector3.new(0, 4.5, 0), Color3.new(1, 1, 1))

	plot:SetAttribute("Index", index)
	plot:SetAttribute("Owner", 0)
	plot:SetAttribute("OwnerName", "")
	plot:SetAttribute("Spawn", base * CFrame.new(0, 3.5, -depth / 2 - 14) * CFrame.Angles(0, math.pi, 0))
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

local function findDeep(plot, name)
	return plot:FindFirstChild(name, true)
end

function PlotService.claim(player)
	for _, plot in plots do
		if plot:GetAttribute("Owner") == 0 then
			plot:SetAttribute("Owner", player.UserId)
			plot:SetAttribute("OwnerName", player.DisplayName)
			findDeep(plot, "SignPost").Owner.Text.Text = player.DisplayName .. "'s Garden"
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
	findDeep(plot, "SignPost").Owner.Text.Text = "Empty Garden"
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
