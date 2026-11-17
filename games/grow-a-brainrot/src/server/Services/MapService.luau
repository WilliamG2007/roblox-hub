-- Finds the map (baked into the place via WorldBuilder.bake) or builds it if
-- it's missing, then exposes the gameplay anchors other services use:
-- Root, ShopPrompt, LostFoundPrompt, RoadWaypoints.

local WorldBuilder = require(script.Parent.Parent.World.WorldBuilder)

local MapService = {}

MapService.Root = nil

local function find(root, name)
	local inst = root:FindFirstChild(name, true)
	assert(inst, "[MapService] the map is missing '" .. name .. "' (re-bake or restore it)")
	return inst
end

function MapService.init()
	local root = workspace:FindFirstChild("GrowABrainrotWorld")
	if root then
		print("[MapService] using the baked map")
	else
		root = WorldBuilder.build()
	end
	MapService.Root = root
	MapService.ShopPrompt = find(root, "ShopPrompt")
	MapService.LostFoundPrompt = find(root, "LostFoundPrompt")
	local x, z, top = root:GetAttribute("RoadX") or 160, root:GetAttribute("RoadZ") or 38, root:GetAttribute("RoadTop") or 0.8
	MapService.RoadWaypoints = {
		Vector3.new(x, top, z),
		Vector3.new(-x, top, z),
		Vector3.new(-x, top, -z),
		Vector3.new(x, top, -z),
	}
end

return MapService
