--!strict
-- Tape recorder / EVP from src/game/evpManager.ts.
-- Frequencies shuffle per ride; meter treats signals and decoys the same.
-- Case Files archive persistence stays out.

local Evp = {}

Evp.MIN_KHZ = 70
Evp.MAX_KHZ = 180
Evp.LOCK_KHZ = 1.0
Evp.METER_WIDTH = 4
Evp.RECORD_HOLD = 1.5
Evp.REVEAL_SECONDS = 3
Evp.DECOYS_PER_SEGMENT = 2
Evp.SIGNAL_GAP = 8
Evp.DECOY_GAP = 5
Evp.TAPE_GLANCE_CHANCE = 0.5

export type SignalDef = {
	id: string,
	title: string,
	stops: { number },
	transcript: string,
}

export type Carrier = {
	kind: "signal" | "decoy",
	khz: number,
	signalId: string?,
}

export type Tape = {
	signalId: string,
	title: string,
	stop: string,
	freq: string,
	transcript: string,
}

export type State = {
	raised: boolean,
	recording: boolean,
	khz: number,
	meter: number,
	lockedKind: string, -- "" | "signal" | "decoy"
	lockedId: string,
	reveal: number,
	recordT: number,
	tapes: { Tape },
	signalKhz: { [string]: number },
	decoyKhz: { [number]: { number } },
	heard: { [string]: number },
}

-- G-route copy with tokens already filled (fillRoute for the G).
local SIGNALS: { SignalDef } = {
	{
		id = "dispatch-hold",
		title = "Dispatch, track 2",
		stops = { 6, 7 },
		transcript = "…G four-forty, hold at Nassau. Hold. Do not open the doors at Nassau…",
	},
	{
		id = "passenger-hoyt",
		title = "A passenger",
		stops = { 7, 8, 9 },
		transcript = "…I got on at Hoyt too. I always get on at Hoyt. I always get on at Hoyt…",
	},
	{
		id = "dispatch-empty",
		title = "Dispatch, no train number",
		stops = { 9, 10 },
		transcript = "…there is no train scheduled on this track. Repeat: nothing is scheduled on this track…",
	},
	{
		id = "passenger-greenpoint",
		title = "Someone at the far end",
		stops = { 10, 11 },
		transcript = "…first time? It gets easier after Greenpoint. Don’t let them see you looking…",
	},
	{
		id = "warning-time",
		title = "Static, then a time",
		stops = { 11, 12 },
		transcript = "…6:52… 6:52 a.m.… it was 6:52 the last time, too…",
	},
	{
		id = "conductor",
		title = "The conductor",
		stops = { 12, 13 },
		transcript = "…this is your conductor. We are above ground. This train does not go above ground…",
	},
	{
		id = "mom-voice",
		title = "A voice like Mom’s",
		stops = { 12, 13 },
		transcript = "…honey, don’t look at the window. Look at me. Look at me…",
	},
	{
		id = "station-bedford",
		title = "Bedford–Nostrand dispatch static",
		stops = { 6, 7 },
		transcript = "…Dispatch 44 to all units on G… relay failure at Bedford–Nostrand. Unauthorized personnel on track bed… repeat: do not look at track bed…",
	},
	{
		id = "station-classon",
		title = "Classon Av phantom PA echo",
		stops = { 6, 7, 8 },
		transcript = "…Please stand clear of the closing doors… the train following this one does not exist… return to your seat immediately…",
	},
	{
		id = "station-flushing",
		title = "Flushing Av night wiretap",
		stops = { 7, 8, 9 },
		transcript = "…Station log 02:14. Platform empty, but footsteps continue down the south stairs. Someone is whistling the wrong chime…",
	},
	{
		id = "station-newtown",
		title = "Newtown Creek emergency channel",
		stops = { 10, 11, 12 },
		transcript = "…Maritime security channel 16. Bridge clearance confirmed. Unscheduled train visible on upper trestle. Who authorized that train…",
	},
}

Evp.SIGNALS = SIGNALS

function Evp.signalById(id: string): SignalDef?
	for _, sig in SIGNALS do
		if sig.id == id then
			return sig
		end
	end
	return nil
end

local function share(a: SignalDef, b: SignalDef): boolean
	for _, stop in a.stops do
		for _, other in b.stops do
			if stop == other then
				return true
			end
		end
	end
	return false
end

function Evp.newState(rng: () -> number): State
	local state: State = {
		raised = false,
		recording = false,
		khz = 120,
		meter = 0,
		lockedKind = "",
		lockedId = "",
		reveal = 0,
		recordT = 0,
		tapes = {},
		signalKhz = {},
		decoyKhz = {},
		heard = {},
	}

	local function rnd(): number
		return math.round((Evp.MIN_KHZ + 4 + rng() * (Evp.MAX_KHZ - Evp.MIN_KHZ - 8)) * 10) / 10
	end

	local function pick(minGap: number, against: { number }): number?
		for _ = 1, 300 do
			local f = rnd()
			local ok = true
			for _, o in against do
				if math.abs(o - f) < minGap then
					ok = false
					break
				end
			end
			if ok then
				return f
			end
		end
		return nil
	end

	local function layout(): boolean
		state.signalKhz = {}
		local order = table.clone(SIGNALS)
		table.sort(order, function(a, b)
			local ca, cb = 0, 0
			for _, x in SIGNALS do
				if share(x, a) then
					ca += 1
				end
				if share(x, b) then
					cb += 1
				end
			end
			return cb < ca
		end)
		for _, sig in order do
			local against = {}
			for _, o in order do
				if o ~= sig and state.signalKhz[o.id] ~= nil and share(o, sig) then
					table.insert(against, state.signalKhz[o.id])
				end
			end
			local f = pick(Evp.SIGNAL_GAP, against)
			if f == nil then
				return false
			end
			state.signalKhz[sig.id] = f
		end
		state.decoyKhz = {}
		for stop = 6, 13 do
			local near = {}
			for _, sig in SIGNALS do
				for _, s in sig.stops do
					if s == stop then
						table.insert(near, state.signalKhz[sig.id])
						break
					end
				end
			end
			local ds = {}
			for _ = 1, Evp.DECOYS_PER_SEGMENT do
				local against = table.clone(near)
				for _, d in ds do
					table.insert(against, d)
				end
				local f = pick(Evp.DECOY_GAP, against)
				if f == nil then
					return false
				end
				table.insert(ds, f)
			end
			state.decoyKhz[stop] = ds
		end
		return true
	end

	for _ = 1, 50 do
		if layout() then
			break
		end
	end
	return state
end

function Evp.carriers(state: State, stop: number?): { Carrier }
	if stop == nil then
		return {}
	end
	local out: { Carrier } = {}
	for _, sig in SIGNALS do
		for _, s in sig.stops do
			if s == stop then
				table.insert(out, {
					kind = "signal",
					khz = state.signalKhz[sig.id] or 0,
					signalId = sig.id,
				})
				break
			end
		end
	end
	for _, f in state.decoyKhz[stop] or {} do
		table.insert(out, { kind = "decoy", khz = f, signalId = nil })
	end
	return out
end

function Evp.setKhz(state: State, khz: number)
	local v = math.round(khz * 10) / 10
	state.khz = math.clamp(v, Evp.MIN_KHZ, Evp.MAX_KHZ)
end

function Evp.tune(state: State, delta: number)
	Evp.setKhz(state, state.khz + delta)
end

function Evp.raise(state: State): boolean
	if state.raised then
		return false
	end
	state.raised = true
	return true
end

function Evp.lower(state: State)
	state.raised = false
	state.recording = false
	state.recordT = 0
	state.lockedKind = ""
	state.lockedId = ""
	state.meter = 0
	state.reveal = 0
end

function Evp.setRecording(state: State, on: boolean)
	local nextOn = on and state.raised
	if nextOn == state.recording then
		return
	end
	state.recording = nextOn
	if not nextOn then
		state.recordT = 0
	end
end

function Evp.hasTape(state: State, signalId: string): boolean
	for _, tape in state.tapes do
		if tape.signalId == signalId then
			return true
		end
	end
	return false
end

-- Returns a new tape when one is saved this frame; otherwise nil.
function Evp.update(state: State, dt: number, stop: number?, stopLabel: string): Tape?
	if not state.raised then
		state.meter = 0
		state.lockedKind = ""
		state.lockedId = ""
		state.reveal = 0
		return nil
	end
	local cs = Evp.carriers(state, stop)
	local best: Carrier? = nil
	local bestD = math.huge
	for _, c in cs do
		local d = math.abs(c.khz - state.khz)
		if d < bestD then
			bestD = d
			best = c
		end
	end
	state.meter = if best then math.exp(-((bestD / Evp.METER_WIDTH) ^ 2)) else 0
	if best and bestD <= Evp.LOCK_KHZ then
		state.lockedKind = best.kind
		state.lockedId = best.signalId or ""
	else
		state.lockedKind = ""
		state.lockedId = ""
	end

	local sig = if state.lockedKind == "signal" then Evp.signalById(state.lockedId) else nil
	if sig ~= nil then
		state.heard[sig.id] = math.min(1, (state.heard[sig.id] or 0) + dt / Evp.REVEAL_SECONDS)
		state.reveal = state.heard[sig.id]
	else
		state.reveal = 0
	end

	if state.recording and sig ~= nil and not Evp.hasTape(state, sig.id) then
		state.recordT += dt
		if state.recordT >= Evp.RECORD_HOLD then
			state.recordT = 0
			local tape: Tape = {
				signalId = sig.id,
				title = sig.title,
				stop = stopLabel,
				freq = string.format("%.1f kHz", state.khz),
				transcript = sig.transcript,
			}
			table.insert(state.tapes, tape)
			return tape
		end
	else
		state.recordT = 0
	end
	return nil
end

function Evp.tapesJson(state: State): string
	-- Compact hand-rolled JSON for the HUD (no HttpService dependency in specs).
	local parts = {}
	for _, tape in state.tapes do
		local entry = string.format(
			'{"signalId":%q,"title":%q,"stop":%q,"freq":%q,"transcript":%q}',
			tape.signalId,
			tape.title,
			tape.stop,
			tape.freq,
			tape.transcript
		)
		table.insert(parts, entry)
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

function Evp.statusLine(state: State, riding: boolean): string
	if state.lockedKind == "signal" then
		local sig = Evp.signalById(state.lockedId)
		if sig ~= nil then
			local n = math.max(1, math.round(#sig.transcript * state.reveal))
			return string.sub(sig.transcript, 1, n)
		end
	end
	if state.lockedKind == "decoy" then
		return "— a carrier tone, no voice —"
	end
	if state.recording then
		return "Recording hiss…"
	end
	if riding then
		return "Tune slowly. Something is out there."
	end
	return "Nothing comes through at a standstill."
end

return Evp
