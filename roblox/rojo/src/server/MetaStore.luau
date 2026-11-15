--!strict
-- Player meta progression: endings archive, achievements, tapes, album, run count.
-- Uses DataStore when available; falls back to an in-memory table (Studio / offline).
-- Failed GetAsync never seeds an empty save that later SetAsync could clobber cloud data.
-- Once a key is live in memory for this session, load returns that copy (no delayed overwrite).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

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
-- Keys where GetAsync failed: memory is session-only; skip SetAsync to avoid wiping cloud.
local cloudBlocked: { [string]: boolean } = {}
local store: GlobalDataStore? = nil

local function tryStore(): GlobalDataStore?
	if store ~= nil then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("LastLocalMeta_v1")
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

function MetaStore.load(userId: number): Save
	local k = keyFor(userId)
	-- Session copy wins: avoids a late GetAsync overwriting in-memory progress.
	local existing = memory[k]
	if existing ~= nil then
		return existing
	end
	local ds = tryStore()
	if ds ~= nil then
		local ok, raw = pcall(function()
			return ds:GetAsync(k)
		end)
		if ok then
			cloudBlocked[k] = nil
			-- nil raw = first-time player; empty save is safe to persist later.
			local s = fromRaw(raw)
			memory[k] = s
			return s
		end
		-- Read failed: session empty only; do not SetAsync until a later load succeeds.
		cloudBlocked[k] = true
		local s = MetaStore.empty()
		memory[k] = s
		return s
	end
	local s = MetaStore.empty()
	memory[k] = s
	return s
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
