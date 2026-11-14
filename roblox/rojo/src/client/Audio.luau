--!strict
-- Minimal sound bed. Client only. Phase, stretch timing, Held, DoorTarget,
-- and PaText stay server-owned; this module listens and plays.
-- Chime before PA, rumble from stretch speed, door open/close, track clacks.
-- No ride-music decay, pause music, EVP, heartbeat, or intercom voice.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Hold = require(ReplicatedStorage.Shared.Hold)
local Lines = require(ReplicatedStorage.Shared.Lines)
local Motion = require(ReplicatedStorage.Shared.Motion)

local Audio = {}

local muted = false
local group: SoundGroup? = nil
local rumble: Sound? = nil
local muteButton: TextButton? = nil
local lastDoor: number? = nil
local lastPa = ""
local clackTravel = 0
local lastSpeedSample = 0

local function makeSound(name: string, id: string, volume: number, looped: boolean): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	if group ~= nil then
		sound.SoundGroup = group
	end
	sound.Parent = SoundService
	return sound
end

local function playOneShot(id: string, volume: number, playback: number?)
	if muted then
		return
	end
	local sound = makeSound("OneShot", id, volume, false)
	if playback ~= nil then
		sound.PlaybackSpeed = playback
	end
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(4, function()
		if sound.Parent ~= nil then
			sound:Destroy()
		end
	end)
end

local function playChime()
	-- Two-tone stand-in for the MTA ding using one built-in ping pitched twice.
	playOneShot(Constants.SOUND_CHIME, Constants.SOUND_CHIME_VOLUME, 1.05)
	task.delay(0.45, function()
		playOneShot(Constants.SOUND_CHIME, Constants.SOUND_CHIME_VOLUME * 0.9, 0.84)
	end)
end

local function playDoor(opening: boolean)
	playOneShot(Constants.SOUND_DOOR, Constants.SOUND_DOOR_VOLUME, if opening then 1.1 else 0.85)
end

local function playClack()
	playOneShot(Constants.SOUND_CLACK, Constants.SOUND_CLACK_VOLUME, 1.4 + math.random() * 0.2)
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

	local loop = makeSound("Rumble", Constants.SOUND_RUMBLE, 0, true)
	loop.PlaybackSpeed = Constants.SOUND_RUMBLE_PLAYBACK
	loop:Play()
	rumble = loop

	local ride = ReplicatedStorage:WaitForChild("Ride")

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
				playOneShot(Constants.SOUND_DOOR, 0.15, 1.6)
			end
			lastEvpRaised = on
			local loopSound = rumble
			if loopSound ~= nil and on and not muted then
				loopSound.Volume = math.min(loopSound.Volume, Constants.SOUND_RUMBLE_MIN)
			end
		elseif name == "EvpPlayId" then
			local id = ride:GetAttribute("EvpPlayId")
			local text = if typeof(id) == "string" then id else ""
			if text ~= "" and text ~= lastPlayId then
				playOneShot(Constants.SOUND_CHIME, 0.25, 0.7)
				task.delay(0.35, function()
					playOneShot(Constants.SOUND_CHIME, 0.2, 0.55)
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
