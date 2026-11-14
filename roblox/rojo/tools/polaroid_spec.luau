--!strict
-- Polaroid framing / flash helpers. Run: luau tools/polaroid_spec.luau

local Polaroid = require("../src/shared/Polaroid")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

-- Plain XYZ tables: Polaroid.inFrame only reads .X/.Y/.Z.
local function v3(x: number, y: number, z: number): any
	return { X = x, Y = y, Z = z }
end

local s = 3
local cam = v3(0, 3, 0)
local look = v3(1, 0, 0)
check("ahead in cone", Polaroid.inFrame(cam, look, v3(9, 3, 0), s))
check("too far", not Polaroid.inFrame(cam, look, v3(60, 3, 0), s))
check("beside out of cone", not Polaroid.inFrame(cam, look, v3(3, 3, 9), s))

check("catch match", Polaroid.photoCatches({ "seat6", "x" }, { "announcement", "seat6" }))
check("no catch", not Polaroid.photoCatches({ "mom" }, { "seat6" }))

check("watched flash", Polaroid.flashWatched("watched"))
check("calm not watched", not Polaroid.flashWatched("calm"))
check("film clamp", Polaroid.clampFilm(99) == Polaroid.MAX_FILM)

if failures == 0 then
	print("polaroid_spec: ok")
else
	print(string.format("polaroid_spec: %d failure(s)", failures))
	os.exit(1)
end
