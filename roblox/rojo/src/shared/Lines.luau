--!strict
-- On-screen strings copied from the web game, plus the dwell banner,
-- the minute board, tell labels, door choice, and Safe Haven lines.
-- The dwell banner and the board are labels and numbers.
-- Sources: src/constants.ts (STOPS, the Stop 9 paLie), src/game/gameState.ts
-- (PA, boarding, the Court Sq line), src/components/HUD.tsx ("Next:"),
-- src/components/ReportScreen.tsx (Caught / Missed / false flag).

local Lines = {}

-- fillRoute('This is the Last Local. {terminus}–bound {line} train.') on the G.
Lines.INTRO_PA = "This is the Last Local. Court Square–bound G train."

-- departNext() and the boarding close.
Lines.STAND_CLEAR = "Stand clear of the closing doors, please."

-- fillRoute('{terminus}. This is the last stop on this train.')
Lines.LAST_PA = "Court Square. This is the last stop on this train."

-- SEGS stop 9, paLie. The conductor says this instead of "This is Metropolitan Av."
Lines.PA_LIE = "This is Court Square. Last stop. Everybody off the train."

-- say(1, ...) during boarding. The subtitle is "Dad: " plus the line.
Lines.DAD_BOARD = "Dad: Grab a seat. It’s a long one."

-- say(0, fillRoute('Here we are. {terminus}.'))
Lines.MOM_ARRIVE = "Mom: Here we are. Court Square."

-- The first-ride hint (keyboard).
Lines.HINT = "Move the mouse to look. Hold F while looking at anything that changes."

-- Report words. A correct flag and a miss use these alone.
Lines.CAUGHT = "Caught"
Lines.MISSED = "Missed"
Lines.FALSE_FLAG = "False flag"
Lines.CLEAN = "Clean"

-- HUD station card.
Lines.NEXT_LABEL = "Next:"

-- Mute toggle. Not a spoken line.
Lines.MUTE = "MUTE"
Lines.UNMUTE = "UNMUTE"

-- Stay / step-off choice (web presentDoorChoice / resolveDoors).
Lines.STAY_ON = "Stay on"
Lines.STEP_OFF = "Step off"
Lines.DOOR_PROMPT = "The doors are open."
Lines.MOM_REAL_OFF = "Mom: Hey! Where are you going? Get back in here."
Lines.MOM_REFUSE_HAVEN = "Mom: You don’t want to stretch your legs? …Okay."
Lines.MOM_FALSE_FORGIVING = "Mom: Not this one, hon. The doors opened funny."
-- Safe Haven (Myrtle–Willoughby). Web executeSafeHaven / giveRecorder.
Lines.MOM_HAVEN_CUE = "Mom: I think this is our transfer. Let’s stretch our legs."
Lines.MOM_HAVEN_STAND = "Mom: Feels good to stand up, right?"
Lines.DAD_HAVEN_STOPS = "Dad: Couple more stops after this. Then Court Square."
Lines.DAD_RECORDER_HAVEN =
	"Dad: Here. Your grandfather’s. He used it on the night shift. Never could get it to stop picking up the radio."
Lines.DAD_RECORDER_TRAIN =
	"Dad: Here, hold onto this. Your grandfather’s old recorder. Never could get it to stop picking up the radio."
Lines.RECORDER_HINT = "Dad gave you a tape recorder. Press R to raise it. Tab opens Evidence."
Lines.RECORDER_NONE = "You don’t have anything to record with."
Lines.RECORDER_BUSY = "Your hands are full."
-- Polaroid (web camera / film hints).
Lines.CAMERA_BUSY = "Answer first."
Lines.CAMERA_OUT_OF_FILM = "Out of film."
Lines.CAMERA_HINT = "Press C for the Polaroid. Space snaps. P opens the album strip."
Lines.CAMERA_FLASH_WATCH = "The flash caught a parent's eye."
Lines.HAVEN_BOARD = "You get back on with them."
-- Kept for Doors.resolve signature / older call sites; unused once haven runs.
Lines.HAVEN_STUB = ""
Lines.TRIAL_STUB = ""
-- False Stop Trial (engineTrial.ts).
Lines.TRIAL_HINT = "Find the way back. The signs lie. Watch the lights when the chime plays."
Lines.MOM_TRIAL_CLEAN = "Mom: Where did you go?! You can’t just walk off like that!"
Lines.MOM_TRIAL_ROUGH = "You don’t remember getting back on. Mom: Oh my god. Where were you?"
Lines.DAD_TRIAL_SIT = "Dad: Sit. Stay where we can see you."

-- ReportScreen: "False flag: {name}"
function Lines.falseFlag(label: string): string
	return Lines.FALSE_FLAG .. ": " .. label
end

-- "This is Fulton St."
function Lines.thisIs(name: string): string
	return "This is " .. name .. "."
end

-- "The next stop is Fulton St."
function Lines.nextStop(name: string): string
	return "The next stop is " .. name .. "."
end

-- "{miss} missed, {fp} false flag(s)."
function Lines.scoreLine(miss: number, fp: number): string
	local suffix = if fp == 1 then "" else "s"
	return string.format("%d missed, %d false flag%s.", miss, fp, suffix)
end

-- Dwell banner. Not a spoken line.
Lines.MIN_DWELL = "MINIMUM DWELL TIME"

function Lines.dwellCountdown(secondsLeft: number): string
	local whole = math.ceil(secondsLeft)
	if whole < 1 then
		whole = 1
	end
	return tostring(whole)
end

-- Minute board. The number is the count. MIN is the unit.
Lines.MIN_LABEL = "MIN"

function Lines.minutesLabel(minutes: number): string
	return tostring(minutes) .. " " .. Lines.MIN_LABEL
end

-- Flag labels for the two tells. Not spoken lines.
Lines.ANNOUNCEMENT = "the announcement"
Lines.COUNTDOWN = "the countdown"
Lines.STICKER = "the window sticker"
Lines.MAPSTOP = "the route map"
Lines.NEARWORD = "the warped ad"
Lines.LIGHTTEMP = "the cold light"
Lines.EMPTY = "the empty car"
Lines.MAP_NORMAL = "G · Hoyt–Schermerhorn → Court Sq"
Lines.MAP_HOLLOW = "G · Hollow St (impossible)"
Lines.AD_NORMAL = "GREENPOINT SAVINGS"
Lines.AD_WARP = "DONT LOOK BACK"

-- Suspicion HUD. The number is Ride.Suspicion; the word is Ride.Band
-- (calm / uneasy / watched / hunted from Shared.Band). Display only.
Lines.BAND_CALM = "CALM"
Lines.BAND_UNEASY = "UNEASY"
Lines.BAND_WATCHED = "WATCHED"
Lines.BAND_HUNTED = "HUNTED"

function Lines.bandLabel(band: string): string
	if band == "uneasy" then
		return Lines.BAND_UNEASY
	end
	if band == "watched" then
		return Lines.BAND_WATCHED
	end
	if band == "hunted" then
		return Lines.BAND_HUNTED
	end
	return Lines.BAND_CALM
end

-- "25 UNEASY" — whole number plus the band word.
function Lines.suspicionMeter(value: number, band: string): string
	local n = math.floor(value + 0.5)
	if n < 0 then
		n = 0
	elseif n > 100 then
		n = 100
	end
	return tostring(n) .. " " .. Lines.bandLabel(band)
end

-- Sanity HUD. Number is Ride.Sanity; word is Ride.SanityTier.
Lines.TIER_HIGH = "HIGH"
Lines.TIER_MEDIUM = "MEDIUM"
Lines.TIER_LOW = "LOW"
Lines.TIER_CRITICAL = "CRITICAL"

function Lines.tierLabel(tier: string): string
	if tier == "medium" then
		return Lines.TIER_MEDIUM
	end
	if tier == "low" then
		return Lines.TIER_LOW
	end
	if tier == "critical" then
		return Lines.TIER_CRITICAL
	end
	return Lines.TIER_HIGH
end

-- "82 HIGH" — whole number plus the tier word.
function Lines.sanityMeter(value: number, tier: string): string
	local n = math.floor(value + 0.5)
	if n < 0 then
		n = 0
	elseif n > 100 then
		n = 100
	end
	return tostring(n) .. " " .. Lines.tierLabel(tier)
end

-- Restraint (Greenpoint Av). Hold Space or F; same button as Flag.
Lines.RESTRAINT_HINT = "Hold Space or F. Don't let go. Don't react."
Lines.RESTRAINT_DAD = "Dad: No. We're not getting off. You know that."
Lines.RESTRAINT_MOM_MOUTH = "Mom (her mouth doesn't move): You can stop pretending."
Lines.RESTRAINT_OK = "The lights come back. Everyone is where they were."
Lines.RESTRAINT_FAIL = "You flinch. Dad sees it."
Lines.RESTRAINT_FAIL_WAIT = "You couldn't keep it together"

-- Concerned intervention (suspicion ≥ intervene threshold). Does not end the ride.
Lines.INTERVENTION_DAD = "Dad: Hey. Look at me. Both of us, right now."
Lines.INTERVENTION_MOM = "Mom: Talk to us. What is going on with you?"
Lines.INTERVENTION_YOU = "You: Nothing. I'm okay. I promise."

-- Court Square exit choice (labels never spoil which ending is open).
Lines.EXIT_PROMPT = "Which way out?"
Lines.EXIT_ESCALATORS = "Follow Mom and Dad to the escalators"
Lines.EXIT_LOWER = "Follow the static down the side stairs"
Lines.EXIT_HATCH = "Push through the emergency door"
Lines.EXIT_DEFAULT = "default Escalators"

-- Meta menu (nightmare / chapter / archive).
Lines.META_TITLE = "LAST LOCAL"
Lines.META_START = "Ride from Hoyt"
Lines.META_CH2 = "Practice · Ch II (Haven)"
Lines.META_CH3 = "Practice · Ch III (Greenpoint)"
Lines.META_NIGHTMARE = "Nightmare mode"
Lines.META_NIGHTMARE_LOCKED = "Nightmare (finish one full ride)"
Lines.META_PRACTICE_NOTE = "Practice: nothing is saved."
Lines.META_ARCHIVE = "Case Files"
Lines.META_AGAIN = "Back to menu"
Lines.META_HINT = "Choose a ride. Nightmare unlocks after one full arrival at Court Sq."

-- Caught staring / false-stop react feedback.
Lines.STARE_CAUGHT = "They saw you looking."
Lines.STARE_PARENT = "Mom: Don’t stare."
Lines.FALSE_STOP_REACT = "You moved toward the doors. They noticed."

return Lines
