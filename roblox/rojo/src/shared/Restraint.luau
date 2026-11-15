--!strict
-- Greenpoint Av restraint beat (web gameState startRestraintMoment /
-- updateRestraint / endRestraint). Pure helpers; Ride owns the live state.

local Restraint = {}

Restraint.START_AT = 8.0
Restraint.WAIT_TIMEOUT = 5.0
Restraint.DURATION = 15.0
Restraint.GRACE = 2.5

Restraint.BEAT_MOM = 1.5
Restraint.BEAT_DAD = 4.0
Restraint.BEAT_EMPTY = 7.0
Restraint.BEAT_MOUTH = 10.5

export type State = {
	t: number,
	started: boolean,
	wait: number,
	dur: number,
	beats: number,
	grace: number,
}

function Restraint.newState(duration: number): State
	return {
		t = 0,
		started = false,
		wait = 0,
		dur = duration,
		beats = 0,
		grace = 0,
	}
end

function Restraint.shouldStart(segRestraint: boolean, done: boolean, elapsed: number, startAt: number, busy: boolean): boolean
	if not segRestraint or done or busy then
		return false
	end
	return elapsed >= startAt
end

-- Advance one tick. Returns "wait" | "holding" | "fail_wait" | "fail_release" | "ok".
function Restraint.tick(state: State, dt: number, held: boolean): string
	if state.grace > 0 then
		state.grace = math.max(0, state.grace - dt)
		if not held then
			return "wait"
		end
	end

	if not state.started then
		state.wait += dt
		if held then
			state.started = true
			return "holding"
		end
		if state.wait > Restraint.WAIT_TIMEOUT then
			return "fail_wait"
		end
		return "wait"
	end

	if not held and state.t < state.dur then
		return "fail_release"
	end

	state.t += dt
	if state.t >= state.dur then
		return "ok"
	end
	return "holding"
end

function Restraint.progress(state: State): number
	if not state.started then
		return 0
	end
	if state.dur <= 0 then
		return 1
	end
	return math.clamp(state.t / state.dur, 0, 1)
end

function Restraint.dimFraction(t: number): number
	-- Web: dim = max(0.4, min(1, 1 - t/6))
	return math.clamp(1 - t / 6, 0.4, 1)
end

function Restraint.shouldFireBeat(state: State, at: number): boolean
	if state.t >= at and state.beats < at then
		state.beats = at
		return true
	end
	return false
end

function Restraint.grantGrace(state: State, seconds: number)
	state.grace = math.max(state.grace, seconds)
end

return Restraint
