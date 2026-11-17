-- Gamepasses + developer products.
--   passes: ownership becomes a player attribute ("Pass_DoubleCash" = true);
--           server code checks owns(player, name)
--   products: ProcessReceipt grants each receipt exactly once (receipt IDs are
--             stored in the player's save before we confirm the purchase)
--   policy: players where paid random items are restricted get the attribute
--           "RandomRestricted"; the store hides random-affecting products for them

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePasses = require(ReplicatedStorage.Shared.Config.GamePasses)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MonetizationService = {}

local services
local fx
local GOLD = Color3.fromRGB(255, 215, 80)

local function passes()
	local list = {}
	for name, pass in GamePasses do
		if name ~= "Products" then
			list[name] = pass
		end
	end
	return list
end

local function attribute(name)
	return "Pass_" .. name
end

function MonetizationService.owns(player, name: string): boolean
	return player:GetAttribute(attribute(name)) == true
end

-- admin/testing override
function MonetizationService.setOwned(player, name: string, owned: boolean)
	player:SetAttribute(attribute(name), owned)
	MonetizationService.refreshTag(player)
	services.SyncService.mark(player)
end

-- personal Luck Potion multiplier (1 when none is active)
function MonetizationService.personalLuck(player): number
	local data = services.DataService.get(player)
	if data and data.luckUntil > os.time() then
		return GamePasses.Products.LuckPotion.luck
	end
	return 1
end

-- VIP tag over the player's head
function MonetizationService.refreshTag(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local existing = head:FindFirstChild("VipTag")
	if MonetizationService.owns(player, "VIP") then
		if existing then
			return
		end
		local tag = Instance.new("BillboardGui")
		tag.Name = "VipTag"
		tag.Size = UDim2.fromOffset(120, 36)
		tag.StudsOffset = Vector3.new(0, 2.6, 0)
		tag.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.LuckiestGuy
		label.TextScaled = true
		label.Text = "👑 VIP"
		label.TextColor3 = GOLD
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(35, 24, 58)
		stroke.Thickness = 2.5
		stroke.Parent = label
		label.Parent = tag
		tag.Parent = head
	elseif existing then
		existing:Destroy()
	end
end

--------------------------------------------------------------------------------
-- products

local grants = {}

function grants.CashSmall(player, product)
	local amount = math.max(product.min, services.GardenService.getIncome(player) * product.incomeSeconds)
	services.EconomyService.add(player, amount)
	return "+" .. Format.cash(amount)
end
grants.CashLarge = grants.CashSmall

function grants.LuckPotion(player, product)
	local data = services.DataService.get(player)
	data.luckUntil = math.max(data.luckUntil, os.time()) + product.duration
	return string.format("x%d luck for %d minutes!", product.luck, product.duration // 60)
end

function grants.InstantRestock(player)
	local data = services.DataService.get(player)
	data.shop.bought = {}
	return "Your pack stock is full again!"
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and services.DataService.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries later
	end
	local key = tostring(receipt.PurchaseId)
	if data.purchases[key] then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted
	end
	local name, product
	for productName, def in GamePasses.Products do
		if def.id ~= 0 and def.id == receipt.ProductId then
			name, product = productName, def
		end
	end
	if not product then
		warn("[Monetization] unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, result = pcall(grants[name], player, product)
	if not ok then
		warn("[Monetization] grant failed:", result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.purchases[key] = true
	-- persist before confirming so a crash can't grant twice or lose it
	services.DataService.save(player)
	services.SyncService.mark(player)
	services.AnalyticsService.economy(player, "Source", "Robux", product.price or 0, 0, "IAP", name)
	fx:FireClient(player, "Celebrate", nil, GOLD, "THANK YOU!")
	fx:FireClient(player, "Toast", product.name .. ": " .. tostring(result), GOLD)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

--------------------------------------------------------------------------------

local function check(player)
	for name, pass in passes() do
		if pass.id ~= 0 then
			local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok and owned then
				player:SetAttribute(attribute(name), true)
			end
		end
	end
	local ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	-- if the policy check fails, play it safe and treat random items as restricted
	player:SetAttribute("RandomRestricted", not ok or policy.ArePaidRandomItemsRestricted == true)
	player:SetAttribute("TradingAllowed", ok and policy.IsPaidItemTradingAllowed == true)
	MonetizationService.refreshTag(player)
end

function MonetizationService.init(s)
	services = s
	fx = Remotes.get("Fx")
end

function MonetizationService.start()
	local function onPlayer(player)
		check(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 5)
			MonetizationService.refreshTag(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for name, pass in passes() do
			if pass.id == passId then
				player:SetAttribute(attribute(name), true)
				fx:FireClient(player, "Celebrate", nil, GOLD, pass.name .. " UNLOCKED!")
				MonetizationService.refreshTag(player)
				services.SyncService.mark(player)
			end
		end
	end)
	MarketplaceService.ProcessReceipt = processReceipt
end

return MonetizationService
