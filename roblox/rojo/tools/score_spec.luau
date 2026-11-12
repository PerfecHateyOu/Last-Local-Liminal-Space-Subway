--!strict
-- False-alarm penalty and the one result at the end of a stop.
-- Run: luau tools/score_spec.luau
-- Amounts match src/shared/Constants.luau.

local Lines = require("../src/shared/Lines")
local Score = require("../src/shared/Score")

local FALSE_ALARM = 10
local CORRECT = 5
local CLEAN = 5
local DECAY = 2
local LEAST = 0
local MOST = 100

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("a correct flag lowers suspicion", Score.flagDelta(true, false, FALSE_ALARM, CORRECT) == -5)
check("a correct flag still lowers suspicion while a tell is up", Score.flagDelta(true, true, FALSE_ALARM, CORRECT) == -5)
check("a false alarm adds 10 when nothing is active", Score.flagDelta(false, false, FALSE_ALARM, CORRECT) == 10)
check("flagging the wrong target while a tell is up adds nothing", Score.flagDelta(false, true, FALSE_ALARM, CORRECT) == 0)

check("noticed wins", Score.result(true, true, true) == "noticed")
check("a wolf cry with no catch is a false alarm", Score.result(true, false, true) == "false")
check("an unflagged anomaly is a miss", Score.result(true, false, false) == "missed")
check("nothing wrong and no flag is clean", Score.result(false, false, false) == "clean")
check("a flag with no anomaly is a false alarm", Score.result(false, false, true) == "false")
check("catching the stranger on a quiet stop is noticed", Score.result(false, true, false) == "noticed")

check("a clean stop gets the clean bonus and decay", Score.endDelta("clean", CLEAN, DECAY) == -7)
check("a miss does not raise suspicion", Score.endDelta("missed", CLEAN, DECAY) == -2)
check("a miss delta is not positive", Score.endDelta("missed", CLEAN, DECAY) <= 0)
check("noticed has no extra end change", Score.endDelta("noticed", CLEAN, DECAY) == 0)
check("a false alarm has no extra end change", Score.endDelta("false", CLEAN, DECAY) == 0)

check("no reaction at a false stop adds nothing", Score.falseStopDelta(false, FALSE_ALARM) == 0)
check("a detected reaction would add 10", Score.falseStopDelta(true, FALSE_ALARM) == 10)

check("10 stacks on 20", Score.apply(20, 10, LEAST, MOST) == 30)
check("a drop stays in range", Score.apply(3, -7, LEAST, MOST) == 0)
check("the top stays 100", Score.apply(95, 10, LEAST, MOST) == 100)
check("100 is still a number", typeof(Score.apply(100, 10, LEAST, MOST)) == "number")

check("caught word", Lines.CAUGHT == "Caught")
check("missed word", Lines.MISSED == "Missed")
check("false flag word", Lines.FALSE_FLAG == "False flag")
check("clean word", Lines.CLEAN == "Clean")
check("false flag line still names the person", Lines.falseFlag("Dad") == "False flag: Dad")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("score spec ok")
