-- Seeds in inventory are keyed "<brainrotId>|<mutationId>", e.g. "TungTungTungSahur|Gold".

local Seeds = {}

function Seeds.key(id: string, mutation: string?): string
	return id .. "|" .. (mutation or "Normal")
end

function Seeds.parse(key: string): (string, string)
	local id, mutation = string.match(key, "^([^|]+)|(.+)$")
	if id then
		return id, mutation
	end
	return key, "Normal"
end

return Seeds
