--!strict
-- Court Square endings from src/game/endings.ts. resolveEnding is pure:
-- first match in priority order wins. The exit only picks which earned
-- ending you walk into; the menu never says what's open.

local Endings = {}

export type EndingId =
	"secret_mask"
	| "eternal_commute"
	| "signal_archivist"
	| "skyward_void"
	| "dawn_horizon"
	| "exposed"
	| "collapse"
	| "civilian_extraction"

export type ExitChoice = "escalators" | "lower_level" | "surface_hatch"

export type EndingDefinition = {
	id: EndingId,
	priority: number,
	title: string,
	badge: string,
	narrative: string,
	summary: string,
}

export type EndingSummary = {
	peak: number,
	interventions: number,
	trialStops: { number },
	sanPct: number,
	accPct: number,
	restraintOK: boolean,
	tapes: { string },
	exit: ExitChoice,
}

-- Half of INTERVENE_SUSPICION (60). Quieter endings need peak ≤ this.
Endings.COMPOSED_PEAK = 30
Endings.BAIT_STOP = 12

local function fill(text: string): string
	return (
		text:gsub("{terminus}", "Court Square")
			:gsub("{terminusSign}", "Court Sq")
			:gsub("{origin}", "Hoyt–Schermerhorn")
			:gsub("{bait}", "21 St")
			:gsub("{street}", "Jackson Ave")
			:gsub("{area}", "Long Island City")
			:gsub("{line}", "G")
	)
end

local ENDINGS: { [EndingId]: EndingDefinition } = {
	secret_mask = {
		id = "secret_mask",
		priority = 1,
		title = "The Unbroken Mask",
		badge = "[SECRET: THE UNBROKEN MASK]",
		narrative = fill(
			'At {terminus}, Mom takes your hand on the escalator. "You can stop pretending now," she says, not looking at you. "We saw it too."'
		),
		summary = "The whole ride without a single visible reaction (peak Suspicion 0).",
	},
	eternal_commute = {
		id = "eternal_commute",
		priority = 2,
		title = "The Eternal Commute",
		badge = "[LOOP: THE ETERNAL COMMUTE]",
		narrative = fill(
			'The doors open. The sign says {origin}. Mom stands up and smooths her coat. "This is us," she says.'
		),
		summary = fill("Stepped off at {bait}, or let too much of yourself slip away (Sanity Retained under 30%)."),
	},
	signal_archivist = {
		id = "signal_archivist",
		priority = 3,
		title = "Midnight Terminal",
		badge = "[BRANCH: SIGNAL ARCHIVIST]",
		narrative = fill(
			"You descend past the rusted chain-link gate into {terminus}'s abandoned lower level. The microcassette recorder crackles to life on its own in the damp darkness. A calm dispatcher voice speaks through the hiss: \"Track 4 clear. All units hold position.\" The loop is broken."
		),
		summary = "Followed the static down the side stairs, with tapes in hand, most anomalies caught, and your composure intact.",
	},
	skyward_void = {
		id = "skyward_void",
		priority = 4,
		title = "Skyward Catwalk",
		badge = "[BRANCH: SKYWARD VOID]",
		narrative = "You break away through the emergency door and climb until there is open air. Below you, the sodium lights of the city glow in eerie silence, completely empty. Behind you, the train rumbles into the dark tunnel—its cars completely hollow.",
		summary = "Pushed through the emergency door after holding firm through the restraint, without a single False Stop or intervention.",
	},
	dawn_horizon = {
		id = "dawn_horizon",
		priority = 5,
		title = "Dawn Horizon",
		badge = "[BRANCH: DAWN HORIZON]",
		narrative = fill(
			"The doors open at {terminus} onto daylight that shouldn't reach this platform. Dad squints and says nothing. For once, neither do you."
		),
		summary = "Stayed with your parents after holding firm through the restraint, with the conductor on tape and most of yourself intact.",
	},
	exposed = {
		id = "exposed",
		priority = 6,
		title = "Exposed",
		badge = "[TERMINAL: EXPOSED]",
		narrative = fill(
			"You made it to {terminus}. Dad keeps a firm, unyielding grip on your shoulder all the way up the stairs into the street. Nobody says a single word."
		),
		summary = "Your parents stepped in.",
	},
	collapse = {
		id = "collapse",
		priority = 7,
		title = "Disoriented Collapse",
		badge = "[COLLAPSE: DISORIENTED]",
		narrative = fill(
			"You made it to {terminus}. Mom doesn't let go of your sleeve until you're outside on {street}. You have no memory of the last three stops."
		),
		summary = "Stepped off at a False Stop.",
	},
	civilian_extraction = {
		id = "civilian_extraction",
		priority = 8,
		title = "Civilian Extraction",
		badge = "[STANDARD: EXTRACTION]",
		narrative = fill(
			"You made it to {terminus}. Your parents push through the turnstiles, already arguing about where to eat in {area}."
		),
		summary = "An ordinary arrival.",
	},
}

Endings.ENDINGS = ENDINGS

function Endings.definition(id: EndingId): EndingDefinition
	return ENDINGS[id]
end

function Endings.normalizeExit(value: string?): ExitChoice
	if value == "lower_level" or value == "surface_hatch" or value == "escalators" then
		return value
	end
	return "escalators"
end

function Endings.accuracyPercent(correct: number, miss: number): number
	local total = correct + miss
	if total <= 0 then
		return 100
	end
	return math.floor((100 * correct) / total + 0.5)
end

local function hasTrial(stops: { number }, stop: number): boolean
	for _, s in stops do
		if s == stop then
			return true
		end
	end
	return false
end

local function hasTape(tapes: { string }, id: string): boolean
	for _, t in tapes do
		if t == id then
			return true
		end
	end
	return false
end

function Endings.resolve(s: EndingSummary): EndingDefinition
	local noTrials = #s.trialStops == 0
	if s.peak == 0 then
		return ENDINGS.secret_mask
	end
	if hasTrial(s.trialStops, Endings.BAIT_STOP) or s.sanPct < 30 then
		return ENDINGS.eternal_commute
	end
	if
		s.exit == "lower_level"
		and #s.tapes >= 2
		and s.accPct >= 75
		and s.peak <= Endings.COMPOSED_PEAK
	then
		return ENDINGS.signal_archivist
	end
	if s.exit == "surface_hatch" and s.restraintOK and noTrials and s.interventions == 0 then
		return ENDINGS.skyward_void
	end
	if
		s.exit == "escalators"
		and s.restraintOK
		and noTrials
		and hasTape(s.tapes, "conductor")
		and s.sanPct >= 60
	then
		return ENDINGS.dawn_horizon
	end
	if s.interventions > 0 then
		return ENDINGS.exposed
	end
	if not noTrials then
		return ENDINGS.collapse
	end
	return ENDINGS.civilian_extraction
end

function Endings.exitLine(choice: ExitChoice): string
	if choice == "lower_level" then
		return "You drift toward the side stairs. The hiss in your pocket gets louder."
	end
	if choice == "surface_hatch" then
		return "You lean on the emergency bar. Somewhere above, the air is moving."
	end
	return "You follow your parents toward the escalators."
end

return Endings
