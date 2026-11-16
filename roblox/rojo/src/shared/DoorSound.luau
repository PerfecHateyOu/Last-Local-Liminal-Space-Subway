--!strict
-- Door clip windows for the sound bed (client Audio plays the regions).
-- Verified Studio scene rbxassetid://9117093785 (~8.15s): open 0–4.45,
-- close 4.45–end. Short latch clips (< SCENE_MIN) play start→end on either edge.

local Constants = require(script.Parent.Constants)

local DoorSound = {}

-- (startTime, endTime) in seconds on the asset timeline.
function DoorSound.edgeWindow(length: number, opening: boolean): (number, number)
	if length <= 0 then
		return 0, 0
	end
	if length < Constants.SOUND_DOOR_SCENE_MIN_LENGTH then
		return 0, length
	end
	local split = math.min(Constants.SOUND_DOOR_OPEN_END, length)
	if opening then
		return 0, split
	end
	return split, length
end

-- EVP raise click: attack slice only (0.75–1.10 on the long scene).
function DoorSound.evpAttackWindow(length: number): (number, number)
	if length <= 0 then
		return 0, 0
	end
	local startAt = math.min(Constants.SOUND_DOOR_EVP_START, length)
	local endAt = math.min(Constants.SOUND_DOOR_EVP_END, length)
	if endAt <= startAt then
		return 0, length
	end
	return startAt, endAt
end

return DoorSound
