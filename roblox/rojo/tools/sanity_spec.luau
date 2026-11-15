--!strict
-- Sanity bands, tiers, and clamps.
-- Run: luau tools/sanity_spec.luau

local Sanity = require("../src/shared/Sanity")
local Lines = require("../src/shared/Lines")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("100 is high", Sanity.tierOf(100) == Sanity.TIER_HIGH)
check("75 is high", Sanity.tierOf(75) == Sanity.TIER_HIGH)
check("74 is medium", Sanity.tierOf(74) == Sanity.TIER_MEDIUM)
check("40 is medium", Sanity.tierOf(40) == Sanity.TIER_MEDIUM)
check("39 is low", Sanity.tierOf(39) == Sanity.TIER_LOW)
check("10 is low", Sanity.tierOf(10) == Sanity.TIER_LOW)
check("9 is critical", Sanity.tierOf(9) == Sanity.TIER_CRITICAL)

local lo11, hi11 = Sanity.bandForStop(11, false, 6)
check("stop 11 lo", lo11 == 0)
check("stop 11 hi", hi11 == 9)
local _, hi11ok = Sanity.bandForStop(11, true, 6)
check("restraint raises ceiling", hi11ok == 15)

check("drift into Classon", Sanity.driftForStop(4) == -5)
check("flat drift at Broadway", Sanity.driftForStop(8) == 0)
check("boarding stop has no drift", Sanity.driftForStop(1) == 0)

check("clamp into band", Sanity.apply(100, -5, 0, 9) == 9)
check("clamp floor", Sanity.apply(2, -5, 0, 9) == 0)
check("haven inside band", Sanity.apply(70, 15, 50, 85) == 85)

check("band position mid", Sanity.bandPosition(5, 0, 10) == 0.5)
check("retained average", Sanity.retainedPercent({ 1, 0.5, 0 }) == 50)

check("meter label", Lines.sanityMeter(82, "high") == "82 HIGH")
check("critical label", Lines.tierLabel("critical") == "CRITICAL")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("sanity spec ok")
