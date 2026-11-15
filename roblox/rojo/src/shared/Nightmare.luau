--!strict
-- Nightmare mode tuning from src/constants.ts NIGHTMARE.
-- Unlocked after one completed full (non-practice) ride.

local Nightmare = {}

Nightmare.CRUISE = 0.75
Nightmare.SPEED = 1.2
Nightmare.DRIFT = 1.5
Nightmare.MIN_DRIFT = -2

function Nightmare.cruiseSeconds(base: number, on: boolean): number
	if not on then
		return base
	end
	return math.max(4, base * Nightmare.CRUISE)
end

function Nightmare.topSpeed(base: number, on: boolean): number
	if not on then
		return base
	end
	return base * Nightmare.SPEED
end

function Nightmare.driftDelta(base: number, on: boolean): number
	if not on then
		return base
	end
	local scaled = base * Nightmare.DRIFT
	if scaled > Nightmare.MIN_DRIFT then
		return Nightmare.MIN_DRIFT
	end
	return scaled
end

return Nightmare
