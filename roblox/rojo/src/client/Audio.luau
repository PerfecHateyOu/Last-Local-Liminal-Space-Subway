--!strict
-- Minimal sound bed. Client only. Phase, stretch timing, Held, DoorTarget,
-- and PaText stay server-owned; this module listens and plays.
-- Chime before PA, rumble from stretch speed, door open/close scenes, track
-- clacks. Door uses Shared.DoorSound windows (long scene open 0–4.45 / close
-- 4.45–end; short latch full clip). Open and close are separate instances so
-- a short dwell does not cut the open scene. EVP raise uses the 0.75–1.10
-- attack only. No ride-music decay, pause music, heartbeat, or intercom voice.
-- OpenAir (0–1) fades a wind/rain bed on the Newtown Creek trestle.
-- SoundIds come from Shared.Assets (place StringValues). Empty → skip play
-- so unapproved classic rbxasset:// paths never hit Output.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Constants = require(ReplicatedStorage.Shared.Constants)
local DoorSound = require(ReplicatedStorage.Shared.DoorSound)
local Hold = require(ReplicatedStorage.Shared.Hold)
local Lines = require(ReplicatedStorage.Shared.Lines)
local Motion = require(ReplicatedStorage.Shared.Motion)

local Audio = {}

local muted = false
local group: SoundGroup? = nil
local rumble: Sound? = nil
local openAir: Sound? = nil
local muteButton: TextButton? = nil
local lastDoor: number? = nil
local lastPa = ""
local clackTravel = 0
local lastSpeedSample = 0
local openAirLevel = 0

local function makeSound(name: string, id: string, volume: number, looped: boolean): Sound?
	local ready = Assets.normalizeSoundId(id)
	if ready == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = ready
	sound.Volume = volume
	sound.Looped = looped
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	if group ~= nil then
		sound.SoundGroup = group
	end
	sound.Parent = SoundService
	return sound
end

local function destroySound(sound: Sound)
	if sound.Parent ~= nil then
		sound:Stop()
		sound:Destroy()
	end
end

local function whenSoundReady(sound: Sound, onReady: (length: number) -> ())
	local function finish(length: number)
		if sound.Parent == nil then
			return
		end
		onReady(length)
	end

	if sound.IsLoaded and sound.TimeLength > 0 then
		finish(sound.TimeLength)
		return
	end

	local conn: RBXScriptConnection? = nil
	conn = sound.Loaded:Connect(function()
		local c = conn
		if c ~= nil then
			c:Disconnect()
		end
		finish(sound.TimeLength)
	end)
	task.delay(Constants.SOUND_ONESHOT_MAX_LIFE, function()
		local c = conn
		if c ~= nil and c.Connected then
			c:Disconnect()
		end
		if sound.Parent ~= nil and not sound.IsPlaying then
			destroySound(sound)
		end
	end)
end

local function playOneShot(key: Assets.SoundKey, volume: number, playback: number?)
	if muted then
		return
	end
	local id = Assets.soundId(key)
	local sound = makeSound("OneShot", id, volume, false)
	if sound == nil then
		return
	end
	if playback ~= nil then
		sound.PlaybackSpeed = playback
	end
	sound:Play()
	sound.Ended:Once(function()
		destroySound(sound)
	end)
	task.delay(Constants.SOUND_ONESHOT_MAX_LIFE, function()
		destroySound(sound)
	end)
end

-- Play [startAt, endAt) on the Door asset. New instance per call so a 2.6s
-- dwell does not cut the open scene when close starts on top.
local function playDoorSlice(
	name: string,
	volume: number,
	windowFor: (length: number) -> (number, number)
)
	if muted then
		return
	end
	local id = Assets.soundId("door")
	local sound = makeSound(name, id, volume, false)
	if sound == nil then
		return
	end

	whenSoundReady(sound, function(length: number)
		if length <= 0 then
			destroySound(sound)
			return
		end
		local startAt, endAt = windowFor(length)
		local finish = math.clamp(endAt, 0, length)
		local start = math.clamp(startAt, 0, finish)
		if finish <= start then
			destroySound(sound)
			return
		end
		local speed = math.max(sound.PlaybackSpeed, 0.05)
		local life = (finish - start) / speed
		sound.TimePosition = start
		sound:Play()
		-- Stop at the scene end (do not wait for full-asset Ended / old 4s cutoff).
		task.delay(life + 0.05, function()
			destroySound(sound)
		end)
	end)
end

local function playChime()
	-- Two-tone stand-in for the MTA ding using one clip pitched twice.
	playOneShot("chime", Constants.SOUND_CHIME_VOLUME, 1.05)
	task.delay(0.45, function()
		playOneShot("chime", Constants.SOUND_CHIME_VOLUME * 0.9, 0.84)
	end)
end

local function playDoor(opening: boolean)
	playDoorSlice(if opening then "DoorOpen" else "DoorClose", Constants.SOUND_DOOR_VOLUME, function(length: number)
		return DoorSound.edgeWindow(length, opening)
	end)
end

local function playDoorEvpAttack()
	playDoorSlice("DoorEvp", 0.15, DoorSound.evpAttackWindow)
end

local function playClack()
	playOneShot("clack", Constants.SOUND_CLACK_VOLUME, 1.4 + math.random() * 0.2)
end

local function speedFraction(): number
	local ride = ReplicatedStorage:FindFirstChild("Ride")
	if ride == nil then
		return 0
	end
	if ride:GetAttribute("Phase") ~= "ride" then
		return 0
	end
	local start = ride:GetAttribute("StretchStart")
	local accel = ride:GetAttribute("StretchAccel")
	local cruise = ride:GetAttribute("StretchCruise")
	local brake = ride:GetAttribute("StretchBrake")
	if typeof(start) ~= "number" or typeof(accel) ~= "number" or typeof(cruise) ~= "number" or typeof(brake) ~= "number" then
		return 0
	end
	local holdAt = ride:GetAttribute("HoldAt")
	local holdFor = ride:GetAttribute("HoldFor")
	local at = if typeof(holdAt) == "number" then holdAt else 0
	local span = if typeof(holdFor) == "number" then holdFor else 0
	local elapsed = workspace:GetServerTimeNow() - start
	if not Hold.moving(elapsed, at, span) then
		return 0
	end
	local motionT = Hold.motionTime(elapsed, at, span)
	local top = Constants.TOP_SPEED_MPS
	local velocity = Motion.speed(motionT, accel, cruise, brake, top)
	if top <= 0 then
		return 0
	end
	return math.clamp(velocity / top, 0, 1)
end

local function refreshMuteLabel()
	local button = muteButton
	if button == nil then
		return
	end
	button.Text = if muted then Lines.UNMUTE else Lines.MUTE
end

function Audio.isMuted(): boolean
	return muted
end

function Audio.setMute(value: boolean)
	muted = value
	local bus = group
	if bus ~= nil then
		bus.Volume = if muted then 0 else 1
	end
	local loop = rumble
	if loop ~= nil and muted then
		loop.Volume = 0
	end
	local wind = openAir
	if wind ~= nil and muted then
		wind.Volume = 0
	end
	refreshMuteLabel()
end

function Audio.toggleMute(): boolean
	Audio.setMute(not muted)
	return muted
end

function Audio.start(button: TextButton)
	muteButton = button
	refreshMuteLabel()
	button.MouseButton1Click:Connect(function()
		Audio.toggleMute()
	end)

	local bus = Instance.new("SoundGroup")
	bus.Name = "LastLocal"
	bus.Volume = 1
	bus.Parent = SoundService
	group = bus

	local readyCount, total, missing = Assets.soundStatus()
	if readyCount == 0 then
		print(
			"[Last Local] Sound bed silent (no ReplicatedStorage.Assets IDs). Ride continues. See README → Sound bed."
		)
	elseif readyCount < total then
		print(
			string.format(
				"[Last Local] Sound bed %d/%d wired; silent without IDs: %s",
				readyCount,
				total,
				table.concat(missing, ", ")
			)
		)
	else
		print("[Last Local] Sound bed fully wired.")
	end

	local loop = makeSound("Rumble", Assets.soundId("rumble"), 0, true)
	if loop ~= nil then
		loop.PlaybackSpeed = Constants.SOUND_RUMBLE_PLAYBACK
		loop:Play()
		rumble = loop
	end

	local wind = makeSound("OpenAir", Assets.soundId("openAir"), 0, true)
	if wind ~= nil then
		wind.PlaybackSpeed = Constants.SOUND_OPEN_AIR_PLAYBACK
		wind:Play()
		openAir = wind
	end

	local ride = ReplicatedStorage:WaitForChild("Ride")
	local openAttr = ride:GetAttribute("OpenAir")
	openAirLevel = if typeof(openAttr) == "number" then math.clamp(openAttr, 0, 1) else 0

	local function onDoor(value: any)
		if typeof(value) ~= "number" then
			return
		end
		local previous = lastDoor
		lastDoor = value
		if previous == nil then
			return
		end
		if previous < 0.5 and value >= 0.5 then
			playDoor(true)
		elseif previous >= 0.5 and value < 0.5 then
			playDoor(false)
		end
	end

	local function onPa(value: any)
		local text = if typeof(value) == "string" then value else ""
		if text ~= "" and text ~= lastPa then
			playChime()
		end
		lastPa = text
	end

	onDoor(ride:GetAttribute("DoorTarget"))
	onPa(ride:GetAttribute("PaText"))

	local lastEvpRaised = false
	local lastPlayId = ""

	ride.AttributeChanged:Connect(function(name: string)
		if name == "DoorTarget" then
			onDoor(ride:GetAttribute("DoorTarget"))
		elseif name == "PaText" then
			onPa(ride:GetAttribute("PaText"))
		elseif name == "TrialChime" then
			local stamp = ride:GetAttribute("TrialChime")
			if typeof(stamp) == "number" and stamp > 0 then
				playChime()
			end
		elseif name == "EvpRaised" then
			local on = ride:GetAttribute("EvpRaised") == true
			if on and not lastEvpRaised then
				playDoorEvpAttack()
			end
			lastEvpRaised = on
			local loopSound = rumble
			if loopSound ~= nil and on and not muted then
				loopSound.Volume = math.min(loopSound.Volume, Constants.SOUND_RUMBLE_MIN)
			end
		elseif name == "PolaroidFlash" then
			local stamp = ride:GetAttribute("PolaroidFlash")
			if typeof(stamp) == "number" and stamp > 0 then
				playOneShot("polaroid", Constants.SOUND_POLAROID_VOLUME, 1.35)
			end
		elseif name == "OpenAir" then
			local level = ride:GetAttribute("OpenAir")
			openAirLevel = if typeof(level) == "number" then math.clamp(level, 0, 1) else 0
		elseif name == "EvpPlayId" then
			local id = ride:GetAttribute("EvpPlayId")
			local text = if typeof(id) == "string" then id else ""
			if text ~= "" and text ~= lastPlayId then
				playOneShot("chime", 0.25, 0.7)
				task.delay(0.35, function()
					playOneShot("chime", 0.2, 0.55)
				end)
			end
			lastPlayId = text
		end
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.M then
			Audio.toggleMute()
		end
	end)

	lastSpeedSample = os.clock()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = now - lastSpeedSample
		lastSpeedSample = now
		if dt <= 0 or dt > 0.5 then
			return
		end
		local fraction = speedFraction()
		local loopSound = rumble
		if loopSound ~= nil and not muted then
			local vol = Constants.SOUND_RUMBLE_MIN
				+ (Constants.SOUND_RUMBLE_MAX - Constants.SOUND_RUMBLE_MIN) * fraction
			loopSound.Volume = if fraction > 0.02 then vol else 0
		elseif loopSound ~= nil and muted then
			loopSound.Volume = 0
		end
		local windSound = openAir
		if windSound ~= nil and not muted then
			-- Web peaks ~0.14 * level; slice uses a quieter stand-in.
			windSound.Volume = Constants.SOUND_OPEN_AIR_MAX * openAirLevel
		elseif windSound ~= nil and muted then
			windSound.Volume = 0
		end
		if fraction > 0.08 then
			clackTravel += Constants.TOP_SPEED_MPS * fraction * dt
			if clackTravel >= Constants.CLACK_SPACING_M then
				clackTravel = 0
				playClack()
			end
		else
			clackTravel = 0
		end
	end)
end

return Audio
