-- Client entry point: starts each controller in ./Controllers.
-- Each controller exposes start(controllers) and may call into the others.

local ORDER = { "State", "EffectsController", "HudController", "ShopController", "PlantController", "GrowthController" }

local controllers = {}
for _, name in ORDER do
	controllers[name] = require(script.Parent.Controllers[name])
end
for _, name in ORDER do
	task.spawn(controllers[name].start, controllers)
end
