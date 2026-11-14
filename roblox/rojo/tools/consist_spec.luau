--!strict
-- Car letter from position along the consist. Run: luau tools/consist_spec.luau

local Route = require("../src/shared/Route")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("mid car", Route.carLabel(0) == "CAR B (MID)")
check("front of B still mid", Route.carLabel(-10.0) == "CAR B (MID)")
check("into gangway A", Route.carLabel(-10.3) == "CAR A (LEAD)")
check("deep A", Route.carLabel(-22) == "CAR A (LEAD)")
check("rear of B still mid", Route.carLabel(10.0) == "CAR B (MID)")
check("into gangway C", Route.carLabel(10.3) == "CAR C (REAR)")
check("deep C", Route.carLabel(23) == "CAR C (REAR)")

local line = Route.chapterLine(1)
check("default chapter mid", string.find(line, "CAR B %(MID%)", 1, false) ~= nil)

local swapped = Route.withCarLabel(line, "CAR A (LEAD)")
check("swap to A", string.find(swapped, "CAR A %(LEAD%)", 1, false) ~= nil)
check("swap keeps chapter", string.find(swapped, "THE DESCENT", 1, true) ~= nil)

if failures == 0 then
	print("consist_spec: ok")
else
	print(string.format("consist_spec: %d failure(s)", failures))
	os.exit(1)
end
