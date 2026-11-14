--!strict
-- Polaroid 600 rules from polaroidManager.ts / engineTools.ts.
-- A shot privately records framed anomalies; the stop scores them like a flag.
-- Flash may raise suspicion when parents are alert, or make one glance.

local Polaroid = {}

Polaroid.STARTING_FILM = 8
Polaroid.MAX_FILM = 10
Polaroid.SHUTTER_COOLDOWN = 0.9
Polaroid.FLASH_GLANCE_CHANCE = 0.5
-- Web frustum cone (~0.65 rad) and max distance (18 m).
Polaroid.CONE_RAD = 0.65
Polaroid.MAX_RANGE_M = 18
-- SUS.visible in constants.ts
Polaroid.FLASH_WATCH_SUSPICION = 10

export type Photo = {
	id: string,
	stop: string,
	framed: { string },
	developed: boolean,
}

function Polaroid.inFrame(camPos: Vector3, lookDir: Vector3, targetPos: Vector3, studsPerMeter: number): boolean
	local ox = targetPos.X - camPos.X
	local oy = targetPos.Y - camPos.Y
	local oz = targetPos.Z - camPos.Z
	local dist = math.sqrt(ox * ox + oy * oy + oz * oz)
	if dist > Polaroid.MAX_RANGE_M * studsPerMeter or dist < 0.05 then
		return false
	end
	local lookLen = math.sqrt(lookDir.X * lookDir.X + lookDir.Y * lookDir.Y + lookDir.Z * lookDir.Z)
	if lookLen < 0.05 then
		return false
	end
	local lx = lookDir.X / lookLen
	local ly = lookDir.Y / lookLen
	local lz = lookDir.Z / lookLen
	local tx = ox / dist
	local ty = oy / dist
	local tz = oz / dist
	local cosAngle = lx * tx + ly * ty + lz * tz
	-- angle < CONE_RAD ⇔ cos > cos(CONE_RAD)
	return cosAngle >= math.cos(Polaroid.CONE_RAD)
end

function Polaroid.photoCatches(framed: { string }, liveIds: { string }): boolean
	for _, framedId in framed do
		for _, liveId in liveIds do
			if framedId == liveId then
				return true
			end
		end
	end
	return false
end

-- Watched/hunted bands: parents are alert enough that a flash counts as visible.
function Polaroid.flashWatched(band: string): boolean
	return band == "watched" or band == "hunted"
end

function Polaroid.clampFilm(n: number): number
	return math.clamp(math.floor(n + 0.5), 0, Polaroid.MAX_FILM)
end

return Polaroid
