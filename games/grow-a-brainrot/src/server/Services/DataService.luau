-- Loads/saves player data with a simple session lock so two servers never
-- overwrite each other. If loading fails, the player can still play but
-- nothing is saved (so we never wipe real data).

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

local STORE_NAME = "GrowABrainrot_v1"
local LOCK_TIMEOUT = 300 -- a lock older than this is considered stale
local LOAD_RETRIES = 5

local DataService = {}

local store
local profiles = {} -- [Player] = { data = table, canSave = boolean }

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function defaultData()
	return {
		version = 1,
		cash = GameConfig.StartingCash,
		seeds = deepCopy(GameConfig.StarterSeeds), -- ["<id>|<mutation>"] = count
		tiles = {}, -- ["1"] = { id, mutation, plantedAt, growTime, state, size?, stored? }
		index = {}, -- [brainrotId] = true once grown
		shop = { stockId = "", bought = {} },
		pity = {}, -- [packId] = opens since last pity-rarity hit
		stats = { planted = 0, grown = 0, earned = 0 },
		lastSave = 0,
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	-- v1 seeds were keyed by brainrot id only; they become Normal mutation seeds
	for key, count in table.clone(data.seeds) do
		if not string.find(key, "|", 1, true) then
			data.seeds[key] = nil
			data.seeds[key .. "|Normal"] = (data.seeds[key .. "|Normal"] or 0) + count
		end
	end
	return data
end

local function key(player)
	return "u" .. player.UserId
end

function DataService.init()
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	if ok then
		store = result
	else
		warn("[DataService] DataStore unavailable, progress won't save:", result)
	end
end

function DataService.load(player)
	if not store then
		profiles[player] = { data = defaultData(), canSave = false }
		return profiles[player].data, false
	end

	for attempt = 1, LOAD_RETRIES do
		local lockedElsewhere = false
		local loaded
		local ok, err = pcall(store.UpdateAsync, store, key(player), function(old)
			local now = os.time()
			old = old or defaultData()
			if old.lock and old.lock.job ~= game.JobId and now - (old.lock.time or 0) < LOCK_TIMEOUT then
				lockedElsewhere = true
				return nil -- abort; another server still owns this data
			end
			old.lock = { job = game.JobId, time = now }
			loaded = old
			return old
		end)
		if ok and loaded then
			profiles[player] = { data = reconcile(loaded), canSave = true }
			return profiles[player].data, true
		end
		warn(string.format("[DataService] load attempt %d for %s failed: %s", attempt, player.Name, if lockedElsewhere then "locked by another server" else tostring(err)))
		if not player.Parent then
			break
		end
		task.wait(if lockedElsewhere then 6 else 2)
	end

	profiles[player] = { data = defaultData(), canSave = false }
	return profiles[player].data, false
end

function DataService.get(player)
	local profile = profiles[player]
	return profile and profile.data
end

function DataService.canSave(player)
	local profile = profiles[player]
	return profile ~= nil and profile.canSave
end

function DataService.save(player, release: boolean?)
	local profile = profiles[player]
	if not profile or not profile.canSave or not store then
		return
	end
	local data = profile.data
	data.lastSave = os.time()
	local ok, err = pcall(store.UpdateAsync, store, key(player), function(old)
		if old and old.lock and old.lock.job ~= game.JobId then
			return nil -- someone else took over; don't clobber
		end
		data.lock = if release then nil else { job = game.JobId, time = os.time() }
		return data
	end)
	if not ok then
		warn("[DataService] save failed for", player.Name, err)
	end
end

function DataService.release(player)
	DataService.save(player, true)
	profiles[player] = nil
end

function DataService.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveInterval)
			for player in profiles do
				task.spawn(DataService.save, player)
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 20
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
