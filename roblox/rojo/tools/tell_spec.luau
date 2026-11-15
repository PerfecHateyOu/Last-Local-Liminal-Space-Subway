--!strict
-- Wrong-announcement, wrong-countdown, and expanded catalog tells.
-- Run: luau tools/tell_spec.luau
-- Stop numbers and minute counts match src/shared/Constants.luau.

local AnomalySystem = require("../src/server/AnomalySystem")
local Lines = require("../src/shared/Lines")

local POSTER_STOP = 3
local EXTRA_STOP = 5
local ANNOUNCE_STOP = 7
local COUNTDOWN_STOP = 10
local LIGHTTEMP_STOP = 2
local STICKER_STOP = 4
local NEARWORD_STOP = 8
local MAPSTOP_STOP = 9
local MOVED_STOP = 11
local EMPTY_STOP = 13
local HONEST_MINUTES = 1
local WRONG_MINUTES = 4

local schedule = {
	posterStop = POSTER_STOP,
	extraStop = EXTRA_STOP,
	announceStop = ANNOUNCE_STOP,
	countdownStop = COUNTDOWN_STOP,
	lighttempStop = LIGHTTEMP_STOP,
	stickerStop = STICKER_STOP,
	nearwordStop = NEARWORD_STOP,
	mapstopStop = MAPSTOP_STOP,
	movedStop = MOVED_STOP,
	emptyStop = EMPTY_STOP,
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
check("catalog includes lighttemp", listed("lighttemp"))
check("catalog includes sticker", listed("sticker"))
check("catalog includes nearword", listed("nearword"))
check("catalog includes mapstop", listed("mapstop"))
check("catalog includes moved", listed("moved"))
check("catalog includes empty", listed("empty"))
check("catalog includes faceturn", listed("faceturn"))
check("catalog includes momface", listed("momface"))

check("NEAR_X is 5 m", AnomalySystem.NEAR_X == 5)
check("near seat is fair", AnomalySystem.isNear(4.5))
check("far seat is not near", not AnomalySystem.isNear(6.5))
check("near slot is within NEAR_X", AnomalySystem.isNear(AnomalySystem.pickNearSlot(0)))

check("stop 3 is the poster", AnomalySystem.pick(3, false, schedule) == "poster_changed")
check("Bedford approach is the mid-ride extra", AnomalySystem.pick(5, false, schedule) == "extra")
check("Flushing approach is the wrong announcement", AnomalySystem.pick(7, false, schedule) == "wrong_announcement")
check("Nassau approach is the wrong countdown", AnomalySystem.pick(10, false, schedule) == "wrong_countdown")
check("stop 2 is lighttemp", AnomalySystem.pick(2, false, schedule) == "lighttemp")
check("Classon approach is sticker", AnomalySystem.pick(4, false, schedule) == "sticker")
check("Broadway approach is nearword", AnomalySystem.pick(8, false, schedule) == "nearword")
check("Metropolitan approach is mapstop", AnomalySystem.pick(9, false, schedule) == "mapstop")
check("Greenpoint approach is moved", AnomalySystem.pick(11, false, schedule) == "moved")
check("Court Sq approach is empty", AnomalySystem.pick(13, false, schedule) == "empty")
check("a quiet stop has no tell", AnomalySystem.pick(6, false, schedule) == nil)
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
check("sticker id", AnomalySystem.STICKER_ID == "sticker")
check("map id", AnomalySystem.MAP_ID == "mapstop")

check("next-stop phrasing is unchanged", Lines.nextStop("Court Sq") == "The next stop is Court Sq.")
check("minute label", Lines.MIN_LABEL == "MIN")
check("one minute on the board", Lines.minutesLabel(1) == "1 MIN")
check("four minutes on the board", Lines.minutesLabel(4) == "4 MIN")
check("announcement label", Lines.ANNOUNCEMENT == "the announcement")
check("countdown label", Lines.COUNTDOWN == "the countdown")
check("hollow map copy", Lines.MAP_HOLLOW == "G · Hollow St (impossible)")
check("warp ad copy", Lines.AD_WARP == "DONT LOOK BACK")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("tell spec ok")
