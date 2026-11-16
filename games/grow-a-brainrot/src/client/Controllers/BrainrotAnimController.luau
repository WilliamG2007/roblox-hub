-- Brings garden brainrots to life (client-only):
--   pop-in: a new brainrot squashes up from tiny with a springy overshoot
--   idle:   gentle bob + sway, each with its own rhythm
-- Brainrots being carried by a monster ("Carried" attribute) are left alone,
-- since the server is moving them.

local RunService = game:GetService("RunService")

local BrainrotAnimController = {}

local MAX_DISTANCE = 160
local tracked = {} -- [Model] = { base, phase, popStart, scale }

local function easeOutBack(t)
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function track(model, fresh)
	if tracked[model] or not model:IsA("Model") or not string.match(model.Name, "^Brainrot%d+$") then
		return
	end
	task.wait() -- let its parts replicate
	if not model.Parent or not model.PrimaryPart then
		return
	end
	local entry = {
		base = model:GetPivot(),
		phase = math.random() * math.pi * 2,
		scale = model:GetScale(),
		popStart = if fresh then os.clock() else nil,
	}
	tracked[model] = entry
	if fresh then
		model:ScaleTo(entry.scale * 0.15)
	end
	model:GetAttributeChangedSignal("Carried"):Connect(function()
		if not model:GetAttribute("Carried") then
			task.wait(0.1) -- server just put it back on its tile
			entry.base = model:GetPivot()
		end
	end)
end

local function watchPlot(plot)
	for _, child in plot:GetChildren() do
		task.spawn(track, child, false)
	end
	plot.ChildAdded:Connect(function(child)
		track(child, true)
	end)
end

function BrainrotAnimController.start()
	local plots = workspace:WaitForChild("GrowABrainrotWorld"):WaitForChild("Plots")
	for _, plot in plots:GetChildren() do
		watchPlot(plot)
	end
	plots.ChildAdded:Connect(watchPlot)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local camPos = workspace.CurrentCamera.CFrame.Position
		for model, e in tracked do
			if not model.Parent then
				tracked[model] = nil
				continue
			end
			if model:GetAttribute("Carried") then
				continue
			end
			if e.popStart then
				local p = math.clamp((t - e.popStart) / 0.5, 0, 1)
				model:ScaleTo(e.scale * math.max(0.15, easeOutBack(p)))
				if p >= 1 then
					model:ScaleTo(e.scale)
					e.popStart = nil
				end
			end
			if (e.base.Position - camPos).Magnitude < MAX_DISTANCE then
				local bob = math.abs(math.sin(t * 2.2 + e.phase)) * 0.35
				local sway = math.sin(t * 1.6 + e.phase) * math.rad(5)
				model:PivotTo(e.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, sway * 0.4))
			end
		end
	end)
end

return BrainrotAnimController
