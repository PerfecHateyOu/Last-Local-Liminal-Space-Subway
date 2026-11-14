--!strict
-- Trestle mouth timing. Run: luau tools/trestle_spec.luau

local Trestle = require("../src/shared/Trestle")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local to12 = Trestle.plan(12, false, 100, 200)
check("exit at 25%", math.abs(to12.exitAt - 150) < 0.01)
check("no enter on 12", to12.enterAt == nil)
check("before mouth tunnel", Trestle.outsideLevel(140, to12) == 0)
check("after blend open", Trestle.outsideLevel(150 + Trestle.BLEND_M, to12) == 1)
check("mid blend", Trestle.outsideLevel(150 + Trestle.BLEND_M * 0.5, to12) > 0.4)

local to13 = Trestle.plan(13, false, 300, 200)
check("enter at 60%", to13.enterAt ~= nil and math.abs((to13.enterAt :: number) - 420) < 0.01)
check("start of 13 outside", Trestle.outsideLevel(300, to13) == 1)
check("after reenter tunnel", Trestle.outsideLevel(420 + Trestle.BLEND_M, to13) == 0)

local quiet = Trestle.plan(8, false, 0, 100)
check("early stop tunnel", Trestle.outsideLevel(50, quiet) == 0)
check("12b no trestle", Trestle.plan(12, true, 0, 100).exitAt >= math.huge)

check("arriving open 12", Trestle.arrivingOpenAir(12, false))
check("leaving open 13", Trestle.leavingOpenAir(13))
check("show threshold", Trestle.show(0.1) and not Trestle.show(0.01))

if failures == 0 then
	print("trestle_spec: ok")
else
	print(string.format("trestle_spec: %d failure(s)", failures))
	os.exit(1)
end
