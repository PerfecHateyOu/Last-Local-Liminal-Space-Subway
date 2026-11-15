--!strict
-- Greenpoint restraint state machine.
-- Run: luau tools/restraint_spec.luau

local Restraint = require("../src/shared/Restraint")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("starts after 8s", Restraint.shouldStart(true, false, 8.0, 8.0, false))
check("not before 8s", not Restraint.shouldStart(true, false, 7.9, 8.0, false))
check("not when done", not Restraint.shouldStart(true, true, 9.0, 8.0, false))
check("not when busy", not Restraint.shouldStart(true, false, 9.0, 8.0, true))

local waiting = Restraint.newState(15)
check("wait tick", Restraint.tick(waiting, 1.0, false) == "wait")
check("fail wait", Restraint.tick(waiting, 4.1, false) == "fail_wait")

local hold = Restraint.newState(15)
check("start hold", Restraint.tick(hold, 0.2, true) == "holding")
check("progress early", Restraint.progress(hold) < 0.1)
check("release fails", Restraint.tick(hold, 0.1, false) == "fail_release")

local full = Restraint.newState(2)
Restraint.tick(full, 0.1, true)
check("still holding", Restraint.tick(full, 1.0, true) == "holding")
check("succeeds", Restraint.tick(full, 1.0, true) == "ok")
check("progress done", Restraint.progress(full) >= 1)

local beats = Restraint.newState(15)
beats.started = true
beats.t = 1.6
check("mom beat", Restraint.shouldFireBeat(beats, Restraint.BEAT_MOM))
check("mom beat once", not Restraint.shouldFireBeat(beats, Restraint.BEAT_MOM))

check("dim floors at 0.4", Restraint.dimFraction(10) == 0.4)
check("dim starts at 1", Restraint.dimFraction(0) == 1)

local grace = Restraint.newState(15)
grace.started = true
grace.t = 3
Restraint.grantGrace(grace, 2.5)
check("grace ignores release", Restraint.tick(grace, 0.2, false) == "wait")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("restraint spec ok")
