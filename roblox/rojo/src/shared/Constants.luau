--!strict
-- Tuning copied from the web game (src/constants.ts, src/game/gameState.ts,
-- src/game/personKeepOut.ts). Distances in the tables stay in metres; the car
-- builder multiplies by STUDS_PER_METER.

local Constants = {}

-- A default Roblox character is about 5 studs tall. 3 studs per metre makes a
-- 1.7 m rider about 5.1 studs, so the imported people and the player match.
Constants.STUDS_PER_METER = 3

-- personKeepOut.ts: eye to the standing passenger's centre.
Constants.KEEP_OUT_METERS = 0.75

-- Default HumanoidRootPart is 2 studs wide. The solid keep-out cylinder is
-- this much smaller than 0.75 m so the root's centre, not its skin, stops at
-- the radius.
Constants.ROOT_HALF_WIDTH_STUDS = 1

-- gameState.ts walking speed (m/s) and the eye height the web camera uses.
Constants.WALK_SPEED_MPS = 2.4
Constants.EYE_HEIGHT_M = 1.18

-- constants.ts CFG.flagHold. How long Flag must be held on one person.
Constants.FLAG_HOLD = 0.7

-- Web timings, in seconds: TA = 5, TD = 6, default cruise 26.
-- NEXT_STOP_PA_AT = 7, NEXT_STOP_PA_S = 4.5.
-- This slice shortens accel, cruise and brake so a playtest can hear every
-- stop. The "next stop" line still starts 7 seconds into the stretch.
Constants.ACCEL = 3
Constants.BRAKE = 3
Constants.CRUISE = 12
Constants.NEXT_STOP_AT = 7
Constants.NEXT_STOP_FOR = 4.5

-- arrive(): flickerUntil = GT + 0.16. Whole-car blackout, flicker tick only.
Constants.FLICKER_TICK_SECONDS = 0.16

-- Far door leaves slide this many metres when doorOpen goes from 0 to 1.
Constants.DOOR_SLIDE_M = 0.62

-- Final stretch only. Linear, from full to this fraction. Not a flicker.
Constants.FINAL_DIM = 0.62

-- Published MeshPart budget. The importer's hard ceiling is about 21,000.
-- https://create.roblox.com/docs/art/modeling/specifications
Constants.MESH_TRIANGLE_LIMIT = 20000

-- How far a flag ray reaches, in metres. Long enough to cover one car.
Constants.FLAG_RANGE_M = 20

-- constants.ts V. Cruise speed in metres per second. The slice's accel, cruise
-- and brake times scale the distance; they do not change this speed.
Constants.TOP_SPEED_MPS = 14

-- View motion only. The car and the player do not move with the train.
-- Peak bob is 2.2 cm and roll stays under 1 degree, times speed/top speed,
-- so a stop is still and cruise stays inside comfort limits.
Constants.BOB_Y_M = 0.022
Constants.BOB_X_M = 0.01
Constants.ROLL_DEG = 0.7
Constants.PITCH_DEG = 0.4

-- Web point light: 0xfff0d4, intensity 0.55, distance 9.5 m, decay 1.6
-- (subwayCarBuilder.setupLighting, gameState.applyLighting). Roblox's light
-- units are hotter, and 9.5 m of range washed the whole car in the playtest.
-- The shorter range is the decay: a pool under each lamp, ends in shadow.
Constants.LAMP_BRIGHTNESS = 0.48
Constants.LAMP_RANGE_M = 4.2

Constants.COLOR = {
	-- Web wall 0xc9ccc4, ceiling 0xe6e4db. Those hexes are the paint under
	-- three.js Lambert. On Roblox SmoothPlastic they read as white, so the
	-- value is pulled down and the hue is kept (sage gray, warm ceiling).
	wall = Color3.fromRGB(86, 90, 82),
	lowWall = Color3.fromRGB(62, 66, 62),
	seatOrange = Color3.fromRGB(176, 90, 28),
	seatYellow = Color3.fromRGB(184, 122, 38),
	underSeat = Color3.fromRGB(42, 44, 46),
	door = Color3.fromRGB(96, 100, 96),
	steel = Color3.fromRGB(118, 120, 122),
	ceiling = Color3.fromRGB(78, 76, 68),
	floor = Color3.fromRGB(32, 32, 30),
	glass = Color3.fromRGB(70, 92, 86),
	dark = Color3.fromRGB(6, 8, 9),
	-- Tube body. Not 0xfff4de: Neon at that hex is a white bar. The point
	-- light carries 0xfff0d4; the strip is the dimmer fixture around it.
	lightOn = Color3.fromRGB(150, 128, 88),
	lightOff = Color3.fromRGB(12, 10, 8),
	lamp = Color3.fromRGB(255, 240, 212),
	gLine = Color3.fromRGB(108, 190, 69),
	warn = Color3.fromRGB(227, 168, 58),
	cream = Color3.fromRGB(243, 239, 226),
	ink = Color3.fromRGB(12, 10, 8),
	paBg = Color3.fromRGB(18, 13, 5),
}

function Constants.meters(metres: number): number
	return metres * Constants.STUDS_PER_METER
end

return Constants
