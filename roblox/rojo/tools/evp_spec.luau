--!strict
-- EVP helpers. Run: luau tools/evp_spec.luau

local Evp = require("../src/shared/Evp")

local failures = 0
local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

local seq = 0.2
local function rng()
	seq += 0.13
	if seq > 1 then
		seq -= 1
	end
	return seq
end

local state = Evp.newState(rng)
check("layout assigned signals", next(state.signalKhz) ~= nil)
check("decoys for stop 7", state.decoyKhz[7] ~= nil and #state.decoyKhz[7] == 2)

local carriers = Evp.carriers(state, 7)
check("carriers at 7", #carriers >= 3)

Evp.raise(state)
check("raised", state.raised == true)

-- Lock onto a known signal frequency.
local sigId = "passenger-hoyt"
local khz = state.signalKhz[sigId]
check("hoyt freq", typeof(khz) == "number")
Evp.setKhz(state, khz)
local tape = nil
for _ = 1, 40 do
	tape = Evp.update(state, 0.1, 7, "Flushing Av")
end
check("locked signal", state.lockedKind == "signal" and state.lockedId == sigId)
check("reveal progresses", state.reveal > 0)

Evp.setRecording(state, true)
tape = nil
for _ = 1, 20 do
	tape = Evp.update(state, 0.1, 7, "Flushing Av")
	if tape ~= nil then
		break
	end
end
check("tape saved", tape ~= nil and Evp.hasTape(state, sigId))
check("json non-empty", string.find(Evp.tapesJson(state), sigId, 1, true) ~= nil)

-- Decoy lock has no voice.
Evp.lower(state)
Evp.raise(state)
local decoy = state.decoyKhz[7][1]
Evp.setKhz(state, decoy)
Evp.update(state, 0.05, 7, "Flushing Av")
check("decoy lock", state.lockedKind == "decoy")
check("decoy status", Evp.statusLine(state, true) == "— a carrier tone, no voice —")

-- Standstill: no carriers.
Evp.update(state, 0.05, nil, "")
check("standstill clears lock", state.lockedKind == "" and state.meter == 0)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("evp spec ok")
