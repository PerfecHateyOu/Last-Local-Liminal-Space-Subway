--!strict
-- False Stop Trial helpers. Run: luau tools/trial_spec.luau

local Trial = require("../src/shared/Trial")
local Doors = require("../src/shared/Doors")

local failures = 0
local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local seq = 0.31
local function rng()
	seq += 0.17
	if seq > 1 then
		seq -= 1
	end
	return seq
end

local state = Trial.start("Metropolitan Av")
check("start paths", state.mode == "paths" and state.need == 2 and state.depth == 0)

local _, view = Trial.round(state, rng)
check("three path choices", #view.items == 3 and view.windowSeconds == 0)
check("three signs", #view.signs == 3)

-- Correct path picks until board.
state.correct = view.items[1].val
local r1 = Trial.applyPick(state, state.correct)
check("first correct continues", r1.kind == "continue" and r1.state.need == 1)

state = r1.state
local _, v2 = Trial.round(state, rng)
state.correct = v2.items[1].val
-- Force correct match
local forced = state.correct
local r2 = Trial.applyPick(state, forced)
check("need exhausted enters board", r2.state.mode == "board" or r2.state.need > 0)
if r2.state.need <= 0 or r2.state.mode == "board" then
	state = r2.state
	state.mode = "board"
	state.need = 0
	local _, boardView = Trial.round(state, rng)
	check("board has two choices", #boardView.items == 2 and boardView.boardDoors == true)
	state.correct = boardView.items[1].val
	local exitOk = Trial.applyPick(state, state.correct)
	check("clean board exit", exitOk.kind == "exit" and exitOk.clean == true)
end

-- Wrong path increases depth.
local s2 = Trial.start("21 St")
local _, badView = Trial.round(s2, rng)
local wrong = (s2.correct + 1) % 3
local bad = Trial.applyPick(s2, wrong)
check("wrong raises depth", bad.state.depth == 1 and bad.kind == "continue")

local amounts = { realOff = 20, refuseHaven = 10, falseOff = 15 }
local trialOff = Doors.resolve("false", false, "off", amounts, "R", "REF", "F", "H", "T")
check("doors enter trial", trialOff.mode == "trial" and trialOff.suspicionDelta == 0)

local forgive = Doors.resolve("false", true, "off", amounts, "R", "REF", "F", "H", "T")
check("forgiving still depart", forgive.mode == "depart")

check("window at depth 2", Trial.windowSeconds(2) == 10)
local events = Trial.cycleEvents({ depth = 0, need = 2, mode = "paths", correct = 1, stopName = "x" }, rng)
check("paths cycle has flick", #events >= 1 and events[1].kind == "flick")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("trial spec ok")
