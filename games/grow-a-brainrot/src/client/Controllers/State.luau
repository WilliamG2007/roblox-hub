-- Holds the latest state snapshot from the server and announces changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local State = {}

State.data = nil
local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

function State.start()
	Remotes.get("State").OnClientEvent:Connect(function(data)
		State.data = data
		changed:Fire(data)
	end)
end

return State
