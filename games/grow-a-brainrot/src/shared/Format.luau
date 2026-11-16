-- Number and time formatting shared by server and client.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.number(n: number): string
	if n ~= n or n == math.huge then
		return "∞"
	end
	if n < 0 then
		return "-" .. Format.number(-n)
	end
	if n < 1000 then
		if n < 10 and n ~= math.floor(n) then
			return string.format("%.1f", n)
		end
		return tostring(math.floor(n))
	end
	local exponent = math.floor(math.log10(n))
	local tier = math.floor(exponent / 3)
	if tier < #SUFFIXES then
		local scaled = n / 10 ^ (tier * 3)
		local pattern = if scaled >= 100 then "%.0f%s" elseif scaled >= 10 then "%.1f%s" else "%.2f%s"
		return string.format(pattern, scaled, SUFFIXES[tier + 1])
	end
	return string.format("%.2fe%d", n / 10 ^ exponent, exponent)
end

function Format.cash(n: number): string
	return "$" .. Format.number(n)
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%dh %dm", seconds // 3600, (seconds % 3600) // 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

return Format
