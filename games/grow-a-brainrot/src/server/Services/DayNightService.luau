-- Server-wide day/night cycle. Publishes the phase as ReplicatedStorage
-- attributes (Phase, PhaseEndsAt, NightNumber, BossNight) for the HUD, fades
-- the lighting, and fires NightStarted / DayStarted for MonsterService.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DayNightService = {}

local config = GameConfig.Night
local fx
local nightStarted = Instance.new("BindableEvent")
local dayStarted = Instance.new("BindableEvent")
DayNightService.NightStarted = nightStarted.Event -- (nightNumber, isBoss)
DayNightService.DayStarted = dayStarted.Event

local state = { phase = "Day", endsAt = 0, night = 0, boss = false }

local LOOKS = {
	Day = {
		lighting = { ClockTime = 14, Brightness = 2.6, Ambient = Color3.fromRGB(125, 120, 140), OutdoorAmbient = Color3.fromRGB(150, 150, 170) },
		tint = Color3.fromRGB(255, 255, 255),
	},
	Night = {
		lighting = { ClockTime = 23.5, Brightness = 1.2, Ambient = Color3.fromRGB(80, 60, 140), OutdoorAmbient = Color3.fromRGB(90, 70, 160) },
		tint = Color3.fromRGB(200, 180, 255),
	},
}

local function publish()
	ReplicatedStorage:SetAttribute("Phase", state.phase)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", state.endsAt)
	ReplicatedStorage:SetAttribute("NightNumber", state.night)
	ReplicatedStorage:SetAttribute("BossNight", state.boss)
end

local function fade(phase)
	local look = LOOKS[phase]
	local info = TweenInfo.new(4, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, look.lighting):Play()
	local cc = Lighting:FindFirstChild("GrowABrainrotCC")
	if cc then
		TweenService:Create(cc, info, { TintColor = look.tint }):Play()
	end
end

function DayNightService.isNight(): boolean
	return state.phase == "Night"
end

function DayNightService.nightNumber(): number
	return state.night
end

function DayNightService.isBossNight(): boolean
	return state.phase == "Night" and state.boss
end

function DayNightService.startNight(forceBoss: boolean?)
	state.night += 1
	state.boss = forceBoss == true or state.night % config.BossEvery == 0
	state.phase = "Night"
	state.endsAt = workspace:GetServerTimeNow() + config.NightSeconds
	publish()
	fade("Night")
	fx:FireAllClients("Phase", "Night", state.night, state.boss)
	nightStarted:Fire(state.night, state.boss)
end

function DayNightService.startDay()
	state.phase = "Day"
	state.boss = false
	state.endsAt = workspace:GetServerTimeNow() + config.DaySeconds
	publish()
	fade("Day")
	fx:FireAllClients("Phase", "Day", state.night, false)
	dayStarted:Fire()
end

function DayNightService.init()
	fx = Remotes.get("Fx")
	state.endsAt = workspace:GetServerTimeNow() + config.DaySeconds
	publish()
end

function DayNightService.start()
	task.spawn(function()
		while true do
			task.wait(0.5)
			if workspace:GetServerTimeNow() >= state.endsAt then
				if state.phase == "Day" then
					DayNightService.startNight()
				else
					DayNightService.startDay()
				end
			end
		end
	end)
end

return DayNightService
