--!strict
-- Minimum-dwell math. The server owns the clock and whether anyone asked
-- to leave early. This module only updates the suspicion number.
-- The result stays in range. It does not end the ride.

local Dwell = {}

-- When the train may leave. lieHold is the existing PA-lie wait from
-- arrival, or nil when that stop has no lie. The result is never earlier
-- than openAt + minimum.
function Dwell.departTime(openAt: number, minimum: number, lieHold: number?): number
	local departAt = openAt + minimum
	if lieHold ~= nil then
		return math.max(departAt, lieHold)
	end
	return departAt
end

function Dwell.departureSuspicion(
	current: number,
	elapsed: number,
	minimum: number,
	requestedEarly: boolean,
	penalty: number,
	least: number,
	most: number
): number
	local nextValue = current
	if requestedEarly and elapsed < minimum then
		nextValue += penalty
	end
	return math.clamp(nextValue, least, most)
end

return Dwell
