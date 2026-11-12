--!strict
-- Held At Signal. The server pauses the tunnel between stations.
-- A hold may blink one strip or dim the car slowly. It never blacks
-- the whole car out. That remains the flicker tick.

local Hold = {}

function Hold.applies(stop: number, b: boolean, final: boolean, first: number, second: number): boolean
	if b or final then
		return false
	end
	return stop == first or stop == second
end

-- The pause must start while the train is already in the tunnel: after
-- accel, before braking. A pause at the platform or on the way into a
-- station is not a hold.
function Hold.placed(holdAt: number, holdFor: number, accel: number, cruise: number): boolean
	if holdFor <= 0 or cruise <= 0 then
		return false
	end
	return holdAt >= accel and holdAt < accel + cruise
end

-- Motion clock. Wall time keeps moving. Travel time does not, for holdFor
-- seconds starting at holdAt.
function Hold.motionTime(elapsed: number, holdAt: number, holdFor: number): number
	local t = math.max(0, elapsed)
	if holdFor <= 0 then
		return t
	end
	if t <= holdAt then
		return t
	end
	if t < holdAt + holdFor then
		return holdAt
	end
	return t - holdFor
end

function Hold.moving(elapsed: number, holdAt: number, holdFor: number): boolean
	if holdFor <= 0 then
		return true
	end
	return elapsed < holdAt or elapsed >= holdAt + holdFor
end

function Hold.wallDuration(segmentLength: number, held: boolean, holdFor: number): number
	if held and holdFor > 0 then
		return segmentLength + holdFor
	end
	return segmentLength
end

-- "blackout" is the door tick. A hold cannot select it.
function Hold.blacksOutCar(effect: string): boolean
	return effect == "blackout" or effect == "whole_car"
end

function Hold.plan(effect: string): string
	if effect == "dim" then
		return "dim"
	end
	return "strip"
end

-- A hold dim stays above off. Zero would be a blackout.
function Hold.dimTarget(fraction: number): number
	if fraction <= 0 then
		return 0.55
	end
	return math.clamp(fraction, 0.05, 1)
end

-- Caught-staring is not in this port. The number is what that check would
-- multiply by while the train is held. Nothing here looks at the player.
function Hold.stareScale(held: boolean, multiplier: number): number
	if held then
		return multiplier
	end
	return 1
end

-- Only an id the anomaly catalog already has. Anything else is dropped.
function Hold.tell(kind: string): string?
	if kind == "poster_changed" or kind == "wrong_announcement" or kind == "wrong_countdown" then
		return kind
	end
	return nil
end

return Hold
