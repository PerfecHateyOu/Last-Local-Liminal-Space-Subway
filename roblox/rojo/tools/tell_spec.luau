--!strict
-- Wrong-announcement and wrong-countdown tells.
-- Run: luau tools/tell_spec.luau
-- Stop numbers and minute counts match src/shared/Constants.luau.

local AnomalySystem = require("../src/server/AnomalySystem")
local Lines = require("../src/shared/Lines")

local POSTER_STOP = 3
local EXTRA_STOP = 5
local ANNOUNCE_STOP = 7
local COUNTDOWN_STOP = 10
local HONEST_MINUTES = 1
local WRONG_MINUTES = 4

local schedule = {
	posterStop = POSTER_STOP,
	extraStop = EXTRA_STOP,
	announceStop = ANNOUNCE_STOP,
	countdownStop = COUNTDOWN_STOP,
}

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local function listed(kind: string): boolean
	for _, name in AnomalySystem.types() do
		if name == kind then
			return true
		end
	end
	return false
end

check("catalog keeps the poster", listed("poster_changed"))
check("catalog includes the mid-ride extra", listed("extra"))
check("catalog includes the wrong announcement", listed("wrong_announcement"))
check("catalog includes the wrong countdown", listed("wrong_countdown"))

check("stop 3 is the poster", AnomalySystem.pick(3, false, schedule) == "poster_changed")
check("Bedford approach is the mid-ride extra", AnomalySystem.pick(5, false, schedule) == "extra")
check("Flushing approach is the wrong announcement", AnomalySystem.pick(7, false, schedule) == "wrong_announcement")
check("Nassau approach is the wrong countdown", AnomalySystem.pick(10, false, schedule) == "wrong_countdown")
check("a quiet stop has no tell", AnomalySystem.pick(2, false, schedule) == nil)
check("the scripted PA lie stop is not also a catalog tell", AnomalySystem.pick(9, false, schedule) == nil)
check("the 6b stretch is not a tell", AnomalySystem.pick(6, true, schedule) == nil)

check(
	"one stop keeps a single tell",
	AnomalySystem.pick(3, false, { posterStop = 3, extraStop = 3, announceStop = 3, countdownStop = 3 })
		== "poster_changed"
)

check(
	"wrong announcement uses another real stop",
	AnomalySystem.wrongStop("Flushing Av", "Court Sq", "Fulton St") == "Court Sq"
)
check(
	"wrong announcement will not repeat the real next stop",
	AnomalySystem.wrongStop("Court Sq", "Court Sq", "Fulton St") == "Fulton St"
)
check(
	"no alternate name leaves the real stop",
	AnomalySystem.wrongStop("Court Sq", "Court Sq", "Court Sq") == "Court Sq"
)

check("honest board shows one minute", AnomalySystem.boardMinutes(HONEST_MINUTES, WRONG_MINUTES, false) == 1)
check("wrong board shows four minutes", AnomalySystem.boardMinutes(HONEST_MINUTES, WRONG_MINUTES, true) == 4)

check("a passenger anomaly is noticed", AnomalySystem.verdict(true, false, false) == "noticed")
check("an active tell is noticed", AnomalySystem.verdict(false, true, true) == "noticed")
check("a quiet tell is a false flag", AnomalySystem.verdict(false, true, false) == "false")
check("an ordinary passenger is a false flag", AnomalySystem.verdict(false, false, true) == "false")

check("announcement flag id", AnomalySystem.ANNOUNCE_ID == "announcement")
check("countdown flag id", AnomalySystem.COUNTDOWN_ID == "countdown")
check("extra passenger id", AnomalySystem.EXTRA_ID == "seat6")

check("next-stop phrasing is unchanged", Lines.nextStop("Court Sq") == "The next stop is Court Sq.")
check("minute label", Lines.MIN_LABEL == "MIN")
check("one minute on the board", Lines.minutesLabel(1) == "1 MIN")
check("four minutes on the board", Lines.minutesLabel(4) == "4 MIN")
check("announcement label", Lines.ANNOUNCEMENT == "the announcement")
check("countdown label", Lines.COUNTDOWN == "the countdown")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("tell spec ok")
