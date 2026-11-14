--!strict
-- False Stop Trial loop from src/game/engineTrial.ts.
-- Signs lie; the chime marks the honest light / door. Visuals live in TrialSpace.

local Trial = {}

export type Mode = "paths" | "board"

export type State = {
	depth: number,
	need: number,
	mode: Mode,
	correct: number,
	stopName: string,
}

export type ChoiceItem = {
	text: string,
	val: number,
}

export type RoundView = {
	signs: { string },
	items: { ChoiceItem },
	windowSeconds: number, -- 0 = no timeout
	boardDoors: boolean,
}

export type PickResult = {
	kind: "continue" | "exit",
	clean: boolean?,
	subtitle: string,
	state: State,
}

local TERMINUS_SIGN = "Court Sq"
local TERMINUS = "Court Square"
local OPPOSITE = "Church Av"
local ORIGIN = "Hoyt–Schermerhorn"
local LINE = "G"

local function shuffle(list: { string }, rng: () -> number): { string }
	local out = table.clone(list)
	for i = #out, 2, -1 do
		local j = math.clamp(math.floor(rng() * i) + 1, 1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

function Trial.start(stopName: string): State
	return {
		depth = 0,
		need = 2,
		mode = "paths",
		correct = 0,
		stopName = stopName,
	}
end

function Trial.windowSeconds(depth: number): number
	if depth == 0 then
		return 0
	end
	return math.max(7, 14 - depth * 2)
end

function Trial.round(state: State, rng: () -> number): (State, RoundView)
	local d = state.depth
	local correct = if state.mode == "paths"
		then math.clamp(math.floor(rng() * 3), 0, 2)
		else (if rng() < 0.5 then 0 else 2)
	state.correct = correct

	local toward = "To " .. TERMINUS_SIGN .. " trains"
	local pools = {
		{ toward, "Exit", "To " .. OPPOSITE .. " trains" },
		{ toward, toward, toward },
		{
			toward:gsub("^To (%S)(%S)", "To %2%1"):gsub("trains$", "trians"),
			"Ext",
			"To You",
		},
		{ ORIGIN, ORIGIN, ORIGIN },
	}
	local pool = pools[math.min(d, 3) + 1]
	local signs = shuffle(pool, rng)

	local boardDoors = state.mode == "board"
	if boardDoors then
		signs = {
			TERMINUS_SIGN .. "-bound " .. LINE,
			"—",
			TERMINUS_SIGN .. "-bound " .. LINE,
		}
	end

	local items: { ChoiceItem }
	if state.mode == "paths" then
		local pathLabels = {
			{ "Left stairs", "Turnstiles", "Right stairs" },
			{ "Left stairs", "Middle stairs", "Right stairs" },
			{ "Down", "Down", "Down" },
		}
		local labels = pathLabels[math.min(d, 2) + 1]
		items = {
			{ text = labels[1], val = 0 },
			{ text = labels[2], val = 1 },
			{ text = labels[3], val = 2 },
		}
	else
		items = {
			{ text = "Board the left train", val = 0 },
			{ text = "Board the right train", val = 2 },
		}
	end

	return state, {
		signs = signs,
		items = items,
		windowSeconds = Trial.windowSeconds(d),
		boardDoors = boardDoors,
	}
end

function Trial.applyPick(state: State, val: number?): PickResult
	local ok = val ~= nil and val == state.correct
	if state.mode == "paths" then
		if ok then
			state.need -= 1
			local sub = if state.need > 0
				then "The stairs go down to another platform."
				else "You come out at the platform edge. Two trains are coming."
			if state.need <= 0 then
				state.mode = "board"
			end
			return { kind = "continue", subtitle = sub, state = state }
		end
		state.depth += 1
		state.need = math.min(state.need + 1, 3)
		if state.depth >= 4 then
			return {
				kind = "exit",
				clean = false,
				subtitle = "The stairs bring you back up onto the same platform. It’s quieter now.",
				state = state,
			}
		end
		return {
			kind = "continue",
			subtitle = "The stairs bring you back up onto the same platform. It’s quieter now.",
			state = state,
		}
	end

	-- board
	if ok then
		return { kind = "exit", clean = true, subtitle = "", state = state }
	end
	state.depth += 1
	state.mode = "paths"
	state.need = 1
	if state.depth >= 4 then
		return {
			kind = "exit",
			clean = false,
			subtitle = "The doors close on nothing. You’re back on the stairs.",
			state = state,
		}
	end
	return {
		kind = "continue",
		subtitle = "The doors close on nothing. You’re back on the stairs.",
		state = state,
	}
end

-- Chime cycle events for paths (flick correct first) or board (open/close).
export type CycleEvent = {
	at: number,
	index: number,
	kind: "flick" | "open" | "close",
}

function Trial.cycleEvents(state: State, rng: () -> number): { CycleEvent }
	local events: { CycleEvent } = {}
	if state.mode == "paths" then
		table.insert(events, { at = 0, index = state.correct, kind = "flick" })
		for i = 0, 2 do
			if i ~= state.correct then
				table.insert(events, {
					at = 0.8 + rng() * 2.2,
					index = i,
					kind = "flick",
				})
			end
		end
		if state.depth >= 1 then
			local decoys = {}
			for i = 0, 2 do
				if i ~= state.correct then
					table.insert(decoys, i)
				end
			end
			local decoy = decoys[math.clamp(math.floor(rng() * #decoys) + 1, 1, #decoys)]
			table.insert(events, {
				at = 0.22 + rng() * 0.13,
				index = decoy,
				kind = "flick",
			})
		end
	else
		local fake = if state.correct == 0 then 2 else 0
		table.insert(events, { at = 1.95, index = state.correct, kind = "open" })
		table.insert(events, { at = 1.15, index = fake, kind = "open" })
		table.insert(events, { at = 3.2, index = 0, kind = "close" })
		table.insert(events, { at = 3.2, index = 2, kind = "close" })
	end
	return events
end

Trial.CYCLE = 3.6
Trial.TERMINUS = TERMINUS

return Trial
