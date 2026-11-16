--!strict
-- Door open/close / EVP attack windows.
-- Run: luau tools/door_sound_spec.luau

local DoorSound = require("../src/shared/DoorSound")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

do
	local s, e = DoorSound.edgeWindow(8.15, true)
	check("open start 0", near(s, 0))
	check("open end 4.45", near(e, 4.45))
end

do
	local s, e = DoorSound.edgeWindow(8.15, false)
	check("close start 4.45", near(s, 4.45))
	check("close end length", near(e, 8.15))
end

do
	local s, e = DoorSound.edgeWindow(1.2, true)
	check("short open full", near(s, 0) and near(e, 1.2))
	local s2, e2 = DoorSound.edgeWindow(1.2, false)
	check("short close full", near(s2, 0) and near(e2, 1.2))
end

do
	local s, e = DoorSound.edgeWindow(5.9, true)
	check("under 6s is full open", near(s, 0) and near(e, 5.9))
end

do
	local s, e = DoorSound.evpAttackWindow(8.15)
	check("evp start 0.75", near(s, 0.75))
	check("evp end 1.10", near(e, 1.10))
end

do
	local s, e = DoorSound.evpAttackWindow(0.5)
	check("evp short falls back to full", near(s, 0) and near(e, 0.5))
end

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("door_sound spec ok")
