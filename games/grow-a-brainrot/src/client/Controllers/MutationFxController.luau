-- Animated mutation looks that need to run client-side (Rainbow color cycling).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local MutationFxController = {}

local FACE_PARTS = { Eye = true, Pupil = true }
local rainbow = {} -- [Model] = { parts }

local function track(model)
	local parts = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and not FACE_PARTS[p.Name] then
			table.insert(parts, p)
		end
	end
	rainbow[model] = parts
end

function MutationFxController.start()
	for _, model in CollectionService:GetTagged("RainbowMutation") do
		track(model)
	end
	CollectionService:GetInstanceAddedSignal("RainbowMutation"):Connect(function(model)
		task.wait() -- let descendants replicate
		track(model)
	end)
	CollectionService:GetInstanceRemovedSignal("RainbowMutation"):Connect(function(model)
		rainbow[model] = nil
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for model, parts in rainbow do
			if not model.Parent then
				rainbow[model] = nil
				continue
			end
			for i, p in parts do
				p.Color = Color3.fromHSV((t * 0.35 + i * 0.12) % 1, 0.75, 1)
			end
		end
	end)
end

return MutationFxController
