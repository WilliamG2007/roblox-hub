-- Sound playback for the whole client.
--   Sfx.play("pop")                 2D (UI / your own actions)
--   Sfx.playAt("pop", position)     3D, quieter with distance (other players' stuff)
--   Sfx.music("music_night")        crossfades the background music
-- Sounds are defined in shared/Config/Sounds (volume, pitch range, cooldown, group).

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sounds"))

local Sfx = {}

local groups = {}
local templates = {}
local lastPlayed = {}
local rng = Random.new()
local currentMusic, currentMusicName

local root = Instance.new("Folder")
root.Name = "Sfx"
root.Parent = SoundService

for name, volume in Sounds.GroupVolumes do
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = volume
	group.Parent = SoundService
	groups[name] = group
end

local preload = {}
for name, def in Sounds do
	if type(def) == "table" and def.id then
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = def.id
		sound.Volume = def.volume or 0.5
		sound.Looped = def.loop == true
		sound.SoundGroup = groups[def.group]
		sound.Parent = root
		templates[name] = sound
		table.insert(preload, sound)
	end
end
task.spawn(function()
	pcall(ContentProvider.PreloadAsync, ContentProvider, preload)
end)

local function ready(name)
	local def = Sounds[name]
	local template = templates[name]
	if not def or not template then
		return nil
	end
	local now = os.clock()
	if def.cooldown and now - (lastPlayed[name] or 0) < def.cooldown then
		return nil
	end
	lastPlayed[name] = now
	return def, template
end

local function pitchFor(def, override)
	if override then
		return override
	end
	if def.pitch then
		return rng:NextNumber(def.pitch[1], def.pitch[2])
	end
	return 1
end

-- opts: { pitch = number?, volume = number? (multiplier) }
function Sfx.play(name: string, opts: { pitch: number?, volume: number? }?)
	local def, template = ready(name)
	if not def then
		return
	end
	local sound = template:Clone()
	sound.PlaybackSpeed = pitchFor(def, opts and opts.pitch)
	sound.Volume = template.Volume * (opts and opts.volume or 1)
	sound.Parent = root
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function Sfx.playAt(name: string, position: Vector3, opts: { pitch: number?, volume: number? }?)
	local def, template = ready(name)
	if not def then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	local sound = template:Clone()
	sound.PlaybackSpeed = pitchFor(def, opts and opts.pitch)
	sound.Volume = template.Volume * (opts and opts.volume or 1)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 15
	sound.RollOffMaxDistance = 180
	sound.Parent = attachment
	sound:Play()
	task.delay(10, function()
		attachment:Destroy()
	end)
end

function Sfx.music(name: string?)
	if name == currentMusicName then
		return
	end
	local fade = TweenInfo.new(2.5)
	if currentMusic then
		local old = currentMusic
		TweenService:Create(old, fade, { Volume = 0 }):Play()
		task.delay(2.6, function()
			old:Destroy()
		end)
	end
	currentMusicName = name
	currentMusic = nil
	local template = name and templates[name]
	if not template then
		return
	end
	local sound = template:Clone()
	local target = sound.Volume
	sound.Volume = 0
	sound.Looped = true
	sound.Parent = root
	sound:Play()
	TweenService:Create(sound, fade, { Volume = target }):Play()
	currentMusic = sound
end

function Sfx.setGroupVolume(group: string, volume: number)
	if groups[group] then
		groups[group].Volume = volume
	end
end

return Sfx
