--!strict
-- Port of src/game/personKeepOut.ts. Standing passengers occupy a circle on
-- the floor. The eye (here, the HumanoidRootPart centre) is pushed to the
-- edge of any circle it lands inside. Seated passengers are not in the list;
-- the benches keep the player off those spots.

local Constants = require(script.Parent.Constants)

local KeepOut = {}

export type Circle = {
	x: number,
	z: number,
	r: number,
}

function KeepOut.radiusStuds(): number
	return Constants.meters(Constants.KEEP_OUT_METERS)
end

-- Solid cylinder radius. Smaller than the eye radius by half the root width,
-- so a default character's centre stops on the 0.75 m circle.
function KeepOut.cylinderRadiusStuds(): number
	local radius = KeepOut.radiusStuds() - Constants.ROOT_HALF_WIDTH_STUDS
	return math.max(0.4, radius)
end

function KeepOut.pushOut(x: number, z: number, circles: { Circle }, prevX: number, prevZ: number): (number, number)
	for _, c in circles do
		local dx = x - c.x
		local dz = z - c.z
		local d = math.sqrt(dx * dx + dz * dz)
		if d < c.r then
			if d < 1e-6 then
				dx = prevX - c.x
				dz = prevZ - c.z
				local pd = math.sqrt(dx * dx + dz * dz)
				if pd < 1e-6 then
					dx = 0
					dz = if c.z > 0 then -1 else 1
				else
					dx /= pd
					dz /= pd
				end
			else
				dx /= d
				dz /= d
			end
			x = c.x + dx * c.r
			z = c.z + dz * c.r
		end
	end
	return x, z
end

return KeepOut
