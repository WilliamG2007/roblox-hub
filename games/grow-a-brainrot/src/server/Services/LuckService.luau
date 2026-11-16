-- Server-wide luck: random luck events every 15-25 min, plus admin-triggered ones.
-- Current luck is published as ReplicatedStorage attributes so every client can
-- show a banner and the shop can show live (boosted) odds:
--   Luck, MutationLuck, LuckEventName, LuckEndsAt

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local LuckService = {}

local fx
local current = { luck = 1, mutationLuck = 1, name = "", endsAt = 0, token = 0 }

local function publish()
	ReplicatedStorage:SetAttribute("Luck", current.luck)
	ReplicatedStorage:SetAttribute("MutationLuck", current.mutationLuck)
	ReplicatedStorage:SetAttribute("LuckEventName", current.name)
	ReplicatedStorage:SetAttribute("LuckEndsAt", current.endsAt)
end

function LuckService.getLuck(): number
	return current.luck
end

function LuckService.getMutationLuck(): number
	return current.mutationLuck
end

function LuckService.startEvent(name: string, luck: number, mutationLuck: number, duration: number)
	current.token += 1
	local token = current.token
	current.luck = math.max(1, luck)
	current.mutationLuck = math.max(1, mutationLuck)
	current.name = name
	current.endsAt = workspace:GetServerTimeNow() + duration
	publish()
	fx:FireAllClients("LuckEvent", name, current.luck, current.mutationLuck, duration)
	task.delay(duration, function()
		if current.token == token then
			current.luck, current.mutationLuck, current.name, current.endsAt = 1, 1, "", 0
			publish()
		end
	end)
end

function LuckService.endEvent()
	current.token += 1
	current.luck, current.mutationLuck, current.name, current.endsAt = 1, 1, "", 0
	publish()
end

function LuckService.init()
	fx = Remotes.get("Fx")
	publish()
end

function LuckService.start()
	local events = GameConfig.LuckEvents
	task.spawn(function()
		while true do
			task.wait(math.random(events.MinInterval, events.MaxInterval))
			if current.endsAt < workspace:GetServerTimeNow() then
				local event = events.List[math.random(#events.List)]
				LuckService.startEvent(event.name, event.luck, event.mutationLuck, event.duration)
			end
		end
	end)
end

return LuckService
