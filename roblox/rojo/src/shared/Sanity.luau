--!strict
-- Sanity bands, tiers, and clamps from src/constants.ts / engineVitals.ts.
-- The Ride attribute is absolute 0–100; each stretch clamps into that stop's
-- band. Holding the Greenpoint restraint raises the ceiling for stops 11–13.

local Sanity = {}

Sanity.TIER_HIGH = "high"
Sanity.TIER_MEDIUM = "medium"
Sanity.TIER_LOW = "low"
Sanity.TIER_CRITICAL = "critical"

-- Web BANDS by stop number.
local BANDS: { [number]: { number } } = {
	[1] = { 80, 100 },
	[2] = { 80, 100 },
	[3] = { 80, 100 },
	[4] = { 70, 95 },
	[5] = { 50, 85 },
	[6] = { 50, 85 },
	[7] = { 30, 70 },
	[8] = { 30, 70 },
	[9] = { 30, 70 },
	[10] = { 5, 30 },
	[11] = { 0, 9 },
	[12] = { 0, 9 },
	[13] = { 0, 9 },
}

-- Web DRIFT: only where the band ceiling drops.
local DRIFT: { [number]: number } = {
	[2] = 0,
	[3] = 0,
	[4] = -5,
	[5] = -5,
	[6] = 0,
	[7] = -5,
	[8] = 0,
	[9] = 0,
	[10] = -5,
	[11] = -5,
	[12] = 0,
	[13] = 0,
}

function Sanity.tierOf(san: number): string
	if san >= 75 then
		return Sanity.TIER_HIGH
	end
	if san >= 40 then
		return Sanity.TIER_MEDIUM
	end
	if san >= 10 then
		return Sanity.TIER_LOW
	end
	return Sanity.TIER_CRITICAL
end

function Sanity.bandForStop(stop: number, restraintOk: boolean, raise: number): (number, number)
	local pair = BANDS[stop]
	local lo = if pair ~= nil then pair[1] else 0
	local hi = if pair ~= nil then pair[2] else 9
	if stop >= 11 and restraintOk then
		hi += raise
	end
	return lo, hi
end

function Sanity.driftForStop(stop: number): number
	local d = DRIFT[stop]
	if d == nil then
		return -5
	end
	return d
end

function Sanity.clamp(value: number, lo: number, hi: number): number
	return math.clamp(value, lo, hi)
end

-- Apply a delta inside the current stop band (web addSanity).
function Sanity.apply(current: number, delta: number, lo: number, hi: number): number
	return Sanity.clamp(current + delta, lo, hi)
end

-- Position inside the band, 0–1, for Sanity Retained (PR14 report).
function Sanity.bandPosition(san: number, lo: number, hi: number): number
	if hi <= lo then
		return 1
	end
	return math.clamp((san - lo) / (hi - lo), 0, 1)
end

function Sanity.retainedPercent(samples: { number }): number
	if #samples == 0 then
		return 0
	end
	local sum = 0
	for _, pos in samples do
		sum += pos
	end
	return math.floor((100 * sum) / #samples + 0.5)
end

return Sanity
