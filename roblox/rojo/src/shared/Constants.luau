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

-- Existing arrival hold when the PA tells a lie, measured from arrival.
-- The minimum dwell is a floor under this. It does not replace it.
Constants.PA_LIE_HOLD = 5.4

-- How long the doors stay open before the train may leave, in seconds.
-- The server waits at least this long after the doors open. The client
-- only shows the countdown. 2.6 is the gap this slice already waited
-- between the doors opening and "Stand clear".
Constants.MIN_DWELL_SECONDS = 2.6

-- Closing the doors or leaving before that dwell ends. The player is a
-- passenger and cannot depart, so the ride never adds this. The hook
-- stays. Clamped. The ride does not end.
Constants.EARLY_DEPARTURE_SUSPICION = 10
Constants.SUSPICION_MIN = 0
Constants.SUSPICION_MAX = 100

-- Flagging while no tell and no poster change is up. A correct flag lowers
-- suspicion. A clean stop and a stop with no flag each decay. A miss does
-- not raise suspicion; the decay is the only change on a quiet miss.
Constants.FALSE_ALARM_SUSPICION = 10
Constants.CORRECT_FLAG_SUSPICION = 5
Constants.CLEAN_STOP_SUSPICION = 5
Constants.DECAY_SUSPICION = 2

-- Reacting at a false stop. This slice cannot see standing, moving to the
-- doors, or staring, so the ride never adds it.
Constants.FALSE_STOP_REACT_SUSPICION = 10

-- Stay / step-off (web SUS.falsePos / refuseHaven / maskFail).
Constants.STEP_OFF_REAL_SUSPICION = 20
Constants.REFUSE_HAVEN_SUSPICION = 10
Constants.FALSE_STOP_STEP_OFF_SUSPICION = 15
-- Choice window after doors open. Timeout counts as Stay on.
Constants.DOOR_CHOICE_SECONDS = 5

-- False Stop Trial exit (web SUS.falsePos / SAN.trial).
Constants.TRIAL_EXIT_SUSPICION = 20
Constants.TRIAL_SANITY = 20
Constants.TRIAL_CYCLE = 3.6
Constants.TRIAL_FLICK_SECONDS = 0.14
Constants.TRIAL_HINT_SECONDS = 6

-- Parent chats during cruise (web CHAT_AT / CHAT_LINE_S). Slice times sit
-- after the next-stop PA (7 + 4.5) on the shortened stretch.
Constants.CHAT_AT_1 = 12.0
Constants.CHAT_AT_2 = 14.2
Constants.CHAT_LINE_SECONDS = 2.6

-- Mask checks (web MASK_CHECK_S / presentChoice). First dialogue tier only.
Constants.MASK_CHOICE_SECONDS = 4
Constants.MASK_PROMPT_SECONDS = 6
Constants.MASK_FAIL_SUSPICION = 15
Constants.MASK_TIMEOUT_SUSPICION = 8
-- Sanity is a Ride attribute stub until restraint / intervention (PR13).
-- Safe Haven restores SAN.haven (15). Mask fail/timeout still nudge it down.
Constants.SANITY_START = 100
Constants.SANITY_MIN = 0
Constants.SANITY_MAX = 100
Constants.SANITY_HAVEN = 15
Constants.MASK_FAIL_SANITY = 4
Constants.MASK_TIMEOUT_SANITY = 2
-- needsSus mask lines only appear at or above this suspicion.
Constants.MASK_NEED_SUSPICION = 10

-- Bands from the suspicion number. 0–24 calm, 25–49 uneasy, 50–74 watched,
-- 75–100 hunted.
Constants.BAND_CALM_MAX = 24
Constants.BAND_UNEASY_MAX = 49
Constants.BAND_WATCHED_MAX = 74

-- Uneasy: one tube, occasionally. Not the whole car.
Constants.UNEASY_TUBE_EVERY = 7
Constants.UNEASY_TUBE_BLINK = 0.15
Constants.BAND_STRIP_NAME = "LightStrip_06"

-- How far a head may turn, in degrees. Glance is the short look.
Constants.GLANCE_YAW_DEG = 18
Constants.TURN_YAW_DEG = 28
Constants.GLANCE_SECONDS = 0.8
Constants.GLANCE_COOLDOWN = 2.4

-- Hunted: slow dim. Above zero so the car does not go dark.
Constants.HUNTED_DIM = 0.5
Constants.HUNTED_DIM_SECONDS = 2.5

-- Watched would raise the chance of a false stop. The route is a fixed
-- table, so this number is published and not rolled.
Constants.WATCHED_FALSE_STOP_BONUS = 0.15

-- One tell per stop, by the arrival number on the segment. Other stops
-- have none. 3 is the poster. 5 is the mid-ride extra passenger. 7 is the
-- ride into Flushing Av. 10 is the ride into Nassau Av. The scripted
-- arrival lie stays on stop 9 and is not one of these.
Constants.ANOMALY_POSTER_STOP = 3
Constants.ANOMALY_EXTRA_STOP = 5
Constants.ANOMALY_ANNOUNCE_STOP = 7
Constants.ANOMALY_COUNTDOWN_STOP = 10

-- Seconds into the stretch when seat6 appears (after accel, during cruise).
-- Web waits until you look away; this slice reveals on a fixed timer.
Constants.EXTRA_APPEAR_AT = 7

-- Signed names the wrong announcement may say. 13 is Court Sq. 2 is
-- Fulton St, used only when 13 is the stop the train is actually nearing.
Constants.WRONG_ANNOUNCE_STOP = 13
Constants.WRONG_ANNOUNCE_FALLBACK_STOP = 2

-- The board's minute count. Every stretch in this slice is under a minute,
-- so the honest board reads 1. The wrong board reads 4.
Constants.COUNTDOWN_MINUTES = 1
Constants.WRONG_COUNTDOWN_MINUTES = 4

-- Held At Signal. Wall seconds into a stretch, then how long the tunnel
-- stays still. 6 is during cruise (accel is 3). The train is not at a
-- platform. Stops 8 and 11 are Broadway and Greenpoint Av.
Constants.HOLD_AT = 6
Constants.HOLD_SECONDS = 4
Constants.HOLD_STOP_A = 8
Constants.HOLD_STOP_B = 11
Constants.HOLD_EFFECT_A = "strip"
Constants.HOLD_EFFECT_B = "dim"
-- One tube. Not the whole car. The door tick still owns the blackout.
Constants.HOLD_STRIP_NAME = "LightStrip_05"
Constants.HOLD_BLINK = 0.35
-- Slow dim. Above zero so the car does not go dark.
Constants.HOLD_DIM = 0.55
Constants.HOLD_RECOVER = 1.2
-- Caught-staring is not built. While held, a future check would run this
-- many times as often. The ride only publishes the number.
Constants.HOLD_STARE_MULTIPLIER = 2
-- Existing catalog id, shown only during the Broadway hold, then cleared.
Constants.HOLD_TELL = "wrong_countdown"
Constants.HOLD_TELL_STOP = 8

-- Final stretch only. Linear, from full to this fraction. Not a flicker.
Constants.FINAL_DIM = 0.62

-- Published MeshPart budget. The importer's hard ceiling is about 21,000.
-- https://create.roblox.com/docs/art/modeling/specifications
Constants.MESH_TRIANGLE_LIMIT = 20000

-- How far a flag ray reaches, in metres. Long enough for one car of the
-- three-car consist (A / B / C) from inside that car.
Constants.FLAG_RANGE_M = 22

-- Sound bed (client). Built-in engine assets so the place needs no uploads.
-- Swap these IDs when custom MTA-style clips are imported.
Constants.SOUND_CHIME = "rbxasset://sounds/electronicpingshort.wav"
Constants.SOUND_DOOR = "rbxasset://sounds/switch.wav"
Constants.SOUND_CLACK = "rbxasset://sounds/impact_explosion_03.mp3"
Constants.SOUND_RUMBLE = "rbxasset://sounds/swoosh.wav"
Constants.SOUND_CHIME_VOLUME = 0.45
Constants.SOUND_DOOR_VOLUME = 0.35
Constants.SOUND_CLACK_VOLUME = 0.12
Constants.SOUND_RUMBLE_MIN = 0.02
Constants.SOUND_RUMBLE_MAX = 0.14
Constants.SOUND_RUMBLE_PLAYBACK = 0.35
-- Metres of travel between track clacks at top speed (client integrates speed).
Constants.CLACK_SPACING_M = 9

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
