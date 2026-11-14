--!strict
-- Stay / step-off outcomes. Mirrors web resolveDoors (gameState.ts).
-- Haven runs Shared.Haven + Ride.executeHaven.
-- Non-forgiving false step-off runs Shared.Trial + TrialSpace.

local Doors = {}

export type Choice = "stay" | "off"
export type StopKind = "real" | "false" | "haven"

export type Outcome = {
	choice: Choice,
	correct: boolean,
	suspicionDelta: number,
	-- "depart" continues the ride. "haven" runs the platform linger.
	-- "trial" runs the False Stop Trial room.
	mode: "depart" | "haven" | "trial",
	line: string,
	holdSeconds: number,
}

export type Amounts = {
	realOff: number,
	refuseHaven: number,
	falseOff: number,
}

function Doors.normalize(choice: string?): Choice
	if choice == "off" then
		return "off"
	end
	return "stay"
end

-- kind/forgiving come from Route. line* are the spoken/subtitle strings.
function Doors.resolve(
	kind: StopKind,
	forgiving: boolean,
	rawChoice: string?,
	amounts: Amounts,
	lineRealOff: string,
	lineRefuseHaven: string,
	lineFalseForgiving: string,
	_lineHavenUnused: string,
	_lineTrialUnused: string
): Outcome
	local choice = Doors.normalize(rawChoice)
	if kind == "real" then
		if choice == "off" then
			return {
				choice = choice,
				correct = false,
				suspicionDelta = amounts.realOff,
				mode = "depart",
				line = lineRealOff,
				holdSeconds = 3.2,
			}
		end
		return {
			choice = choice,
			correct = true,
			suspicionDelta = 0,
			mode = "depart",
			line = "",
			holdSeconds = 0,
		}
	end
	if kind == "haven" then
		if choice == "off" then
			-- Ride runs the Safe Haven linger; holdSeconds stays 0 here.
			return {
				choice = choice,
				correct = true,
				suspicionDelta = 0,
				mode = "haven",
				line = "",
				holdSeconds = 0,
			}
		end
		return {
			choice = choice,
			correct = false,
			suspicionDelta = amounts.refuseHaven,
			mode = "depart",
			line = lineRefuseHaven,
			holdSeconds = 3.2,
		}
	end
	-- False stop.
	if choice == "stay" then
		return {
			choice = choice,
			correct = true,
			suspicionDelta = 0,
			mode = "depart",
			line = "",
			holdSeconds = 0,
		}
	end
	if forgiving then
		return {
			choice = choice,
			correct = false,
			suspicionDelta = amounts.falseOff,
			mode = "depart",
			line = lineFalseForgiving,
			holdSeconds = 3.8,
		}
	end
	-- Non-forgiving: enter the False Stop Trial. Suspicion applies on exit.
	return {
		choice = choice,
		correct = false,
		suspicionDelta = 0,
		mode = "trial",
		line = "",
		holdSeconds = 0,
	}
end

return Doors
