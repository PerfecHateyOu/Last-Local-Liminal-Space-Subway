--!strict
-- Suspicion HUD copy. Run: luau tools/lines_spec.luau

local Lines = require("../src/shared/Lines")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("calm label", Lines.bandLabel("calm") == "CALM")
check("uneasy label", Lines.bandLabel("uneasy") == "UNEASY")
check("watched label", Lines.bandLabel("watched") == "WATCHED")
check("hunted label", Lines.bandLabel("hunted") == "HUNTED")
check("unknown band is calm", Lines.bandLabel("other") == "CALM")

check("zero calm", Lines.suspicionMeter(0, "calm") == "0 CALM")
check("25 uneasy", Lines.suspicionMeter(25, "uneasy") == "25 UNEASY")
check("50 watched", Lines.suspicionMeter(50, "watched") == "50 WATCHED")
check("75 hunted", Lines.suspicionMeter(75, "hunted") == "75 HUNTED")
check("rounds half up", Lines.suspicionMeter(24.6, "calm") == "25 CALM")
check("clamps high", Lines.suspicionMeter(140, "hunted") == "100 HUNTED")
check("clamps low", Lines.suspicionMeter(-3, "calm") == "0 CALM")

if failures == 0 then
	print("OK lines_spec")
else
	print(string.format("%d FAIL", failures))
	error("lines_spec failed")
end
