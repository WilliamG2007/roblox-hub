-- All RemoteEvents in one place. Server calls setup(); both sides use get(name).
--   State  server -> client  full player state snapshot
--   Fx     server -> client  one-shot events (pops, toasts, collects...)
--   Plant    client -> server  (tileIndex, seedKey)
--   BuyPack  client -> server  (packId, count)
--   Admin    client -> server  (commandText)  admin panel; server re-checks permissions
--   Inventory client -> server (action, ...)  "Sell" key count | "SellRarity" rarity | "AutoSell" rarity bool

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = { "State", "Fx", "Plant", "BuyPack", "Admin", "Inventory" }
local FOLDER_NAME = "Remotes"

local Remotes = {}

function Remotes.setup()
	assert(RunService:IsServer(), "Remotes.setup is server-only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) or Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
end

function Remotes.get(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild(FOLDER_NAME):WaitForChild(name)
end

return Remotes
