--!strict
-- On-screen strings copied from the web game, plus the dwell banner,
-- the minute board, and the two tell labels. Do not add new dialogue.
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

-- HUD station card.
Lines.NEXT_LABEL = "Next:"

-- ReportScreen: "False flag: {name}"
function Lines.falseFlag(label: string): string
	return "False flag: " .. label
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

return Lines
