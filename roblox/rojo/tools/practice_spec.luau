--!strict
-- Practice chapter indices and nightmare drift.
-- Run: luau tools/practice_spec.luau

local Practice = require("../src/shared/Practice")
local Nightmare = require("../src/shared/Nightmare")
local Achievements = require("../src/shared/Achievements")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("ch1 index", Practice.startIndex(1) == 1)
check("ch2 index", Practice.startIndex(2) == 5)
check("ch3 index", Practice.startIndex(3) == 11)
check("ch2 is practice", Practice.isPractice(2))
check("ch1 not practice", not Practice.isPractice(1))
check("off record practice", Practice.offRecord(true, false))
check("off record debug", Practice.offRecord(false, true))
check("on record", not Practice.offRecord(false, false))

check("nightmare cruise", Nightmare.cruiseSeconds(12, true) == 9)
check("normal cruise", Nightmare.cruiseSeconds(12, false) == 12)
check("nightmare drift flat", Nightmare.driftDelta(0, true) == -2)
check("nightmare drift deep", Nightmare.driftDelta(-5, true) == -7.5)
check("normal drift", Nightmare.driftDelta(-5, false) == -5)

local map = {}
check("unlock once", Achievements.unlock(map, "first_anomaly", 1, false))
check("no double unlock", not Achievements.unlock(map, "first_anomaly", 2, false))
check("practice blocks", not Achievements.unlock(map, "loop_breaker", 3, true))
check("has", Achievements.has(map, "first_anomaly"))
check("count", Achievements.count(map) == 1)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("practice spec ok")
