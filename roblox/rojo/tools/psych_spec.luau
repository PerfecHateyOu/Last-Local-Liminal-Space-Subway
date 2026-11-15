--!strict
-- Psych log + stare / sitting score helpers.
-- Run: luau tools/psych_spec.luau

local PsychLog = require("../src/shared/PsychLog")
local Score = require("../src/shared/Score")
local Dialogue = require("../src/shared/Dialogue")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local state = PsychLog.newRide()
PsychLog.markSeen(state, "extra", "Bedford–Nostrand Avs")
PsychLog.markCaught(state, "extra", "Bedford–Nostrand Avs")
PsychLog.markSeen(state, "lighttemp", "Fulton St")
check("one record per id", #state.records == 2)
check("caught", state.byId["extra"].caught == true)
check("seen only", state.byId["lighttemp"].caught == false)
local text = PsychLog.formatReport(state)
check("report has documented", string.find(text, "documented", 1, true) ~= nil)
check("report has unconfirmed", string.find(text, "unconfirmed", 1, true) ~= nil)

check("stare hits", Score.stareDelta(true, 15) == 15)
check("stare miss", Score.stareDelta(false, 15) == 0)
check("sit still", Score.sittingStillDelta(true, 2) == -2)
check("moved", Score.sittingStillDelta(false, 2) == 0)

local calm = Dialogue.maskPoolForBand("calm", 0, 10)
local hunted = Dialogue.maskPoolForBand("hunted", 20, 10)
check("calm pool nonempty", #calm > 0)
check("hunted pool larger or equal", #hunted >= #calm)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("psych spec ok")
