--!strict
-- Newtown Creek trestle timing from gameState.ts (G route only).
-- Exit mouth ~25% of the way to 21 St; re-enter ~60% of the way to Court Sq.

local Trestle = {}

-- Web TRESTLE_FOG #322018 — sodium dusk haze outside (RGB for WorldLight).
Trestle.FOG_RGB = { 50, 32, 24 }
Trestle.TUNNEL_FOG_RGB = { 4, 5, 4 }
-- Tunnel fog stays near WorldLight defaults (near/far in studs at 3 studs/m).
Trestle.TUNNEL_FOG_START = 27
Trestle.TUNNEL_FOG_END = 90
-- Open air pushes fog farther (web +5 near / +55 far metres).
Trestle.OPEN_FOG_START = 27 + 5 * 3
Trestle.OPEN_FOG_END = 90 + 55 * 3

-- How many metres of odo to blend tunnel ↔ open after a mouth.
Trestle.BLEND_M = 40

export type Plan = {
	-- Odo where the train leaves the tunnel (Infinity = never this stretch).
	exitAt: number,
	-- Odo where the train re-enters (nil = not this stretch).
	enterAt: number?,
}

function Trestle.plan(stop: number, b: boolean, origin: number, segDist: number): Plan
	if stop == 12 and not b then
		return {
			exitAt = origin + 0.25 * segDist,
			enterAt = nil,
		}
	end
	if stop == 13 then
		return {
			exitAt = -math.huge,
			enterAt = origin + 0.6 * segDist,
		}
	end
	return {
		exitAt = math.huge,
		enterAt = nil,
	}
end

-- 0 = fully in tunnel, 1 = fully outside (car middle).
function Trestle.outsideLevel(odo: number, plan: Plan): number
	local exitAt = plan.exitAt
	local enterAt = plan.enterAt
	if enterAt == nil then
		if exitAt >= math.huge then
			return 0
		end
		if odo < exitAt then
			return 0
		end
		return math.clamp((odo - exitAt) / Trestle.BLEND_M, 0, 1)
	end
	-- Already outside at the start of the Court Sq stretch.
	if odo < enterAt then
		return 1
	end
	return math.clamp(1 - (odo - enterAt) / Trestle.BLEND_M, 0, 1)
end

function Trestle.show(level: number): boolean
	return level > 0.05
end

-- Arriving platform is open-air on the 21 St approach; leaving is open when
-- departing 21 St toward Court Sq.
function Trestle.arrivingOpenAir(stop: number, b: boolean): boolean
	return stop == 12 and not b
end

function Trestle.leavingOpenAir(stop: number): boolean
	return stop == 13
end

return Trestle
