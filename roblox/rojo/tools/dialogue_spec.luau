--!strict
-- Parent chat / mask helpers. Run: luau tools/dialogue_spec.luau

local Dialogue = require("../src/shared/Dialogue")

local failures = 0
local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("mom name", Dialogue.parentName(0) == "Mom")
check("dad name", Dialogue.parentName(1) == "Dad")
check("chat format", Dialogue.chatLine(0, "Hi") == "Mom: Hi")

local seq = 0
local function rng()
	seq += 0.17
	if seq > 1 then
		seq -= 1
	end
	return seq
end

local plan = Dialogue.buildChatPlan(rng)
check("chat 0 present", plan[0] ~= nil and #plan[0] == 2)
check("chat 4 present", plan[4] ~= nil)

local pool = Dialogue.maskPool(0, 10)
check("needsSus filtered at 0", #pool == 7)
local poolSus = Dialogue.maskPool(10, 10)
check("needsSus included at 10", #poolSus == 8)

local used: { [string]: boolean } = {}
local a = Dialogue.pickMask(poolSus, used, nil, rng)
check("pick returns a line", a ~= nil)
if a ~= nil then
	used[a.line] = true
	local b = Dialogue.pickMask(poolSus, used, a.line, rng)
	local differs = b ~= nil
	if differs and #poolSus > 1 and b ~= nil then
		differs = b.line ~= a.line
	end
	check("second pick differs when possible", differs)
end
check("hesitate copy", string.find(Dialogue.maskHesitate(0), "Mom", 1, true) ~= nil)
check("you answer", string.find(Dialogue.youAnswer("Yeah.", 1), "Dad", 1, true) ~= nil)

local answers = Dialogue.shuffleAnswers("calm", "off1", "off2", rng)
check("three answers", #answers == 3)
local calmCount = 0
for _, item in answers do
	if item.val == "calm" then
		calmCount += 1
	end
end
check("one calm answer", calmCount == 1)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("dialogue spec ok")
