--!strict
-- Stay / step-off outcomes. Run: luau tools/doors_spec.luau

local Doors = require("../src/shared/Doors")

local amounts = { realOff = 20, refuseHaven = 10, falseOff = 15 }
local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local function resolve(kind: string, forgiving: boolean, choice: string?)
	return Doors.resolve(kind :: any, forgiving, choice, amounts, "REAL", "REFUSE", "FORGIVE", "HAVEN", "TRIAL")
end

check("nil choice is stay", Doors.normalize(nil) == "stay")
check("off normalizes", Doors.normalize("off") == "off")

local realStay = resolve("real", false, "stay")
check("real stay is correct", realStay.correct and realStay.suspicionDelta == 0 and realStay.mode == "depart")

local realOff = resolve("real", false, "off")
check("real off raises suspicion", realOff.suspicionDelta == 20 and realOff.line == "REAL")

local havenOff = resolve("haven", false, "off")
check("haven off is stub", havenOff.mode == "haven_stub" and havenOff.correct and havenOff.suspicionDelta == 0)

local havenStay = resolve("haven", false, "stay")
check("haven stay refuses", havenStay.suspicionDelta == 10 and havenStay.line == "REFUSE")

local falseStay = resolve("false", false, "stay")
check("false stay is correct", falseStay.correct and falseStay.suspicionDelta == 0)

local forgiveOff = resolve("false", true, "off")
check("forgiving false off", forgiveOff.mode == "depart" and forgiveOff.suspicionDelta == 15 and forgiveOff.line == "FORGIVE")

local trialOff = resolve("false", false, "off")
check("trial stub soft-fail", trialOff.mode == "trial_stub" and trialOff.suspicionDelta == 15 and trialOff.line == "TRIAL")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("doors spec ok")
