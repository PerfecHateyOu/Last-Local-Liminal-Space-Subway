--!strict
-- Stay / step-off outcomes. Mirrors web resolveDoors (gameState.ts).
-- Haven cinematic and the False Stop Trial are stubs until later PRs.

local Doors = {}

export type Choice = "stay" | "off"
export type StopKind = "real" | "false" | "haven"

export type Outcome = {
	choice: Choice,
	correct: boolean,
	suspicionDelta: number,
	-- "depart" continues the ride. Stubs still depart after a beat.
	mode: "depart" | "haven_stub" | "trial_stub",
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
	lineHavenStub: string,
	lineTrialStub: string
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
			-- Full Safe Haven is PR6. Step off, subtitle, get back on.
			return {
				choice = choice,
				correct = true,
				suspicionDelta = 0,
				mode = "haven_stub",
				line = lineHavenStub,
				holdSeconds = 3.4,
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
	-- Non-forgiving: trial is PR7. Soft-fail — pull back + suspicion.
	return {
		choice = choice,
		correct = false,
		suspicionDelta = amounts.falseOff,
		mode = "trial_stub",
		line = lineTrialStub,
		holdSeconds = 3.8,
	}
end

return Doors
