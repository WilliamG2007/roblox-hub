-- Every sound in the game, by name. IDs come from SoundIds (filled in by
-- tools/upload_audio.py). Until a sound is uploaded it falls back to one of the
-- few sounds that ship with Roblox itself (verified to exist in content/sounds).
--   group     UI | SFX | Music   (separate volume buckets)
--   volume    base volume
--   pitch     random pitch range for variety ({ min, max })
--   cooldown  minimum seconds between plays (stops spammy stacking)

local SoundIds = require(script.Parent.SoundIds)

local BUILTIN = {
	tick = "rbxasset://sounds/volume_slider.ogg",
	boing = "rbxasset://sounds/action_jump.mp3",
	thud = "rbxasset://sounds/action_jump_land.mp3",
	boom = "rbxasset://sounds/impact_explosion_03.mp3",
	splash = "rbxasset://sounds/impact_water.mp3",
}

local defs = {
	-- UI
	ui_click = { group = "UI", volume = 0.5, pitch = { 0.95, 1.05 }, cooldown = 0.03, fallback = BUILTIN.tick },
	ui_hover = { group = "UI", volume = 0.25, pitch = { 0.97, 1.03 }, cooldown = 0.05 },
	ui_open = { group = "UI", volume = 0.45, cooldown = 0.1, fallback = BUILTIN.tick },
	ui_close = { group = "UI", volume = 0.4, cooldown = 0.1, fallback = BUILTIN.tick },
	ui_select = { group = "UI", volume = 0.45, pitch = { 0.98, 1.04 }, cooldown = 0.03, fallback = BUILTIN.tick },
	ui_error = { group = "UI", volume = 0.45, cooldown = 0.2, fallback = BUILTIN.thud },
	notify = { group = "UI", volume = 0.45, cooldown = 0.15, fallback = BUILTIN.tick },
	purchase = { group = "UI", volume = 0.55, cooldown = 0.05, fallback = BUILTIN.boing },
	sell = { group = "UI", volume = 0.5, pitch = { 0.97, 1.05 }, cooldown = 0.05, fallback = BUILTIN.tick },

	-- gameplay
	plant = { group = "SFX", volume = 0.6, pitch = { 0.9, 1.1 }, cooldown = 0.05, fallback = BUILTIN.thud },
	pop = { group = "SFX", volume = 0.55, pitch = { 0.92, 1.1 }, cooldown = 0.05, fallback = BUILTIN.boing },
	pop_rare = { group = "SFX", volume = 0.65, cooldown = 0.1, fallback = BUILTIN.boing },
	collect = { group = "SFX", volume = 0.6, pitch = { 0.98, 1.05 }, cooldown = 0.15, fallback = BUILTIN.tick },
	cash_small = { group = "SFX", volume = 0.4, pitch = { 0.95, 1.15 }, cooldown = 0.04, fallback = BUILTIN.tick },
	reveal_tick = { group = "SFX", volume = 0.35, pitch = { 0.95, 1.08 }, cooldown = 0.02, fallback = BUILTIN.tick },
	reveal_land = { group = "SFX", volume = 0.6, cooldown = 0.05, fallback = BUILTIN.thud },
	reveal_rare = { group = "SFX", volume = 0.7, cooldown = 0.2, fallback = BUILTIN.boing },
	mutation_hit = { group = "SFX", volume = 0.65, cooldown = 0.1, fallback = BUILTIN.boing },
	unlock = { group = "SFX", volume = 0.55, cooldown = 0.2, fallback = BUILTIN.boing },
	luck_event = { group = "SFX", volume = 0.6, cooldown = 1, fallback = BUILTIN.boing },
	restock = { group = "SFX", volume = 0.5, cooldown = 1, fallback = BUILTIN.tick },
	announce = { group = "SFX", volume = 0.5, cooldown = 0.5, fallback = BUILTIN.tick },
	night_start = { group = "SFX", volume = 0.6, cooldown = 2 },
	day_start = { group = "SFX", volume = 0.55, cooldown = 2, fallback = BUILTIN.tick },
	bonk = { group = "SFX", volume = 0.55, pitch = { 0.9, 1.15 }, cooldown = 0.05, fallback = BUILTIN.thud },
	zap = { group = "SFX", volume = 0.18, pitch = { 0.85, 1.2 }, cooldown = 0.08 },
	monster_die = { group = "SFX", volume = 0.55, pitch = { 0.9, 1.1 }, cooldown = 0.08, fallback = BUILTIN.boing },
	shards = { group = "SFX", volume = 0.45, pitch = { 0.98, 1.06 }, cooldown = 0.1, fallback = BUILTIN.tick },
	stomp = { group = "SFX", volume = 0.8, cooldown = 0.3, fallback = BUILTIN.boom },
	wander_spawn = { group = "SFX", volume = 0.55, cooldown = 1, fallback = BUILTIN.boing },

	-- music (only plays once uploaded; no built-in fallback)
	music_day = { group = "Music", volume = 0.35, loop = true },
	music_night = { group = "Music", volume = 0.35, loop = true },
}

local Sounds = {}
for name, def in defs do
	def.name = name
	def.id = SoundIds[name] or def.fallback
	Sounds[name] = def
end

-- group volumes (mix): music sits well under effects
Sounds.GroupVolumes = { UI = 0.8, SFX = 0.9, Music = 0.5 }

return Sounds
