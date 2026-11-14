--!strict
-- Safe Haven helpers. Run: luau tools/haven_spec.luau

local Haven = require("../src/shared/Haven")
local Doors = require("../src/shared/Doors")

local failures = 0
local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("no handoff with recorder", Haven.shouldTrainHandoff(true, 7, false) == false)
check("handoff on 6b without recorder", Haven.shouldTrainHandoff(false, 6, true) == true)
check("no handoff on haven approach", Haven.shouldTrainHandoff(false, 6, false) == false)
check("handoff after stop 6", Haven.shouldTrainHandoff(false, 7, false) == true)

check("sanity restore", Haven.restoreSanity(80, 15, 0, 100) == 95)
check("sanity clamp", Haven.restoreSanity(90, 15, 0, 100) == 100)

local amounts = { realOff = 20, refuseHaven = 10, falseOff = 15 }
local off = Doors.resolve("haven", false, "off", amounts, "R", "REFUSE", "F", "H", "T")
check("haven off mode", off.mode == "haven" and off.correct and off.suspicionDelta == 0)
local stay = Doors.resolve("haven", false, "stay", amounts, "R", "REFUSE", "F", "H", "T")
check("haven stay refuses", stay.mode == "depart" and stay.suspicionDelta == 10)

check("timing order", Haven.MOM_STAND_AT < Haven.DAD_STOPS_AT and Haven.RECORDER_AT < Haven.DEPART_AT)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("haven spec ok")
