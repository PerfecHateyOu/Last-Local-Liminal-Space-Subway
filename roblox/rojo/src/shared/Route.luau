--!strict
-- G train stops and the stretch table from src/constants.ts (STOPS, SEGS,
-- CHAPTERS). Fields this slice plays: name, real / false / haven, arrival
-- tick, quiet PA, parent chat index, and mask check times (seconds into the
-- stretch, fitted to sliceCruise). Safe Haven runs at kind "haven"; the trial stays out.

local Route = {}

export type Tick = "doors" | "flicker"
export type StopKind = "real" | "false" | "haven"

export type Segment = {
	stop: number,
	b: boolean,
	kind: StopKind,
	tick: Tick?,
	silent: boolean,
	crowd: boolean,
	final: boolean,
	-- Classon Av only. Mom pulls you back; no trial.
	forgiving: boolean,
	paLie: string?,
	-- Web SEGS.chat index into CHATS / calm swaps. Nil = no chat on this stretch.
	chat: number?,
	-- Seconds into the stretch when a mask check starts (slice-scaled).
	masks: { number }?,
	-- Web cruise is 26 unless noted. The slice uses a shorter cruise.
	sliceCruise: number,
}

-- Signed names, stop numbers 1 through 13. The web array has an empty [0].
local STOPS: { [number]: string } = {
	[1] = "Hoyt–Schermerhorn",
	[2] = "Fulton St",
	[3] = "Clinton–Washington Avs",
	[4] = "Classon Av",
	[5] = "Bedford–Nostrand Avs",
	[6] = "Myrtle–Willoughby Avs",
	[7] = "Flushing Av",
	[8] = "Broadway",
	[9] = "Metropolitan Av",
	[10] = "Nassau Av",
	[11] = "Greenpoint Av",
	[12] = "21 St",
	[13] = "Court Sq",
}

local CHAPTERS = {
	{ from = 1, to = 5, numeral = "I", title = "THE DESCENT" },
	{ from = 6, to = 10, numeral = "II", title = "SIGNAL DRIFT" },
	{ from = 11, to = 13, numeral = "III", title = "OPERATION SKYWARD" },
}

-- Same order as SEGS. sliceCruise is the shortened stand-in for the web cruise
-- (26, or the override on 6b and the last stretch).
local SEGMENTS: { Segment } = {
	{ stop = 2, b = false, kind = "real", tick = nil, silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = nil, masks = nil, sliceCruise = 12 },
	{ stop = 3, b = false, kind = "real", tick = nil, silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = 0, masks = { 12 }, sliceCruise = 12 },
	{ stop = 4, b = false, kind = "false", tick = "doors", silent = false, crowd = false, final = false, forgiving = true, paLie = nil, chat = nil, masks = nil, sliceCruise = 12 },
	{ stop = 5, b = false, kind = "real", tick = nil, silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = 1, masks = { 12 }, sliceCruise = 12 },
	{ stop = 6, b = false, kind = "haven", tick = nil, silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = nil, masks = nil, sliceCruise = 12 },
	-- 6b. No announcement. The arrival flicker is the whole-car blackout.
	{ stop = 6, b = true, kind = "false", tick = "flicker", silent = true, crowd = false, final = false, forgiving = false, paLie = nil, chat = nil, masks = nil, sliceCruise = 8 },
	{ stop = 7, b = false, kind = "real", tick = nil, silent = false, crowd = true, final = false, forgiving = false, paLie = nil, chat = 2, masks = { 12 }, sliceCruise = 12 },
	{ stop = 8, b = false, kind = "real", tick = nil, silent = false, crowd = true, final = false, forgiving = false, paLie = nil, chat = 3, masks = { 8, 13 }, sliceCruise = 12 },
	{
		stop = 9,
		b = false,
		kind = "false",
		tick = "doors",
		silent = false,
		crowd = false,
		final = false,
		forgiving = false,
		paLie = "This is Court Square. Last stop. Everybody off the train.",
		chat = nil,
		masks = nil,
		sliceCruise = 12,
	},
	{ stop = 10, b = false, kind = "real", tick = nil, silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = 4, masks = { 12 }, sliceCruise = 12 },
	{ stop = 11, b = false, kind = "real", tick = nil, silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = nil, masks = nil, sliceCruise = 12 },
	-- 21 St. False stop. Flicker tick: the lights go out for 0.16 s. No "This is".
	{ stop = 12, b = false, kind = "false", tick = "flicker", silent = false, crowd = false, final = false, forgiving = false, paLie = nil, chat = nil, masks = { 12 }, sliceCruise = 12 },
	{ stop = 13, b = false, kind = "real", tick = nil, silent = false, crowd = false, final = true, forgiving = false, paLie = nil, chat = nil, masks = nil, sliceCruise = 10 },
}

Route.SEGMENTS = SEGMENTS

function Route.stopName(stop: number): string
	return STOPS[stop] or ""
end

-- Web gameState currentCarIndex thresholds (metres along the consist).
Route.CAR_A_MAX_X = -10.2
Route.CAR_C_MIN_X = 10.2

function Route.carLabel(xMetres: number): string
	if xMetres < Route.CAR_A_MAX_X then
		return "CAR A (LEAD)"
	elseif xMetres > Route.CAR_C_MIN_X then
		return "CAR C (REAR)"
	end
	return "CAR B (MID)"
end

-- HUD chapter line. Car letter defaults to mid until the client swaps it
-- from the player's position.
function Route.chapterLine(stop: number, carLabel: string?): string
	local numeral = "I"
	local title = "THE DESCENT"
	for _, chapter in CHAPTERS do
		if stop >= chapter.from and stop <= chapter.to then
			numeral = chapter.numeral
			title = chapter.title
			break
		end
	end
	return "CH. " .. numeral .. " · " .. title .. " · " .. (carLabel or "CAR B (MID)")
end

-- Replace the trailing car tag on a chapter line (server still ships MID).
function Route.withCarLabel(chapterLine: string, carLabel: string): string
	local replaced, count = string.gsub(chapterLine, "CAR [ABC] %([^%)]+%)", carLabel, 1)
	if count > 0 then
		return replaced
	end
	return chapterLine .. " · " .. carLabel
end

function Route.segmentLength(segment: Segment, accel: number, brake: number): number
	return accel + segment.sliceCruise + brake
end

return Route
