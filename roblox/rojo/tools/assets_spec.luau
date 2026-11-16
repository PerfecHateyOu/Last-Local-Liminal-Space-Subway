--!strict
-- Sound ID normalization and place-folder keys for Shared.Assets.
-- Run from this folder: luau tools/assets_spec.luau

local Assets = require("../src/shared/Assets")

local failures = 0

local function check(name: string, cond: boolean)
	if not cond then
		failures += 1
		print("FAIL " .. name)
	end
end

check("empty stays empty", Assets.normalizeSoundId("") == "")
check("nil stays empty", Assets.normalizeSoundId(nil) == "")
check("whitespace stays empty", Assets.normalizeSoundId("  ") == "")

check(
	"rejects classic electronicpingshort path",
	Assets.normalizeSoundId("rbxasset://sounds/electronicpingshort.wav") == ""
)
check("rejects classic swoosh path", Assets.normalizeSoundId("rbxasset://sounds/swoosh.wav") == "")
check("rejects classic switch path", Assets.normalizeSoundId("rbxasset://sounds/switch.wav") == "")
check(
	"rejects classic impact path",
	Assets.normalizeSoundId("rbxasset://sounds/impact_explosion_03.mp3") == ""
)

check("bare digits become rbxassetid", Assets.normalizeSoundId("12221990") == "rbxassetid://12221990")
check(
	"keeps rbxassetid form",
	Assets.normalizeSoundId("rbxassetid://12222170") == "rbxassetid://12222170"
)
check("trims rbxassetid", Assets.normalizeSoundId("  rbxassetid://1  ") == "rbxassetid://1")

check("ready on rbxassetid", Assets.isSoundIdReady("rbxassetid://1") == true)
check("not ready on classic path", Assets.isSoundIdReady("rbxasset://sounds/switch.wav") == false)
check("not ready on empty", Assets.isSoundIdReady("") == false)

check("Chime value name", Assets.SOUND_VALUE_NAMES.chime == "Chime")
check("Door value name", Assets.SOUND_VALUE_NAMES.door == "Door")
check("Clack value name", Assets.SOUND_VALUE_NAMES.clack == "Clack")
check("Rumble value name", Assets.SOUND_VALUE_NAMES.rumble == "Rumble")
check("OpenAir value name", Assets.SOUND_VALUE_NAMES.openAir == "OpenAir")
check("Polaroid value name", Assets.SOUND_VALUE_NAMES.polaroid == "Polaroid")
check("six sound keys", #Assets.SOUND_ORDER == 6)
check(
	"recommended Door id documented",
	Assets.RECOMMENDED_DOOR_ID == "rbxassetid://9117093785"
)
check("recommended Door is ready form", Assets.isSoundIdReady(Assets.RECOMMENDED_DOOR_ID) == true)

-- Without a DataModel Assets folder, every key is silent.
local ready, total, missing = Assets.soundStatus()
check("no place folder → 0 ready", ready == 0)
check("no place folder → total 6", total == 6)
check("no place folder → 6 missing names", #missing == 6)

if failures > 0 then
	error(tostring(failures) .. " failed")
end
print("assets spec ok")
