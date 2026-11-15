--!strict
-- Career achievements from src/game/achievements.ts.
-- Persistence lives in MetaStore; this module is defs + unlock helpers.

local Achievements = {}

export type AchievementId =
	"first_anomaly"
	| "photo_evidence"
	| "tuning_pro"
	| "broadcaster_lore"
	| "iron_composure"
	| "trestle_cross"
	| "loop_breaker"
	| "master_archivist"

export type AchievementDef = {
	id: AchievementId,
	title: string,
	category: string,
	description: string,
	badge: string,
	secret: boolean?,
}

export type UnlockedMap = { [string]: { unlockedAt: number } }

local DEFS: { [AchievementId]: AchievementDef } = {
	first_anomaly = {
		id = "first_anomaly",
		title = "First Contact",
		category = "observation",
		description = "Catch your first anomaly with a flag or Polaroid photo.",
		badge = "FLAG",
	},
	photo_evidence = {
		id = "photo_evidence",
		title = "Silver Halide Evidence",
		category = "observation",
		description = "Successfully photograph an active car anomaly with the Polaroid 600.",
		badge = "PHOTO",
	},
	tuning_pro = {
		id = "tuning_pro",
		title = "Signal Hunter",
		category = "signals",
		description = "Record at least 3 distinct radio signals on the microcassette recorder.",
		badge = "EVP",
	},
	broadcaster_lore = {
		id = "broadcaster_lore",
		title = "Phantom Broadcaster",
		category = "signals",
		description = "Discover and record a secret station broadcaster frequency.",
		badge = "RADIO",
	},
	iron_composure = {
		id = "iron_composure",
		title = "The Unbroken Mask",
		category = "composure",
		description = "Complete a full ride with 0 peak suspicion from your parents.",
		badge = "MASK",
		secret = true,
	},
	trestle_cross = {
		id = "trestle_cross",
		title = "Night Watch",
		category = "survival",
		description = "Witness the Newtown Creek trestle crossing into the night sky.",
		badge = "VISTA",
	},
	loop_breaker = {
		id = "loop_breaker",
		title = "Loop Breaker",
		category = "survival",
		description = "Unlock any alternative escape ending beyond standard Civilian Extraction.",
		badge = "ESCAPE",
	},
	master_archivist = {
		id = "master_archivist",
		title = "Chief Archivist",
		category = "observation",
		description = "Catalog at least 6 distinct anomaly types across rides.",
		badge = "DOSSIER",
	},
}

Achievements.DEFS = DEFS
Achievements.IDS = {
	"first_anomaly",
	"photo_evidence",
	"tuning_pro",
	"broadcaster_lore",
	"iron_composure",
	"trestle_cross",
	"loop_breaker",
	"master_archivist",
} :: { AchievementId }

function Achievements.definition(id: AchievementId): AchievementDef
	return DEFS[id]
end

function Achievements.has(map: UnlockedMap, id: string): boolean
	return map[id] ~= nil
end

-- Returns true when newly unlocked.
function Achievements.unlock(map: UnlockedMap, id: AchievementId, at: number, offRecord: boolean): boolean
	if offRecord then
		return false
	end
	if map[id] ~= nil then
		return false
	end
	map[id] = { unlockedAt = at }
	return true
end

function Achievements.count(map: UnlockedMap): number
	local n = 0
	for _ in map do
		n += 1
	end
	return n
end

return Achievements
