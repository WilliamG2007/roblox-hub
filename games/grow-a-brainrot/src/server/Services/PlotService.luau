-- Garden plots. The plots themselves are part of the map (WorldBuilder); this
-- service tracks ownership. Players are NOT auto-assigned: they walk up to an
-- empty garden and use its "Claim this garden" prompt.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.Game)

local PlotService = {}

local services
local plots = {}
local byPlayer = {}
local claimed = Instance.new("BindableEvent")
PlotService.Claimed = claimed.Event -- (player, plot)

local function find(plot, name)
	return plot:FindFirstChild(name, true)
end

local function setClaimable(plot, claimable: boolean)
	local prompt = find(plot, "ClaimPrompt")
	if prompt then
		prompt.Enabled = claimable
	end
	local claimSign = find(plot, "ClaimSign")
	if claimSign then
		claimSign.Enabled = claimable
	end
end

local function setOwnerText(plot, text)
	local sign = find(plot, "SignPost")
	local owner = sign and sign:FindFirstChild("Owner")
	if owner then
		owner.Text.Text = text
	end
end

function PlotService.init(s)
	services = s
end

function PlotService.start()
	local folder = services.MapService.Root:WaitForChild("Plots")
	for _, plot in folder:GetChildren() do
		local index = plot:GetAttribute("Index")
		if index then
			plots[index] = plot
			plot:SetAttribute("Owner", 0)
			plot:SetAttribute("OwnerName", "")
			setClaimable(plot, true)
			setOwnerText(plot, "Empty Garden")
			-- upgrade older baked maps: no spinning coin, shorter label range
			for _, inst in plot:GetDescendants() do
				if inst.Name == "Coin" and inst:IsA("BasePart") then
					inst:Destroy()
				end
			end
			local stored = plot.CollectPad:FindFirstChild("Stored")
			if stored then
				stored.MaxDistance = 60
				stored.StudsOffset = Vector3.new(0, 4.5, 0)
			end
			local owner = find(plot, "Owner")
			if owner then
				owner.MaxDistance = 110
			end
			local prompt = find(plot, "ClaimPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					PlotService.claim(player, plot)
				end)
			end
		end
	end
end

function PlotService.claim(player, plot)
	if byPlayer[player] or plot:GetAttribute("Owner") ~= 0 or not services.DataService.get(player) then
		return nil
	end
	plot:SetAttribute("Owner", player.UserId)
	plot:SetAttribute("OwnerName", player.DisplayName)
	setOwnerText(plot, player.DisplayName .. "'s Garden")
	setClaimable(plot, false)
	byPlayer[player] = plot
	claimed:Fire(player, plot)
	return plot
end

function PlotService.release(player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	byPlayer[player] = nil
	plot:SetAttribute("Owner", 0)
	plot:SetAttribute("OwnerName", "")
	setOwnerText(plot, "Empty Garden")
	setClaimable(plot, true)
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

function PlotService.hasFreePlot()
	for _, plot in plots do
		if plot:GetAttribute("Owner") == 0 then
			return true
		end
	end
	return false
end

-- respawning players go back to their own garden (if they have one)
function PlotService.sendHome(player)
	local plot = byPlayer[player]
	local character = player.Character
	if plot and character then
		character:PivotTo(plot:GetAttribute("Spawn"))
	end
end

return PlotService
