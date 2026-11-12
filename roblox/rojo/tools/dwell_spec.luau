--!strict
-- Arithmetic for the minimum dwell and the early-departure penalty.
-- Run from this folder: luau tools/dwell_spec.luau
-- Amounts match src/shared/Constants.luau (this file cannot require that
-- module: it builds Color3 values).

local Lines = require("../src/shared/Lines")
local Dwell = require("../src/shared/Dwell")

local MIN_DWELL = 2.6
local PENALTY = 10
local LEAST = 0
local MOST = 100

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("banner title", Lines.MIN_DWELL == "MINIMUM DWELL TIME")
check("countdown rounds up", Lines.dwellCountdown(2.6) == "3")
check("countdown keeps a whole second", Lines.dwellCountdown(2) == "2")
check("countdown stays at least one while time remains", Lines.dwellCountdown(0.05) == "1")
check("countdown at one", Lines.dwellCountdown(1) == "1")

check(
	"early departure adds the penalty",
	Dwell.departureSuspicion(0, 0, MIN_DWELL, true, PENALTY, LEAST, MOST) == 10
)
check(
	"a second early departure stacks",
	Dwell.departureSuspicion(10, 1, MIN_DWELL, true, PENALTY, LEAST, MOST) == 20
)
check(
	"penalty clamps at 100",
	Dwell.departureSuspicion(95, 0, MIN_DWELL, true, PENALTY, LEAST, MOST) == 100
)
check(
	"penalty does not pass 100",
	Dwell.departureSuspicion(100, 0, MIN_DWELL, true, PENALTY, LEAST, MOST) == 100
)
check(
	"leaving once the dwell has ended adds nothing",
	Dwell.departureSuspicion(0, MIN_DWELL, MIN_DWELL, true, PENALTY, LEAST, MOST) == 0
)
check(
	"leaving after the dwell adds nothing",
	Dwell.departureSuspicion(30, MIN_DWELL + 1, MIN_DWELL, true, PENALTY, LEAST, MOST) == 30
)
check(
	"no request leaves suspicion unchanged",
	Dwell.departureSuspicion(40, 0, MIN_DWELL, false, PENALTY, LEAST, MOST) == 40
)
check(
	"value stays inside 0 to 100",
	Dwell.departureSuspicion(-4, 5, MIN_DWELL, false, PENALTY, LEAST, MOST) == 0
		and Dwell.departureSuspicion(140, 5, MIN_DWELL, false, PENALTY, LEAST, MOST) == 100
)
check(
	"reaching 100 is still just a number",
	typeof(Dwell.departureSuspicion(100, 0, MIN_DWELL, true, PENALTY, LEAST, MOST)) == "number"
)

-- Door-open times copied from the ride: 0.35 + 1.95, and 0.35 + 1.15 on a doors tick.
-- 5.4 is Constants.PA_LIE_HOLD.
check("normal stop waits the minimum", Dwell.departTime(2.3, MIN_DWELL, nil) == 4.9)
check("doors tick waits the minimum", Dwell.departTime(1.5, MIN_DWELL, nil) == 4.1)
check("a PA lie can hold longer than the minimum", Dwell.departTime(1.5, MIN_DWELL, 5.4) == 5.4)
check("a short lie does not cut the minimum", Dwell.departTime(2.3, MIN_DWELL, 4) == 4.9)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("dwell spec ok")
