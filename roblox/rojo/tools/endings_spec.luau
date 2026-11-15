--!strict
-- Court Square resolveEnding priority order.
-- Run: luau tools/endings_spec.luau

local Endings = require("../src/shared/Endings")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local function base(): Endings.EndingSummary
	return {
		peak = 5,
		interventions = 0,
		trialStops = {},
		sanPct = 80,
		accPct = 100,
		restraintOK = true,
		tapes = {},
		exit = "escalators",
	}
end

local function endId(p: { [string]: any }): string
	local s = base()
	for k, v in p do
		(s :: any)[k] = v
	end
	return Endings.resolve(s).id
end

check("secret mask beats all", endId({ peak = 0, sanPct = 10, trialStops = { 12 } }) == "secret_mask")
check("eternal from bait trial", endId({ trialStops = { 12 } }) == "eternal_commute")
check("eternal from low sanity", endId({ sanPct = 29 }) == "eternal_commute")
check("not eternal at 30", endId({ sanPct = 30 }) ~= "eternal_commute")

check(
	"signal archivist",
	endId({
		exit = "lower_level",
		tapes = { "a", "b" },
		accPct = 75,
		peak = Endings.COMPOSED_PEAK,
	}) == "signal_archivist"
)
check(
	"signal needs 2 tapes",
	endId({
		exit = "lower_level",
		tapes = { "a" },
		accPct = 75,
		peak = Endings.COMPOSED_PEAK,
	}) ~= "signal_archivist"
)

check("skyward void", endId({ exit = "surface_hatch" }) == "skyward_void")
check(
	"skyward needs restraint",
	endId({ exit = "surface_hatch", restraintOK = false }) == "civilian_extraction"
)

check("dawn horizon", endId({ tapes = { "conductor" } }) == "dawn_horizon")
check(
	"dawn needs sanity",
	endId({ tapes = { "conductor" }, sanPct = 59 }) == "civilian_extraction"
)

check("exposed", endId({ interventions = 1 }) == "exposed")
check("collapse", endId({ trialStops = { 4 } }) == "collapse")
check("civilian", endId({}) == "civilian_extraction")

check("acc 100 when empty", Endings.accuracyPercent(0, 0) == 100)
check("acc half", Endings.accuracyPercent(1, 1) == 50)
check("normalize exit", Endings.normalizeExit("nope") == "escalators")
check("composed peak is 30", Endings.COMPOSED_PEAK == 30)

-- No hard fail: peak 100 with intervention still resolves (exposed), never a special fail id.
check("peak 100 still an ending", endId({ peak = 100, interventions = 1 }) == "exposed")

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("endings spec ok")
