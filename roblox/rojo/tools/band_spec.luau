--!strict
-- Suspicion bands. No band blacks out the whole car.
-- Run: luau tools/band_spec.luau
-- Thresholds match src/shared/Constants.luau.

local Band = require("../src/shared/Band")

local CALM = 24
local UNEASY = 49
local WATCHED = 74

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local function words(line: string): { string }
	local list = {}
	for word in string.gmatch(line, "%S+") do
		table.insert(list, word)
	end
	return list
end

local function hasWord(line: string, word: string): boolean
	for _, item in words(line) do
		if item == word then
			return true
		end
	end
	return false
end

check("0 is calm", Band.fromSuspicion(0, CALM, UNEASY, WATCHED) == "calm")
check("24 is calm", Band.fromSuspicion(24, CALM, UNEASY, WATCHED) == "calm")
check("25 is uneasy", Band.fromSuspicion(25, CALM, UNEASY, WATCHED) == "uneasy")
check("49 is uneasy", Band.fromSuspicion(49, CALM, UNEASY, WATCHED) == "uneasy")
check("50 is watched", Band.fromSuspicion(50, CALM, UNEASY, WATCHED) == "watched")
check("74 is watched", Band.fromSuspicion(74, CALM, UNEASY, WATCHED) == "watched")
check("75 is hunted", Band.fromSuspicion(75, CALM, UNEASY, WATCHED) == "hunted")
check("100 is hunted", Band.fromSuspicion(100, CALM, UNEASY, WATCHED) == "hunted")

check("calm does nothing to the lamps", Band.light("calm") == "none")
check("uneasy is one strip", Band.light("uneasy") == "strip")
check("watched does not touch the lamps", Band.light("watched") == "none")
check("hunted is a dim", Band.light("hunted") == "dim")
check("a blackout request is not used", Band.light("blackout") == "none")

check("strip is not a whole-car flicker", Band.blacksOutCar("strip") == false)
check("dim is not a whole-car flicker", Band.blacksOutCar("dim") == false)
check("blackout would be a whole-car flicker", Band.blacksOutCar("blackout"))
for _, band in { "calm", "uneasy", "watched", "hunted" } do
	check(band .. " light does not black out the car", Band.blacksOutCar(Band.light(band)) == false)
end

check("hunted dim stays lit", Band.dimTarget(0.5) == 0.5)
check("a zero dim is refused", Band.dimTarget(0) > 0)

local line = "The next stop is Fulton St."
local glitched = Band.glitchLine(line)
check("watched repeats a word", glitched == "The next next stop is Fulton St.")
local onlyOld = true
for _, word in words(glitched) do
	if not hasWord(line, word) then
		onlyOld = false
	end
end
check("the glitch adds no new word", onlyOld)
check("an empty line stays empty", Band.glitchLine("") == "")

check("watched publishes a false-stop bonus", Band.falseStopBonus("watched", 0.15) == 0.15)
check("calm publishes no false-stop bonus", Band.falseStopBonus("calm", 0.15) == 0)
check("uneasy publishes no false-stop bonus", Band.falseStopBonus("uneasy", 0.15) == 0)
check("hunted publishes no false-stop bonus", Band.falseStopBonus("hunted", 0.15) == 0)

check("uneasy glances", Band.look("uneasy") == "glance")
check("watched turns heads", Band.look("watched") == "turn")
check("calm does not look", Band.look("calm") == "none")
check("hunted does not look", Band.look("hunted") == "none")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("band spec ok")
