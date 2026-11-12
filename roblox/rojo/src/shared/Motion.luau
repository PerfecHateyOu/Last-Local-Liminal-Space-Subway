--!strict
-- Speed and distance along one stretch. Port of gameState.segVel / segPos.
-- smoothstep accel, steady cruise, smoothstep brake. Times are the slice's
-- ACCEL, sliceCruise and BRAKE, so the scenery and the stop timer agree.

local Motion = {}

function Motion.smooth(x: number): number
	local u = math.clamp(x, 0, 1)
	return u * u * (3 - 2 * u)
end

function Motion.speed(t: number, accel: number, cruise: number, brake: number, top: number): number
	if t <= 0 or accel <= 0 or brake <= 0 then
		return 0
	end
	if t < accel then
		return top * Motion.smooth(t / accel)
	end
	if t < accel + cruise then
		return top
	end
	if t < accel + cruise + brake then
		return top * (1 - Motion.smooth((t - accel - cruise) / brake))
	end
	return 0
end

-- Metres travelled since the start of the stretch. At the end of braking
-- this is top * (accel/2 + cruise + brake/2), matching segDist.
function Motion.distance(t: number, accel: number, cruise: number, brake: number, top: number): number
	if t <= 0 or accel <= 0 or brake <= 0 then
		return 0
	end
	local length = accel + cruise + brake
	if t >= length then
		return top * (accel / 2 + cruise + brake / 2)
	end
	if t <= accel then
		local u = t / accel
		return top * accel * (u * u * u - (u * u * u * u) / 2)
	end
	local travelled = top * accel / 2
	if t <= accel + cruise then
		return travelled + top * (t - accel)
	end
	travelled += top * cruise
	local u = math.clamp((t - accel - cruise) / brake, 0, 1)
	return travelled + top * brake * (u - (u * u * u - (u * u * u * u) / 2))
end

function Motion.segmentDistance(accel: number, cruise: number, brake: number, top: number): number
	return top * (accel / 2 + cruise + brake / 2)
end

return Motion
