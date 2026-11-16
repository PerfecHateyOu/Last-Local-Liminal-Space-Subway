--!strict
-- Mesh and sound asset wiring for the Studio place.
--
-- Meshes: CarBuilder clones Models under ReplicatedStorage.Models (FBX
-- imports). A missing model uses Part figures — that is intentional, not an
-- error. See README "Put your characters in the car".
--
-- Sounds: classic rbxasset://sounds/* paths are often rejected as unapproved
-- and spam Output. Defaults are empty (silent). After you upload audio (or
-- pick Creator Store clips you may use), put rbxassetid://… values in
-- ReplicatedStorage.Assets StringValues named below. Do not invent private
-- asset IDs in source.

local Assets = {}

export type SoundKey = "chime" | "door" | "clack" | "rumble" | "openAir" | "polaroid"

-- Folder child names under ReplicatedStorage.Assets (StringValue.Value).
Assets.SOUND_VALUE_NAMES = {
	chime = "Chime",
	door = "Door",
	clack = "Clack",
	rumble = "Rumble",
	openAir = "OpenAir",
	polaroid = "Polaroid",
}

-- Ordered for one-line status logs.
Assets.SOUND_ORDER = { "chime", "door", "clack", "rumble", "openAir", "polaroid" } :: { SoundKey }

-- Verified public NYC subway door scene (~8.15s). Paste into place
-- ReplicatedStorage.Assets.Door when you want open/close scenes. Not a
-- silent-override fallback: empty Door stays silent (no invented private IDs).
Assets.RECOMMENDED_DOOR_ID = "rbxassetid://9117093785"

-- Strip whitespace; accept bare digits as rbxassetid://N; reject classic
-- rbxasset://sounds/* paths that Roblox often blocks for experiences.
function Assets.normalizeSoundId(raw: string?): string
	if raw == nil then
		return ""
	end
	local trimmed = string.gsub(raw, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")
	if trimmed == "" then
		return ""
	end
	local lower = string.lower(trimmed)
	if string.find(lower, "^rbxasset://sounds/") ~= nil then
		return ""
	end
	if string.match(trimmed, "^%d+$") ~= nil then
		return "rbxassetid://" .. trimmed
	end
	return trimmed
end

function Assets.isSoundIdReady(id: string): boolean
	return Assets.normalizeSoundId(id) ~= ""
end

local function readStringValue(folder: Instance?, name: string): string?
	if folder == nil then
		return nil
	end
	local child = folder:FindFirstChild(name)
	if child == nil then
		return nil
	end
	if child:IsA("StringValue") then
		return child.Value
	end
	local attr = folder:GetAttribute(name)
	if typeof(attr) == "string" then
		return attr
	end
	return nil
end

-- Place overrides live under ReplicatedStorage.Assets (created empty by Rojo;
-- Studio fills StringValues). Missing folder / empty values → silent.
function Assets.placeFolder(): Folder?
	local ok, replicated = pcall(function()
		return game:GetService("ReplicatedStorage")
	end)
	if not ok or replicated == nil then
		return nil
	end
	local rs = replicated :: any
	local folder = rs:FindFirstChild("Assets")
	if folder ~= nil and folder:IsA("Folder") then
		return folder
	end
	return nil
end

function Assets.soundId(key: SoundKey): string
	local name = Assets.SOUND_VALUE_NAMES[key]
	local fromPlace = readStringValue(Assets.placeFolder(), name)
	return Assets.normalizeSoundId(fromPlace)
end

function Assets.soundStatus(): (number, number, { string })
	local ready = 0
	local missing: { string } = {}
	for _, key in Assets.SOUND_ORDER do
		local id = Assets.soundId(key)
		if id ~= "" then
			ready += 1
		else
			table.insert(missing, Assets.SOUND_VALUE_NAMES[key])
		end
	end
	return ready, #Assets.SOUND_ORDER, missing
end

-- Mid-car riders CarBuilder always tries (modelName / NPC aliases).
Assets.CORE_MODEL_HINTS = {
	"mom / NPC_mom_seated",
	"dad / NPC_dad_seated",
	"passenger_mta / NPC_mta_seated",
	"passenger_coat / NPC_coat_seated",
	"passenger_puffer / NPC_puffer",
	"anomaly_extra",
	"Car_B (optional interior)",
}

return Assets
