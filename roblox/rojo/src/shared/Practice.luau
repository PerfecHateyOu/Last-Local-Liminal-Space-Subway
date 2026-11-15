--!strict
-- Practice / chapter-select helpers from src/game/practice.ts.
-- Chapter II/III starts are off-record: no endings, badges, or DataStore writes.

local Practice = {}

-- 1-based index into Route.SEGMENTS (web CHAPTER_START_SEGMENT is 0-based into SEGS).
-- Ch I: whole ride from Hoyt. Ch II: into Safe Haven. Ch III: Greenpoint restraint.
Practice.CHAPTER_START_INDEX = {
	[1] = 1,
	[2] = 5,
	[3] = 11,
}

function Practice.normalizeChapter(chapter: number): number
	if chapter == 2 or chapter == 3 then
		return chapter
	end
	return 1
end

function Practice.startIndex(chapter: number): number
	local ch = Practice.normalizeChapter(chapter)
	return Practice.CHAPTER_START_INDEX[ch] or 1
end

function Practice.isPractice(chapter: number): boolean
	return Practice.normalizeChapter(chapter) > 1
end

function Practice.offRecord(practiceOn: boolean, debugRun: boolean): boolean
	return practiceOn or debugRun
end

return Practice
