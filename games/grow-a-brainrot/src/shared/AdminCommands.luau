-- Admin command list (data only) so the admin panel can show help.
-- The server implements each one in AdminService. Type them in chat with a "/"
-- or in the admin panel without it.
-- [target] = me (default), all, or the start of a player's name.

return {
	{ name = "help", usage = "help", desc = "List all commands" },
	{ name = "luck", usage = "luck [mult=3] [seconds=60]", desc = "Server luck event" },
	{ name = "mutluck", usage = "mutluck [mult=6.7] [seconds=67]", desc = "Mutation luck event" },
	{ name = "event", usage = "event <luck> <mutluck> <seconds> <NAME...>", desc = "Custom luck event with your own name" },
	{ name = "endevent", usage = "endevent", desc = "Stop the current luck event" },
	{ name = "givepack", usage = "givepack <pack 1-10|name> [count=1] [target=all]", desc = "Free packs (plays the reveal)" },
	{ name = "seed", usage = "seed <brainrot> [mutation=Normal] [count=1] [target]", desc = "Give seeds directly" },
	{ name = "cash", usage = "cash <amount> [target]", desc = "Add cash" },
	{ name = "setcash", usage = "setcash <amount> [target]", desc = "Set cash exactly" },
	{ name = "wander", usage = "wander [brainrot|random] [mutation] [free]", desc = "Send a wild brainrot down the road" },
	{ name = "night", usage = "night [boss]", desc = "Start the night now (add 'boss' for a 67 NIGHT)" },
	{ name = "day", usage = "day", desc = "Skip to day (monsters flee)" },
	{ name = "spawn", usage = "spawn [count=3]", desc = "Spawn Grumblers right now" },
	{ name = "boss", usage = "boss", desc = "Spawn THE 67 right now" },
	{ name = "shards", usage = "shards <amount> [target]", desc = "Add Moon Shards" },
	{ name = "pass", usage = "pass <FastRoll> [target]", desc = "Toggle a gamepass perk (testing)" },
	{ name = "restock", usage = "restock", desc = "Instant new shop stock" },
	{ name = "stock", usage = "stock <pack> [qty=5]", desc = "Put a pack into the current stock" },
	{ name = "grow", usage = "grow [target]", desc = "Finish all growing plants instantly" },
	{ name = "clear", usage = "clear [target]", desc = "Remove everything from a garden" },
	{ name = "reset", usage = "reset <target>", desc = "Wipe a player's save back to new (careful!)" },
	{ name = "announce", usage = "announce <text...>", desc = "Big announcement to the server" },
	{ name = "speed", usage = "speed <walkspeed> [target]", desc = "Set walk speed" },
	{ name = "tp", usage = "tp <target>", desc = "Teleport to a player's garden" },
}
