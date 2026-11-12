--!strict
-- Suspicion bands. The server picks the band from the suspicion number.
-- A band may blink one tube, dim the car slowly, or leave the lamps alone.
-- It never blacks the whole car out. That remains the flicker tick.

local Band = {}

function Band.fromSuspicion(value: number, calmMax: number, uneasyMax: number, watchedMax: number): string
	if value <= calmMax then
		return "calm"
	end
	if value <= uneasyMax then
		return "uneasy"
	end
	if value <= watchedMax then
		return "watched"
	end
	return "hunted"
end

-- Lamp action. "blackout" is not a band, and it is not returned.
function Band.light(band: string): string
	if band == "uneasy" then
		return "strip"
	end
	if band == "hunted" then
		return "dim"
	end
	return "none"
end

function Band.blacksOutCar(effect: string): boolean
	return effect == "blackout" or effect == "whole_car"
end

-- A hunted dim stays above off. Zero would be a blackout.
function Band.dimTarget(fraction: number): number
	if fraction <= 0 then
		return 0.5
	end
	return math.clamp(fraction, 0.05, 1)
end

-- Repeat the second word of an existing line. No new word is added.
function Band.glitchLine(line: string): string
	if line == "" then
		return ""
	end
	local words = string.split(line, " ")
	if #words == 0 then
		return line
	end
	local index = if #words >= 2 then 2 else 1
	table.insert(words, index + 1, words[index])
	return table.concat(words, " ")
end

-- Added to a false-stop roll at WATCHED. This slice's stops are a fixed
-- table, so the ride publishes the number and does not reroll them.
function Band.falseStopBonus(band: string, bonus: number): number
	if band == "watched" then
		return bonus
	end
	return 0
end

-- What the client does with heads. The server does not pose them.
function Band.look(band: string): string
	if band == "uneasy" then
		return "glance"
	end
	if band == "watched" then
		return "turn"
	end
	return "none"
end

return Band
