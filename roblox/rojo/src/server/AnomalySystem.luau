--!strict
-- Anomaly catalog for this slice. The ride asks pick() which one tell a
-- stop gets, applies it, and validates flags with verdict(). The arrival
-- PA lie in Route is a separate scripted line. It is not this catalog.
-- "extra" is the far-seat passenger (seat6): hidden at boarding, shown
-- mid-stretch, cleared on arrival. It is not a wall plate.

local AnomalySystem = {}

AnomalySystem.ANNOUNCE_ID = "announcement"
AnomalySystem.COUNTDOWN_ID = "countdown"
AnomalySystem.EXTRA_ID = "seat6"

export type Schedule = {
	posterStop: number,
	extraStop: number,
	announceStop: number,
	countdownStop: number,
}

function AnomalySystem.types(): { string }
	return { "poster_changed", "extra", "wrong_announcement", "wrong_countdown" }
end

-- At most one tell. A repeated stop number keeps the earlier entry.
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
