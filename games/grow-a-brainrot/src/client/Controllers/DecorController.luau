-- Animates world decorations locally (smooth, no network cost):
--   "Decor" parts: FloatAmp/FloatSpeed/FloatPhase (bob) and SpinSpeed (deg/s around Y)
--   "Cloud" models: drift slowly along X and wrap around the map

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local DecorController = {}

local MAX_DISTANCE = 300
local decor = {} -- [BasePart] = { base = CFrame, amp, speed, phase, spin }
local clouds = {} -- [Model] = { base = CFrame, speed, offset }

local function addDecor(part)
	if not part:IsA("BasePart") then
		return
	end
	local p = part.Position
	decor[part] = {
		base = part.CFrame,
		amp = part:GetAttribute("FloatAmp") or 0,
		speed = part:GetAttribute("FloatSpeed") or 1,
		phase = part:GetAttribute("FloatPhase") or ((p.X * 0.37 + p.Z * 0.21) % (math.pi * 2)),
		spin = math.rad(part:GetAttribute("SpinSpeed") or 0),
	}
end

local function addCloud(model)
	if model:IsA("Model") then
		clouds[model] = { base = model:GetPivot(), speed = model:GetAttribute("DriftSpeed") or 2, offset = 0 }
	end
end

function DecorController.start()
	for _, part in CollectionService:GetTagged("Decor") do
		addDecor(part)
	end
	CollectionService:GetInstanceAddedSignal("Decor"):Connect(addDecor)
	CollectionService:GetInstanceRemovedSignal("Decor"):Connect(function(part)
		decor[part] = nil
	end)
	for _, model in CollectionService:GetTagged("Cloud") do
		addCloud(model)
	end
	CollectionService:GetInstanceAddedSignal("Cloud"):Connect(function(model)
		task.wait() -- let its parts replicate
		addCloud(model)
	end)
	CollectionService:GetInstanceRemovedSignal("Cloud"):Connect(function(model)
		clouds[model] = nil
	end)

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local camPos = workspace.CurrentCamera.CFrame.Position
		local parts, cframes = {}, {}
		for part, d in decor do
			if not part.Parent then
				decor[part] = nil
			elseif (d.base.Position - camPos).Magnitude < MAX_DISTANCE then
				local cf = d.base
				if d.amp ~= 0 then
					cf = CFrame.new(0, math.sin(t * d.speed + d.phase) * d.amp, 0) * cf
				end
				if d.spin ~= 0 then
					cf = CFrame.new(cf.Position) * CFrame.Angles(0, t * d.spin, 0) * cf.Rotation
				end
				parts[#parts + 1] = part
				cframes[#cframes + 1] = cf
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
		for model, c in clouds do
			if not model.Parent then
				clouds[model] = nil
			else
				c.offset += c.speed * dt
				local x = c.base.Position.X + c.offset
				if x > 280 then
					c.offset -= 560 -- wrap to the other side
				end
				model:PivotTo(c.base + Vector3.new(c.offset, 0, 0))
			end
		end
	end)
end

return DecorController
