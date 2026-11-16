--!nonstrict
-- MetaStore: block cloud writes after a missed read, retry, and merge.
-- Run: luau tools/meta_store_spec.luau
--
-- Merge rule exercised here (session has not yet absorbed a cloud read):
--   runsCompleted and endings[].count = session + cloud, once
--   nightmareUnlocked = either side, or runsCompleted > 0
--   anomalyTypes = union of true flags
--   achievements = union of ids; unlockedAt stays with cloud when both have the id
--   tapes = union by signalId, cloud order then session-only; cloud payload wins
--   album = union by id, cloud order then session-only; framed is a union of ids
--   discoveredAt stays with cloud when both sides have the ending
-- A read that already committed while GetAsync was in flight is left alone.

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local calls = { getAsync = 0, setAsync = 0 }
local setAsyncLog = {}
local getDataStoreError = false
local handlers: { [string]: () -> any } = {}

local fakeStore = {}

function fakeStore:GetAsync(key: string)
	calls.getAsync += 1
	local handler = handlers[key]
	if handler == nil then
		error("no GetAsync handler for " .. key)
	end
	return handler()
end

function fakeStore:SetAsync(key: string, value)
	calls.setAsync += 1
	table.insert(setAsyncLog, { key = key, runs = value.runsCompleted })
end

local DataStoreService = {}

function DataStoreService:GetDataStore(_name: string)
	if getDataStoreError then
		error("DataStore unavailable")
	end
	return fakeStore
end

local MetaStore = require("../src/server/MetaStore")
MetaStore.setDataStoreService(DataStoreService)

local function tape(id: string, title: string)
	return {
		signalId = id,
		title = title,
		stop = "Hoyt",
		freq = "1.0",
		transcript = title,
	}
end

local function photo(id: string, framed: { string })
	return { id = id, framed = framed }
end

local function cloud(partial)
	local save = {
		runsCompleted = 0,
		nightmareUnlocked = false,
		endings = {},
		achievements = {},
		tapes = {},
		album = {},
		anomalyTypes = {},
	}
	if partial ~= nil then
		for key, value in partial do
			save[key] = value
		end
	end
	return save
end

local function hasTape(save, id: string, title: string): boolean
	for _, entry in save.tapes do
		if entry.signalId == id and entry.title == title then
			return true
		end
	end
	return false
end

-- HIGH 1 + HIGH 2: DataStore missing, then a later read must merge and resume saves.
getDataStoreError = true
local raw101 = cloud({
	runsCompleted = 5,
	nightmareUnlocked = false,
	endings = {
		civilian_extraction = { count = 4, discoveredAt = 100 },
		missed_stop = { count = 2, discoveredAt = 40 },
	},
	achievements = {
		first_anomaly = { unlockedAt = 50 },
		photo_evidence = { unlockedAt = 10 },
	},
	tapes = { tape("old", "Old") },
	album = { photo("p1", { "poster_changed" }) },
	anomalyTypes = { extra = true },
})
handlers["u_101"] = function()
	return raw101
end

local data101 = MetaStore.load(101)
check("unreachable store seeds empty", data101.runsCompleted == 0)
data101.runsCompleted = 1
data101.nightmareUnlocked = true
data101.endings = {
	civilian_extraction = { count = 1, discoveredAt = 999 },
	loop_breaker = { count = 1, discoveredAt = 999 },
}
data101.achievements = { photo_evidence = { unlockedAt = 888 } }
data101.tapes = { tape("old", "SessionOld"), tape("live", "Live") }
data101.album = { photo("p1", { "extra", "poster_changed" }), photo("p2", { "mom" }) }
data101.anomalyTypes = { photo = true }

getDataStoreError = false
local setsBeforeBlock = calls.setAsync
MetaStore.save(101, data101)
check("blocked save does not SetAsync", calls.setAsync == setsBeforeBlock)

local merged101 = MetaStore.load(101)
check("retry keeps the session table", merged101 == data101)
check("runs add session delta to cloud", merged101.runsCompleted == 6)
check("nightmare unlock sticks", merged101.nightmareUnlocked == true)
check("ending counts add", merged101.endings.civilian_extraction.count == 5)
check("shared ending keeps cloud time", merged101.endings.civilian_extraction.discoveredAt == 100)
check("session-only ending kept", merged101.endings.loop_breaker.count == 1)
check("session-only ending keeps its time", merged101.endings.loop_breaker.discoveredAt == 999)
check("cloud-only ending kept", merged101.endings.missed_stop.count == 2)
check("cloud-only ending keeps its time", merged101.endings.missed_stop.discoveredAt == 40)
check("cloud achievement kept", merged101.achievements.first_anomaly.unlockedAt == 50)
check("shared achievement keeps cloud time", merged101.achievements.photo_evidence.unlockedAt == 10)
check("cloud tape payload wins", hasTape(merged101, "old", "Old"))
check("session tape payload dropped on conflict", not hasTape(merged101, "old", "SessionOld"))
check("session-only tape kept", hasTape(merged101, "live", "Live"))
check("cloud tape ordered first", merged101.tapes[1].signalId == "old")
check("framed ids union without dupes", table.concat(merged101.album[1].framed, ",") == "poster_changed,extra")
check("session-only photo kept", merged101.album[2].id == "p2")
check("anomaly flags union", merged101.anomalyTypes.extra == true and merged101.anomalyTypes.photo == true)
check("cloud snapshot not mutated", raw101.runsCompleted == 5 and raw101.endings.civilian_extraction.count == 4)

local getsAfterMerge = calls.getAsync
local again101 = MetaStore.load(101)
check("committed load does not add cloud again", again101.runsCompleted == 6)
check("committed load does not refetch", calls.getAsync == getsAfterMerge)

local setsBeforeResume = calls.setAsync
MetaStore.save(101, merged101)
check("successful retry resumes cloud writes", calls.setAsync == setsBeforeResume + 1)
check("resumed write stores merged runs", setAsyncLog[#setAsyncLog].runs == 6)

-- Fresh successful read: cloud is the save, and a later load stays on that copy.
handlers["u_104"] = function()
	return cloud({ runsCompleted = 5, nightmareUnlocked = true })
end
local data104 = MetaStore.load(104)
check("fresh load uses cloud runs", data104.runsCompleted == 5)
check("fresh load uses cloud nightmare", data104.nightmareUnlocked == true)
local gets104 = calls.getAsync
local again104 = MetaStore.load(104)
check("fresh session copy sticks", again104 == data104 and again104.runsCompleted == 5)
check("open key does not refetch", calls.getAsync == gets104)

-- nil raw is a real first-time player, safe to persist.
handlers["u_105"] = function()
	return nil
end
local data105 = MetaStore.load(105)
check("nil raw is an empty save", data105.runsCompleted == 0 and data105.nightmareUnlocked == false)
local sets105 = calls.setAsync
MetaStore.save(105, data105)
check("nil raw is allowed to persist", calls.setAsync == sets105 + 1)

-- GetAsync failure blocks, then a later success folds the cloud snapshot in.
local fail106 = true
handlers["u_106"] = function()
	if fail106 then
		error("GetAsync down")
	end
	return cloud({
		runsCompleted = 4,
		nightmareUnlocked = false,
		tapes = { tape("cloud-tape", "C") },
		anomalyTypes = { extra = true },
	})
end
local data106 = MetaStore.load(106)
check("failed GetAsync seeds empty", data106.runsCompleted == 0)
data106.runsCompleted = 2
data106.tapes = { tape("session-tape", "S") }
data106.anomalyTypes = { photo = true }
local sets106 = calls.setAsync
MetaStore.save(106, data106)
check("failed GetAsync blocks save", calls.setAsync == sets106)
fail106 = false
local merged106 = MetaStore.load(106)
check("failed-read retry sums runs", merged106.runsCompleted == 6)
check("failed-read retry keeps both tapes", hasTape(merged106, "cloud-tape", "C") and hasTape(merged106, "session-tape", "S"))
check("failed-read retry unions flags", merged106.anomalyTypes.extra == true and merged106.anomalyTypes.photo == true)
check("nightmare unlocks when merged runs > 0", merged106.nightmareUnlocked == true)
local sets106b = calls.setAsync
MetaStore.save(106, merged106)
check("failed-read retry resumes saves", calls.setAsync == sets106b + 1)

-- MEDIUM 1: a nested load commits and the caller advances memory before the outer read returns.
local nested103 = false
handlers["u_103"] = function()
	if not nested103 then
		nested103 = true
		local other = MetaStore.load(103)
		other.runsCompleted += 3
		other.tapes = { tape("shared", "SESSION") }
		MetaStore.save(103, other)
		return cloud({
			runsCompleted = 5,
			tapes = { tape("shared", "CLOUD") },
		})
	end
	return cloud({
		runsCompleted = 5,
		tapes = { tape("shared", "CLOUD") },
	})
end
local result103 = MetaStore.load(103)
check("in-flight commit keeps newer runs", result103.runsCompleted == 8)
check("in-flight commit keeps newer tape", result103.tapes[1] ~= nil and result103.tapes[1].title == "SESSION")

-- Memory written during GetAsync, with no committed cloud read yet, is merged not replaced.
local armed107 = true
handlers["u_107"] = function()
	if armed107 then
		armed107 = false
		local progress = MetaStore.empty()
		progress.runsCompleted = 2
		progress.nightmareUnlocked = true
		progress.tapes = { tape("kept", "Kept") }
		MetaStore.save(107, progress)
	end
	return cloud({
		runsCompleted = 5,
		nightmareUnlocked = false,
		tapes = { tape("from-cloud", "Cloud") },
	})
end
local result107 = MetaStore.load(107)
check("mid-read memory is merged", result107.runsCompleted == 7)
check("mid-read merge keeps cloud tape first", result107.tapes[1].signalId == "from-cloud")
check("mid-read merge keeps session tape", result107.tapes[2].signalId == "kept")
check("mid-read nightmare sticks", result107.nightmareUnlocked == true)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("meta store spec ok")
