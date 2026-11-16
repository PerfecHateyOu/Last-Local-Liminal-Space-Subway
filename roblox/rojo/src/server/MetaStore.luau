--!strict
-- Player meta progression: endings archive, achievements, tapes, album, run count.
-- Uses DataStore when available; falls back to an in-memory table (Studio / offline).
-- A missed read (no DataStore, or GetAsync error) keeps the session save and blocks cloud
-- writes so a later SetAsync cannot replace the real key with that empty seed.
-- While blocked, load retries. A successful retry folds cloud data into session progress
-- (mergeInto) and then allows saves. After a read commits, the session copy wins.

-- pcall so a standalone spec (no DataModel) can still load this module.
local dataStoreService: any = nil
do
	local ok, service = pcall(function()
		return game:GetService("DataStoreService")
	end)
	if ok then
		dataStoreService = service
	end
end
local HttpService: any = nil
do
	local ok, service = pcall(function()
		return game:GetService("HttpService")
	end)
	if ok then
		HttpService = service
	end
end

local MetaStore = {}

export type EndingEntry = { count: number, discoveredAt: number }
export type TapeEntry = { signalId: string, title: string, stop: string, freq: string, transcript: string }
export type PhotoEntry = { id: string, framed: { string } }

export type Save = {
	runsCompleted: number,
	nightmareUnlocked: boolean,
	endings: { [string]: EndingEntry },
	achievements: { [string]: { unlockedAt: number } },
	tapes: { TapeEntry },
	album: { PhotoEntry },
	anomalyTypes: { [string]: boolean },
}

local memory: { [string]: Save } = {}
-- Keys where a read has not committed: memory is session-only; skip SetAsync.
local cloudBlocked: { [string]: boolean } = {}
-- Bumped when a GetAsync result is committed. A racing failure must not re-block the
-- key, and a second success must not fold the same cloud snapshot in again.
local cloudEpoch: { [string]: number } = {}
local store: GlobalDataStore? = nil

if dataStoreService == nil then
	-- Spec seam only. Required modules cannot see a stub `game` in the luau CLI.
	function MetaStore.setDataStoreService(service: any)
		dataStoreService = service
		store = nil
	end
end

local function tryStore(): GlobalDataStore?
	if store ~= nil then
		return store
	end
	local ok, result = pcall(function()
		return dataStoreService:GetDataStore("LastLocalMeta_v1")
	end)
	if ok then
		store = result
		return store
	end
	return nil
end

function MetaStore.empty(): Save
	return {
		runsCompleted = 0,
		nightmareUnlocked = false,
		endings = {},
		achievements = {},
		tapes = {},
		album = {},
		anomalyTypes = {},
	}
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function fromRaw(raw: any): Save
	local s = MetaStore.empty()
	if typeof(raw) ~= "table" then
		return s
	end
	local t = raw :: any
	if typeof(t.runsCompleted) == "number" then
		s.runsCompleted = t.runsCompleted
	end
	s.nightmareUnlocked = t.nightmareUnlocked == true or s.runsCompleted > 0
	if typeof(t.endings) == "table" then
		s.endings = t.endings
	end
	if typeof(t.achievements) == "table" then
		s.achievements = t.achievements
	end
	if typeof(t.tapes) == "table" then
		s.tapes = t.tapes
	end
	if typeof(t.album) == "table" then
		s.album = t.album
	end
	if typeof(t.anomalyTypes) == "table" then
		s.anomalyTypes = t.anomalyTypes
	end
	return s
end

local function remember(k: string): Save
	local current = memory[k]
	if current == nil then
		current = MetaStore.empty()
		memory[k] = current
	end
	return current
end

local function copyTape(t: any): TapeEntry?
	if typeof(t) ~= "table" or typeof(t.signalId) ~= "string" then
		return nil
	end
	return {
		signalId = t.signalId,
		title = if typeof(t.title) == "string" then t.title else "",
		stop = if typeof(t.stop) == "string" then t.stop else "",
		freq = if typeof(t.freq) == "string" then t.freq else "",
		transcript = if typeof(t.transcript) == "string" then t.transcript else "",
	}
end

local function copyFramed(list: any, into: { string }, seen: { [string]: boolean })
	if typeof(list) ~= "table" then
		return
	end
	for _, id in list do
		if typeof(id) == "string" and not seen[id] then
			seen[id] = true
			table.insert(into, id)
		end
	end
end

-- Session counters started at the empty seed, so they are a delta on top of cloud.
-- Applied once per committed read (see cloudEpoch). Unlocks and sets union.
-- Timestamps and tape/photo payloads are not monotonic: keep the cloud value when
-- both sides have the same id.
local function mergeInto(session: Save, cloud: Save)
	session.runsCompleted += cloud.runsCompleted
	session.nightmareUnlocked = session.nightmareUnlocked or cloud.nightmareUnlocked or session.runsCompleted > 0

	for id, cloudEntry in cloud.endings do
		local cloudCount = 0
		local cloudAt: number? = nil
		if typeof(cloudEntry) == "table" then
			if typeof(cloudEntry.count) == "number" then
				cloudCount = cloudEntry.count
			end
			if typeof(cloudEntry.discoveredAt) == "number" then
				cloudAt = cloudEntry.discoveredAt
			end
		end
		local kept = session.endings[id]
		if kept == nil then
			session.endings[id] = {
				count = cloudCount,
				discoveredAt = if cloudAt ~= nil then cloudAt else 0,
			}
		else
			local sessionCount = if typeof(kept.count) == "number" then kept.count else 0
			kept.count = sessionCount + cloudCount
			if cloudAt ~= nil then
				kept.discoveredAt = cloudAt
			end
		end
	end

	for id, cloudAch in cloud.achievements do
		local cloudAt = 0
		if typeof(cloudAch) == "table" and typeof(cloudAch.unlockedAt) == "number" then
			cloudAt = cloudAch.unlockedAt
		end
		local kept = session.achievements[id]
		if kept == nil then
			session.achievements[id] = { unlockedAt = cloudAt }
		else
			kept.unlockedAt = cloudAt
		end
	end

	for id, flag in cloud.anomalyTypes do
		if flag == true then
			session.anomalyTypes[id] = true
		end
	end

	local seenTape: { [string]: boolean } = {}
	local tapes: { TapeEntry } = {}
	local function pushTape(t: any)
		local copy = copyTape(t)
		if copy == nil or seenTape[copy.signalId] then
			return
		end
		seenTape[copy.signalId] = true
		table.insert(tapes, copy)
	end
	for _, t in cloud.tapes do
		pushTape(t)
	end
	for _, t in session.tapes do
		pushTape(t)
	end
	session.tapes = tapes

	local sessionPhoto: { [string]: any } = {}
	for _, p in session.album do
		if typeof(p) == "table" and typeof(p.id) == "string" then
			sessionPhoto[p.id] = p
		end
	end
	local seenPhoto: { [string]: boolean } = {}
	local album: { PhotoEntry } = {}
	local function pushPhoto(p: any, preferCloudFramed: boolean)
		if typeof(p) ~= "table" or typeof(p.id) ~= "string" or seenPhoto[p.id] then
			return
		end
		seenPhoto[p.id] = true
		local framed: { string } = {}
		local seenFramed: { [string]: boolean } = {}
		local other = sessionPhoto[p.id]
		if preferCloudFramed then
			copyFramed(p.framed, framed, seenFramed)
			if other ~= nil then
				copyFramed(other.framed, framed, seenFramed)
			end
		else
			copyFramed(p.framed, framed, seenFramed)
		end
		table.insert(album, { id = p.id, framed = framed })
	end
	for _, p in cloud.album do
		pushPhoto(p, true)
	end
	for _, p in session.album do
		pushPhoto(p, false)
	end
	session.album = album
end

function MetaStore.load(userId: number): Save
	local k = keyFor(userId)
	-- A committed read owns the session copy. A blocked key retries GetAsync.
	local existing = memory[k]
	if existing ~= nil and not cloudBlocked[k] then
		return existing
	end

	local epochAtStart = cloudEpoch[k] or 0
	local ds = tryStore()
	if ds == nil then
		cloudBlocked[k] = true
		return remember(k)
	end

	-- Hold writes across the yield so a concurrent save cannot SetAsync the seed.
	cloudBlocked[k] = true
	local ok, raw = pcall(function()
		return ds:GetAsync(k)
	end)
	if (cloudEpoch[k] or 0) ~= epochAtStart then
		-- Another load already committed this key. Leave its memory in place.
		return remember(k)
	end
	if ok then
		local cloud = fromRaw(raw)
		local current = memory[k]
		if current ~= nil then
			mergeInto(current, cloud)
		else
			current = cloud
			memory[k] = cloud
		end
		cloudEpoch[k] = epochAtStart + 1
		cloudBlocked[k] = nil
		return current
	end

	cloudBlocked[k] = true
	return remember(k)
end

function MetaStore.save(userId: number, data: Save)
	local k = keyFor(userId)
	memory[k] = data
	if cloudBlocked[k] then
		return
	end
	local ds = tryStore()
	if ds == nil then
		return
	end
	pcall(function()
		ds:SetAsync(k, data)
	end)
end

function MetaStore.toJson(data: Save): string
	return HttpService:JSONEncode(data)
end

function MetaStore.recordEnding(data: Save, endingId: string, at: number)
	local existing = data.endings[endingId]
	if existing ~= nil then
		existing.count += 1
	else
		data.endings[endingId] = { count = 1, discoveredAt = at }
	end
end

function MetaStore.mergeTapes(data: Save, tapes: { TapeEntry }, maxKeep: number)
	local seen: { [string]: boolean } = {}
	for _, t in data.tapes do
		seen[t.signalId] = true
	end
	for _, t in tapes do
		if not seen[t.signalId] then
			table.insert(data.tapes, t)
			seen[t.signalId] = true
		end
	end
	while #data.tapes > maxKeep do
		table.remove(data.tapes, 1)
	end
end

function MetaStore.mergeAlbum(data: Save, photos: { PhotoEntry }, maxKeep: number)
	for _, p in photos do
		table.insert(data.album, p)
	end
	while #data.album > maxKeep do
		table.remove(data.album, 1)
	end
end

return MetaStore
