--!strict
-- Ride Psych Log: anomaly types seen / caught this ride (web psychLog.ts).
-- Shown on the Travel Report. Persistent Case Files stay in MetaStore (PR15).

local PsychLog = {}

export type EntryDef = {
	id: string,
	title: string,
	tier: number,
	note: string,
}

export type RideRecord = {
	id: string,
	stop: string,
	seen: boolean,
	caught: boolean,
}

export type RideState = {
	records: { RideRecord },
	byId: { [string]: RideRecord },
}

-- Catalog ids this Rojo slice can schedule (plus photo catch marker).
local ENTRIES: { [string]: EntryDef } = {
	poster_changed = {
		id = "poster_changed",
		title = "The Misprint",
		tier = 0,
		note = "An ad shifted color while you weren’t looking.",
	},
	sticker = {
		id = "sticker",
		title = "Window Residue",
		tier = 0,
		note = "Something appeared on the glass between stops.",
	},
	lighttemp = {
		id = "lighttemp",
		title = "The Cold Panel",
		tier = 0,
		note = "One ceiling tube turned a hospital blue.",
	},
	mapstop = {
		id = "mapstop",
		title = "Route Map Error",
		tier = 1,
		note = "The strip map listed Hollow St. There is no Hollow St.",
	},
	moved = {
		id = "moved",
		title = "The Relocated Passenger",
		tier = 1,
		note = "A rider was at the far doors without crossing the car.",
	},
	extra = {
		id = "extra",
		title = "The Additional Passenger",
		tier = 1,
		note = "A silent rider sat at the far end. They didn’t board.",
	},
	wrong_announcement = {
		id = "wrong_announcement",
		title = "Wrong Call",
		tier = 1,
		note = "The conductor named a stop you were not approaching.",
	},
	wrong_countdown = {
		id = "wrong_countdown",
		title = "Wrong Minutes",
		tier = 1,
		note = "The board’s minute count disagreed with the stretch.",
	},
	nearword = {
		id = "nearword",
		title = "Warped Copy",
		tier = 2,
		note = "An ad rearranged itself into words meant for you.",
	},
	empty = {
		id = "empty",
		title = "The Empty Car",
		tier = 3,
		note = "Every stranger was gone at once. Your parents didn’t mention it.",
	},
	faceturn = {
		id = "faceturn",
		title = "The Woman on Your Bench",
		tier = 2,
		note = "Her head turned further than a neck allows.",
	},
	momface = {
		id = "momface",
		title = "Mom, Fixed",
		tier = 3,
		note = "Her face set into an expression that wasn’t hers.",
	},
}

PsychLog.ENTRIES = ENTRIES

function PsychLog.newRide(): RideState
	return { records = {}, byId = {} }
end

function PsychLog.definition(id: string): EntryDef?
	return ENTRIES[id]
end

function PsychLog.markSeen(state: RideState, id: string, stop: string)
	local existing = state.byId[id]
	if existing ~= nil then
		existing.seen = true
		return
	end
	local rec: RideRecord = { id = id, stop = stop, seen = true, caught = false }
	state.byId[id] = rec
	table.insert(state.records, rec)
end

function PsychLog.markCaught(state: RideState, id: string, stop: string)
	local existing = state.byId[id]
	if existing ~= nil then
		existing.seen = true
		existing.caught = true
		return
	end
	local rec: RideRecord = { id = id, stop = stop, seen = true, caught = true }
	state.byId[id] = rec
	table.insert(state.records, rec)
end

function PsychLog.formatReport(state: RideState): string
	if #state.records == 0 then
		return "Psych Log\n(none this ride)"
	end
	local lines = { "Psych Log" }
	for _, rec in state.records do
		local def = ENTRIES[rec.id]
		local title = if def ~= nil then def.title else rec.id
		local status = if rec.caught then "documented" else "unconfirmed"
		table.insert(lines, string.format("• %s @ %s [%s]", title, rec.stop, status))
	end
	return table.concat(lines, "\n")
end

return PsychLog
