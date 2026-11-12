--!strict
-- Held At Signal. The train pauses in the tunnel. The hold never blacks
-- out the whole car.
-- Run: luau tools/hold_spec.luau
-- Amounts match src/shared/Constants.luau.

local Hold = require("../src/shared/Hold")
local Motion = require("../src/shared/Motion")

local HOLD_AT = 6
local HOLD_FOR = 4
local ACCEL = 3
local CRUISE = 12
local BRAKE = 3
local TOP = 14
local STOP_A = 8
local STOP_B = 11
local MULTIPLIER = 2

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("Broadway stretch is held", Hold.applies(STOP_A, false, false, STOP_A, STOP_B))
check("Greenpoint stretch is held", Hold.applies(STOP_B, false, false, STOP_A, STOP_B))
check("an ordinary stretch is not held", Hold.applies(2, false, false, STOP_A, STOP_B) == false)
check("the silent blackout stretch is not held", Hold.applies(6, true, false, STOP_A, STOP_B) == false)
check("the last stretch is not held", Hold.applies(13, false, true, STOP_A, STOP_B) == false)
check("21 St is not a hold", Hold.applies(12, false, false, STOP_A, STOP_B) == false)

check("the pause starts in cruise", Hold.placed(HOLD_AT, HOLD_FOR, ACCEL, CRUISE))
check("a pause at the platform is rejected", Hold.placed(1, HOLD_FOR, ACCEL, CRUISE) == false)
check("a pause while braking is rejected", Hold.placed(16, HOLD_FOR, ACCEL, CRUISE) == false)

check("before the hold the clock matches", Hold.motionTime(5, HOLD_AT, HOLD_FOR) == 5)
check("during the hold the clock stays put", Hold.motionTime(8, HOLD_AT, HOLD_FOR) == HOLD_AT)
check("after the hold the clock drops the pause", Hold.motionTime(12, HOLD_AT, HOLD_FOR) == 8)
check("no hold leaves the clock alone", Hold.motionTime(8, HOLD_AT, 0) == 8)

check("the train is stopped during the hold", Hold.moving(8, HOLD_AT, HOLD_FOR) == false)
check("the train is moving before the hold", Hold.moving(5, HOLD_AT, HOLD_FOR))
check("the train moves again after the hold", Hold.moving(11, HOLD_AT, HOLD_FOR))

local frozen = Motion.distance(Hold.motionTime(6, HOLD_AT, HOLD_FOR), ACCEL, CRUISE, BRAKE, TOP)
local still = Motion.distance(Hold.motionTime(9, HOLD_AT, HOLD_FOR), ACCEL, CRUISE, BRAKE, TOP)
local later = Motion.distance(Hold.motionTime(12, HOLD_AT, HOLD_FOR), ACCEL, CRUISE, BRAKE, TOP)
check("scenery does not advance during the hold", frozen == still)
check("scenery advances after the hold", later > still)

check("a held stretch lasts the pause longer", Hold.wallDuration(18, true, HOLD_FOR) == 22)
check("an ordinary stretch keeps its length", Hold.wallDuration(18, false, HOLD_FOR) == 18)

check("strip is not a whole-car flicker", Hold.blacksOutCar("strip") == false)
check("dim is not a whole-car flicker", Hold.blacksOutCar("dim") == false)
check("the door-tick blackout is a whole-car flicker", Hold.blacksOutCar("blackout"))
check("a hold plans a strip, not a blackout", Hold.plan("strip") == "strip")
check("a hold plans a dim, not a blackout", Hold.plan("dim") == "dim")
check("a blackout request becomes one strip", Hold.plan("blackout") == "strip")
check("planned strip does not black out the car", Hold.blacksOutCar(Hold.plan("strip")) == false)
check("planned dim does not black out the car", Hold.blacksOutCar(Hold.plan("dim")) == false)
check("planned blackout request does not black out the car", Hold.blacksOutCar(Hold.plan("blackout")) == false)

check("dim target stays lit", Hold.dimTarget(0.55) == 0.55)
check("a zero dim is refused", Hold.dimTarget(0) > 0)

check("held stare scale is twice", Hold.stareScale(true, MULTIPLIER) == 2)
check("an ordinary stretch keeps the stare scale", Hold.stareScale(false, MULTIPLIER) == 1)

check("the hold tell is an existing catalog id", Hold.tell("wrong_countdown") == "wrong_countdown")
check("an unknown hold tell is dropped", Hold.tell("blackout") == nil)
check("no hold tell is allowed", Hold.tell("") == nil)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("hold spec ok")
