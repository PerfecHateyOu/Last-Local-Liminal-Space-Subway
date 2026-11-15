--!strict
-- Anomaly catalog for this slice. The ride asks pick() which one tell a
-- stop gets, applies it, and validates flags with verdict(). The arrival
-- PA lie in Route is a separate scripted line. It is not this catalog.
-- "extra" is the far-seat passenger (seat6): hidden at boarding, shown
-- mid-stretch, cleared on arrival. New types (lighttemp, sticker, mapstop,
-- moved, empty, nearword, faceturn, momface) follow web anomalyManager.ts
-- with NEAR_X fair-reach for close-look tells.

local AnomalySystem = {}

-- Web NEAR_X: small / readable tells only within this many metres of the seat.
AnomalySystem.NEAR_X = 5

AnomalySystem.ANNOUNCE_ID = "announcement"
AnomalySystem.COUNTDOWN_ID = "countdown"
AnomalySystem.EXTRA_ID = "seat6"
AnomalySystem.STICKER_ID = "sticker"
AnomalySystem.MAP_ID = "mapstop"
AnomalySystem.NEARWORD_ID = "nearword"
AnomalySystem.LIGHT_ID = "lighttemp"
AnomalySystem.EMPTY_ID = "empty"
AnomalySystem.MOVED_ID = "s3"
AnomalySystem.FACETURN_ID = "s2"
AnomalySystem.MOMFACE_ID = "mom"

export type Schedule = {
	posterStop: number,
	extraStop: number,
	announceStop: number,
	countdownStop: number,
	lighttempStop: number?,
	stickerStop: number?,
	nearwordStop: number?,
	mapstopStop: number?,
	movedStop: number?,
	emptyStop: number?,
	faceturnStop: number?,
	momfaceStop: number?,
}

function AnomalySystem.types(): { string }
	return {
		"poster_changed",
		"extra",
		"wrong_announcement",
		"wrong_countdown",
		"lighttemp",
		"sticker",
		"nearword",
		"mapstop",
		"moved",
		"empty",
		"faceturn",
		"momface",
	}
end

function AnomalySystem.isNear(xMetres: number): boolean
	return math.abs(xMetres) <= AnomalySystem.NEAR_X
end

-- Candidate X positions for close-look props (must pass isNear).
function AnomalySystem.nearSlots(): { number }
	return { -4.5, -3.0, -1.5, 0, 1.5, 3.0, 4.5 }
end

function AnomalySystem.pickNearSlot(seed: number): number
	local slots = AnomalySystem.nearSlots()
	local index = (math.floor(math.abs(seed)) % #slots) + 1
	return slots[index]
end

-- At most one tell. Earlier schedule entries win when stops collide.
-- b stretches (the silent 6b blackout) get none.
function AnomalySystem.pick(stop: number, b: boolean, schedule: Schedule): string?
	if b then
		return nil
	end
	if stop == schedule.posterStop then
		return "poster_changed"
	end
	if stop == schedule.extraStop then
		return "extra"
	end
	if stop == schedule.announceStop then
		return "wrong_announcement"
	end
	if stop == schedule.countdownStop then
		return "wrong_countdown"
	end
	if schedule.lighttempStop ~= nil and stop == schedule.lighttempStop then
		return "lighttemp"
	end
	if schedule.stickerStop ~= nil and stop == schedule.stickerStop then
		return "sticker"
	end
	if schedule.nearwordStop ~= nil and stop == schedule.nearwordStop then
		return "nearword"
	end
	if schedule.mapstopStop ~= nil and stop == schedule.mapstopStop then
		return "mapstop"
	end
	if schedule.movedStop ~= nil and stop == schedule.movedStop then
		return "moved"
	end
	if schedule.emptyStop ~= nil and stop == schedule.emptyStop then
		return "empty"
	end
	if schedule.faceturnStop ~= nil and stop == schedule.faceturnStop then
		return "faceturn"
	end
	if schedule.momfaceStop ~= nil and stop == schedule.momfaceStop then
		return "momface"
	end
	return nil
end

-- Another signed station. Never the stop the train is actually approaching
-- when some other signed name exists.
function AnomalySystem.wrongStop(actual: string, candidate: string, fallback: string): string
	if candidate ~= "" and candidate ~= actual then
		return candidate
	end
	if fallback ~= "" and fallback ~= actual then
		return fallback
	end
	return actual
end

function AnomalySystem.boardMinutes(honest: number, wrong: number, telling: boolean): number
	if telling then
		return wrong
	end
	return honest
end

-- Same split as a passenger flag. An active tell is noticed. Anything else
-- the server accepts is a false flag. Hidden targets never reach this.
function AnomalySystem.verdict(passengerAnomaly: boolean, targetIsTell: boolean, tellActive: boolean): "noticed" | "false"
	if passengerAnomaly or (targetIsTell and tellActive) then
		return "noticed"
	end
	return "false"
end

return AnomalySystem
