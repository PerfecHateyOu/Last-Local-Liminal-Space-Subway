--!strict
-- Safe Haven helpers from gameState.executeSafeHaven / giveRecorder.
-- Unlocks HasRecorder for the EVP UI (PR8) and restores sanity.

local Haven = {}

-- Relative to haven phase start (doors already open, player stepped off).
Haven.MOM_STAND_AT = 0.8
Haven.DAD_STOPS_AT = 3.5
Haven.RECORDER_AT = 6.4
Haven.SANITY_AT = 10.4
Haven.BOARD_AT = 10.4
Haven.DEPART_AT = 11.4

-- Seconds before stretch end for Mom's "stretch our legs" cue (calm tier).
Haven.APPROACH_LEAD = 6.5

-- Train handoff if the player refused the platform (web startSegment).
Haven.TRAIN_HANDOFF_AT = 6.0

function Haven.shouldTrainHandoff(hasRecorder: boolean, stop: number, b: boolean): boolean
	if hasRecorder then
		return false
	end
	return stop > 6 or (stop == 6 and b)
end

function Haven.restoreSanity(current: number, amount: number, minValue: number, maxValue: number): number
	return math.clamp(current + amount, minValue, maxValue)
end

return Haven
