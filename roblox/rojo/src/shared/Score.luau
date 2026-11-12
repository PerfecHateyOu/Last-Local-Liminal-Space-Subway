--!strict
-- Per-stop suspicion. The server decides the result. The number stays in
-- range. Reaching 100 does not end the ride.

local Score = {}

-- correct: the flag hit an anomaly. anomalyLive: a tell or the poster is
-- up right now. A correct flag lowers suspicion. A flag while nothing is
-- up is a false alarm. Flagging the wrong body while something is up
-- changes nothing.
function Score.flagDelta(correct: boolean, anomalyLive: boolean, falseAmount: number, correctAmount: number): number
	if correct then
		return -correctAmount
	end
	if not anomalyLive then
		return falseAmount
	end
	return 0
end

-- One result. A catch wins. A false alarm wins over a miss. A miss does
-- not outrank a clean stop that had no anomaly.
function Score.result(hadAnomaly: boolean, noticed: boolean, falseAlarm: boolean): string
	if noticed then
		return "noticed"
	end
	if falseAlarm then
		return "false"
	end
	if hadAnomaly then
		return "missed"
	end
	return "clean"
end

-- Clean pays the clean bonus and the no-incident decay. A miss pays only
-- the decay. It does not go up. Noticed and false alarm were already
-- applied when the flag happened.
function Score.endDelta(kind: string, cleanAmount: number, decayAmount: number): number
	if kind == "clean" then
		return -(cleanAmount + decayAmount)
	end
	if kind == "missed" then
		return -decayAmount
	end
	return 0
end

-- Standing at the doors, moving to them, or staring on a false stop.
-- Nothing in this slice can see that, so the ride passes false.
function Score.falseStopDelta(reacted: boolean, amount: number): number
	if reacted then
		return amount
	end
	return 0
end

function Score.apply(current: number, delta: number, least: number, most: number): number
	return math.clamp(current + delta, least, most)
end

return Score
