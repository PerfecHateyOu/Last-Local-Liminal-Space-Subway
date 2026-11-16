--!strict
-- Shared sitting-still distance counts only the ride owner's steps.
-- Run: luau tools/motion_spec.luau

local Motion = require("../src/shared/Motion")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local owner = 10
local guest = 20

check("owner steps count", Motion.addOwnerMove(0, owner, owner, 1.5) == 1.5)
check("owner steps accumulate", Motion.addOwnerMove(1.5, owner, owner, 0.25) == 1.75)
check("guest steps do not count", Motion.addOwnerMove(1.75, guest, owner, 4) == 1.75)
check("no owner counts nobody", Motion.addOwnerMove(1.75, owner, nil, 3) == 1.75)
check("zero owner step stays put", Motion.addOwnerMove(1.75, owner, owner, 0) == 1.75)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("motion spec ok")
