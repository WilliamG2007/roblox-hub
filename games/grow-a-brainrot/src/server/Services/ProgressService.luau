-- Player progression loops:
--   tutorial      first-session guide; steps complete on tracked events
--   daily login   7-day streak with growing rewards (UTC days)
--   daily quests  3 per day from a pool, claim for rewards
--   Index         claim a permanent income bonus per completed rarity row
--   rebirth       reset for a permanent income multiplier + pack unlocks
-- Other services report what happened with ProgressService.track(player, event, amount).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Progress = require(Shared.Config.Progress)
local GameConfig = require(Shared.Config.Game)
local Brainrots = require(Shared.Config.Brainrots)
local Packs = require(Shared.Config.Packs)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local ProgressService = {}

local services
local fx
local GOLD = Color3.fromRGB(255, 215, 80)

local function today()
	return math.floor(os.time() / 86400)
end

local function copy(t)
	local c = {}
	for k, v in t do
		c[k] = if type(v) == "table" then copy(v) else v
	end
	return c
end

--------------------------------------------------------------------------------
-- rewards

function ProgressService.cashAmount(player, spec): number
	return math.floor(math.max(spec.min or 0, services.GardenService.getIncome(player) * (spec.incomeSeconds or 0)))
end

-- grants a reward table { cash = spec, shards = n, pack = id, packCount = n } and returns a description
function ProgressService.grant(player, reward, txType: string?): string
	local data = services.DataService.get(player)
	if not data then
		return ""
	end
	local parts = {}
	if reward.cash then
		local amount = ProgressService.cashAmount(player, reward.cash)
		services.EconomyService.add(player, amount)
		services.AnalyticsService.economy(player, "Source", "Cash", amount, data.cash, txType or "TimedReward")
		table.insert(parts, "+" .. Format.cash(amount))
	end
	if reward.shards then
		data.shards += reward.shards
		table.insert(parts, "+" .. reward.shards .. " Moon Shards")
	end
	if reward.pack and Packs.byId[reward.pack] then
		local count = reward.packCount or 1
		services.ShopService.openPacks(player, Packs.byId[reward.pack], count)
		table.insert(parts, (if count > 1 then count .. "x " else "") .. Packs.byId[reward.pack].name)
	end
	services.SyncService.mark(player)
	return table.concat(parts, ", ")
end

--------------------------------------------------------------------------------
-- quests

local function ensureQuests(player, data)
	local day = today()
	if data.quests.day == day then
		return
	end
	local rng = Random.new(day * 7919 + player.UserId % 100003)
	local pool = table.clone(Progress.QuestPool)
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local list = {}
	for i = 1, math.min(Progress.QuestsPerDay, #pool) do
		table.insert(list, { id = pool[i].id, progress = 0, done = false, claimed = false })
	end
	data.quests = { day = day, list = list }
end

local function questDef(id)
	for _, def in Progress.QuestPool do
		if def.id == id then
			return def
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- tracking

function ProgressService.track(player, event: string, amount: number?)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	amount = amount or 1

	-- tutorial
	local step = Progress.Tutorial[data.tutorial]
	if step and step.event == event then
		data.tutorialProgress += amount
		if data.tutorialProgress >= step.goal then
			local stepIndex = data.tutorial
			data.tutorial += 1
			data.tutorialProgress = 0
			services.AnalyticsService.funnel(player, stepIndex, step.id)
			task.defer(function()
				local text = ProgressService.grant(player, step.reward, "Onboarding")
				local done = data.tutorial > #Progress.Tutorial
				fx:FireClient(player, "TutorialStep", stepIndex, text, done)
			end)
		end
	end

	-- daily quests
	ensureQuests(player, data)
	for _, quest in data.quests.list do
		local def = questDef(quest.id)
		if def and def.event == event and not quest.done then
			quest.progress = math.min(def.goal, quest.progress + amount)
			if quest.progress >= def.goal then
				quest.done = true
				fx:FireClient(player, "Toast", "Quest complete: " .. string.format(def.text, def.goal) .. "! Claim it in Quests.", GOLD)
			end
		end
	end
	services.SyncService.mark(player)
end

--------------------------------------------------------------------------------
-- multipliers (read by GardenService)

function ProgressService.indexCompleted(data, rarityName: string): boolean
	for _, def in Brainrots.byRarity[rarityName] or {} do
		if not data.index[def.id] then
			return false
		end
	end
	return true
end

function ProgressService.incomeMultiplier(data): number
	local claimed = 0
	for _ in data.indexClaimed do
		claimed += 1
	end
	return (1 + data.rebirths * Progress.Rebirth.IncomeBonus) * (1 + claimed * Progress.IndexBonusPerRarity)
end

--------------------------------------------------------------------------------
-- actions from the client

local actions = {}

function actions.ClaimDaily(player, data)
	local day = today()
	if data.daily.lastDay ~= day or data.daily.claimedDay == day then
		return
	end
	data.daily.claimedDay = day
	local reward = Progress.LoginRewards[data.daily.streak] or Progress.LoginRewards[1]
	local text = ProgressService.grant(player, reward, "TimedReward")
	fx:FireClient(player, "Celebrate", nil, GOLD, string.format("DAY %d REWARD!", data.daily.streak))
	fx:FireClient(player, "Toast", string.format("Day %d login reward: %s", data.daily.streak, text), GOLD)
end

function actions.ClaimQuest(player, data, index)
	ensureQuests(player, data)
	local quest = type(index) == "number" and data.quests.list[index]
	local def = quest and questDef(quest.id)
	if not quest or not def or not quest.done or quest.claimed then
		return
	end
	quest.claimed = true
	local text = ProgressService.grant(player, def.reward, "Gameplay")
	fx:FireClient(player, "Toast", "Quest reward: " .. text, GOLD)
	services.SyncService.mark(player)
end

function actions.ClaimIndex(player, data, rarityName)
	if type(rarityName) ~= "string" or data.indexClaimed[rarityName] or not ProgressService.indexCompleted(data, rarityName) then
		return
	end
	data.indexClaimed[rarityName] = true
	fx:FireClient(player, "Celebrate", nil, GOLD, rarityName:upper() .. " INDEX COMPLETE!")
	fx:FireClient(player, "Toast", string.format("%s row complete! +%d%% income forever.", rarityName, Progress.IndexBonusPerRarity * 100), GOLD)
	services.SyncService.mark(player)
end

function actions.Rebirth(player, data)
	local cost = Progress.rebirthCost(data.rebirths)
	if data.cash < cost then
		fx:FireClient(player, "Toast", "You need " .. Format.cash(cost) .. " to rebirth!", Color3.fromRGB(255, 120, 120))
		return
	end
	data.rebirths += 1
	services.AnalyticsService.economy(player, "Sink", "Cash", data.cash, 0, "Gameplay", "Rebirth")
	services.GardenService.clearGarden(player)
	data.cash = GameConfig.StartingCash
	data.seeds = copy(GameConfig.StarterSeeds)
	data.pity = {}
	services.SyncService.mark(player)
	fx:FireClient(player, "Celebrate", nil, Color3.fromRGB(200, 120, 255), "REBIRTH " .. data.rebirths .. "!")
	services.FameService.record(string.format("%s REBIRTHED! (Rebirth %d, x%.1f income)", player.DisplayName, data.rebirths, ProgressService.incomeMultiplier(data)), Color3.fromRGB(200, 120, 255))
	services.AnalyticsService.event(player, "Rebirth", data.rebirths)
end

function actions.SkipTutorial(player, data)
	if data.tutorial <= #Progress.Tutorial then
		services.AnalyticsService.funnel(player, data.tutorial, "skipped")
		data.tutorial = #Progress.Tutorial + 1
		services.SyncService.mark(player)
	end
end

--------------------------------------------------------------------------------

-- called when a player's data is loaded (before they claim a garden)
function ProgressService.onPlayerLoaded(player)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	-- veterans from before the tutorial existed skip it
	if data.tutorial == 1 and data.stats.grown > 0 then
		data.tutorial = #Progress.Tutorial + 1
	end
	-- login streak
	local day = today()
	if data.daily.lastDay ~= day then
		data.daily.streak = if data.daily.lastDay == day - 1 then data.daily.streak % #Progress.LoginRewards + 1 else 1
		data.daily.lastDay = day
	end
	ensureQuests(player, data)
	services.SyncService.mark(player)
end

-- snapshot for the client
function ProgressService.snapshot(player)
	local data = services.DataService.get(player)
	if not data then
		return nil
	end
	ensureQuests(player, data)
	local quests = {}
	for _, quest in data.quests.list do
		local def = questDef(quest.id)
		if def then
			table.insert(quests, { text = string.format(def.text, def.goal), progress = quest.progress, goal = def.goal, done = quest.done, claimed = quest.claimed })
		end
	end
	local day = today()
	return {
		tutorial = data.tutorial,
		tutorialProgress = data.tutorialProgress,
		quests = quests,
		questsResetIn = (day + 1) * 86400 - os.time(),
		streak = data.daily.streak,
		dailyClaimable = data.daily.lastDay == day and data.daily.claimedDay ~= day,
		rebirths = data.rebirths,
		rebirthCost = Progress.rebirthCost(data.rebirths),
		indexClaimed = data.indexClaimed,
		multiplier = services.GardenService.getMultiplier(player),
	}
end

function ProgressService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function ProgressService.start()
	Remotes.get("Progress").OnServerEvent:Connect(function(player, action, ...)
		local handler = type(action) == "string" and actions[action]
		local data = services.DataService.get(player)
		if handler and data then
			handler(player, data, ...)
		end
	end)
	-- quests roll over at midnight UTC for players who stay online
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				local data = services.DataService.get(player)
				if data and data.quests.day ~= today() then
					ProgressService.onPlayerLoaded(player)
				end
			end
		end
	end)
end

return ProgressService
