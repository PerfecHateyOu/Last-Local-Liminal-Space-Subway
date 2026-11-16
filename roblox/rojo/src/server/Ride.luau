--!strict
-- Stop cycle for the G, from gameState.ts.
-- PA lines are the web game's lines (see Shared.Lines). The car stays put.
-- The tunnel and the platforms move: accel, cruise, and brake use the same
-- stretch times as the stop timer (Motion.luau).
--
-- Lighting rule (web doc, and the nightmare-bulb comment in gameState.ts):
-- the only whole-car blackout is the flicker tick, 0.16 seconds, used on the
-- silent stretch after Myrtle–Willoughby Avs and on the arrival at 21 St.
-- The doors tick opens the doors early and does not touch the lights.
-- The last stretch may dim in a straight line. Tunnel lamps are outside and
-- never write these interior lights.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnomalySystem = require(script.Parent.AnomalySystem)
local CarBuilder = require(script.Parent.CarBuilder)
local MetaStore = require(script.Parent.MetaStore)
local Scenery = require(script.Parent.Scenery)
local TrialSpace = require(script.Parent.TrialSpace)
local WorldLight = require(script.Parent.WorldLight)
local Achievements = require(ReplicatedStorage.Shared.Achievements)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Trestle = require(ReplicatedStorage.Shared.Trestle)
local Doors = require(ReplicatedStorage.Shared.Doors)
local Dwell = require(ReplicatedStorage.Shared.Dwell)
local Hold = require(ReplicatedStorage.Shared.Hold)
local Dialogue = require(ReplicatedStorage.Shared.Dialogue)
local Haven = require(ReplicatedStorage.Shared.Haven)
local Nightmare = require(ReplicatedStorage.Shared.Nightmare)
local Practice = require(ReplicatedStorage.Shared.Practice)
local Trial = require(ReplicatedStorage.Shared.Trial)
local Evp = require(ReplicatedStorage.Shared.Evp)
local Polaroid = require(ReplicatedStorage.Shared.Polaroid)
local Sanity = require(ReplicatedStorage.Shared.Sanity)
local Restraint = require(ReplicatedStorage.Shared.Restraint)
local Endings = require(ReplicatedStorage.Shared.Endings)
local Lines = require(ReplicatedStorage.Shared.Lines)
local PsychLog = require(ReplicatedStorage.Shared.PsychLog)
local Score = require(ReplicatedStorage.Shared.Score)
local Band = require(ReplicatedStorage.Shared.Band)
local Motion = require(ReplicatedStorage.Shared.Motion)
local Route = require(ReplicatedStorage.Shared.Route)

local Ride = {}

function Ride.start(car: CarBuilder.BuiltCar)
	local ride = Instance.new("Folder")
	ride.Name = "Ride"
	ride.Parent = ReplicatedStorage

	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local flagRemote = Instance.new("RemoteEvent")
	flagRemote.Name = "Flag"
	flagRemote.Parent = remotes
	local doorsRemote = Instance.new("RemoteEvent")
	doorsRemote.Name = "Doors"
	doorsRemote.Parent = remotes
	local maskRemote = Instance.new("RemoteEvent")
	maskRemote.Name = "Mask"
	maskRemote.Parent = remotes
	local trialRemote = Instance.new("RemoteEvent")
	trialRemote.Name = "Trial"
	trialRemote.Parent = remotes
	local evpToggleRemote = Instance.new("RemoteEvent")
	evpToggleRemote.Name = "EvpToggle"
	evpToggleRemote.Parent = remotes
	local evpTuneRemote = Instance.new("RemoteEvent")
	evpTuneRemote.Name = "EvpTune"
	evpTuneRemote.Parent = remotes
	local evpRecordRemote = Instance.new("RemoteEvent")
	evpRecordRemote.Name = "EvpRecord"
	evpRecordRemote.Parent = remotes
	local evpPlayRemote = Instance.new("RemoteEvent")
	evpPlayRemote.Name = "EvpPlay"
	evpPlayRemote.Parent = remotes
	local polaroidToggleRemote = Instance.new("RemoteEvent")
	polaroidToggleRemote.Name = "PolaroidToggle"
	polaroidToggleRemote.Parent = remotes
	local polaroidSnapRemote = Instance.new("RemoteEvent")
	polaroidSnapRemote.Name = "PolaroidSnap"
	polaroidSnapRemote.Parent = remotes
	local polaroidAlbumRemote = Instance.new("RemoteEvent")
	polaroidAlbumRemote.Name = "PolaroidAlbum"
	polaroidAlbumRemote.Parent = remotes
	local holdRemote = Instance.new("RemoteEvent")
	holdRemote.Name = "Hold"
	holdRemote.Parent = remotes
	local exitRemote = Instance.new("RemoteEvent")
	exitRemote.Name = "Exit"
	exitRemote.Parent = remotes
	local gazeRemote = Instance.new("RemoteEvent")
	gazeRemote.Name = "Gaze"
	gazeRemote.Parent = remotes
	local metaStartRemote = Instance.new("RemoteEvent")
	metaStartRemote.Name = "MetaStart"
	metaStartRemote.Parent = remotes
	local metaAgainRemote = Instance.new("RemoteEvent")
	metaAgainRemote.Name = "MetaAgain"
	metaAgainRemote.Parent = remotes

	ride:SetAttribute("Phase", "menu")
	ride:SetAttribute("PaText", "")
	ride:SetAttribute("Subtitle", "")
	ride:SetAttribute("Hint", "")
	ride:SetAttribute("Feedback", "")
	ride:SetAttribute("FeedbackKind", "")
	ride:SetAttribute("NextStop", Route.stopName(2))
	ride:SetAttribute("ChapterLine", Route.chapterLine(1))
	ride:SetAttribute("DwellUntil", 0)
	ride:SetAttribute("Suspicion", 0)
	ride:SetAttribute("PeakSuspicion", 0)
	ride:SetAttribute("Sanity", Constants.SANITY_START)
	ride:SetAttribute("SanityTier", Sanity.tierOf(Constants.SANITY_START))
	ride:SetAttribute("SanityRetained", 0)
	ride:SetAttribute("Interventions", 0)
	ride:SetAttribute("Intervening", false)
	ride:SetAttribute("RestraintActive", false)
	ride:SetAttribute("RestraintProgress", 0)
	ride:SetAttribute("RestraintOK", false)
	ride:SetAttribute("ExitActive", false)
	ride:SetAttribute("ExitUntil", 0)
	ride:SetAttribute("ReportReady", false)
	ride:SetAttribute("EndingId", "")
	ride:SetAttribute("EndingTitle", "")
	ride:SetAttribute("EndingBadge", "")
	ride:SetAttribute("EndingNarrative", "")
	ride:SetAttribute("ReportStats", "")
	ride:SetAttribute("ReportPsych", "")
	ride:SetAttribute("HasRecorder", false)
	ride:SetAttribute("NightmareUnlocked", false)
	ride:SetAttribute("NightmareOn", false)
	ride:SetAttribute("PracticeOn", false)
	ride:SetAttribute("MetaArchive", "")
	ride:SetAttribute("PracticeNote", "")
	ride:SetAttribute("SegStop", 0)
	ride:SetAttribute("EvpRaised", false)
	ride:SetAttribute("EvpKhz", 120)
	ride:SetAttribute("EvpMeter", 0)
	ride:SetAttribute("EvpLocked", "")
	ride:SetAttribute("EvpStatus", "")
	ride:SetAttribute("EvpRecordT", 0)
	ride:SetAttribute("EvpTapes", "[]")
	ride:SetAttribute("EvpSaved", "")
	ride:SetAttribute("EvpPlayId", "")
	ride:SetAttribute("TapeGlance", 0)
	ride:SetAttribute("FlashGlance", 0)
	ride:SetAttribute("CameraRaised", false)
	ride:SetAttribute("AlbumOpen", false)
	ride:SetAttribute("FilmLeft", Polaroid.STARTING_FILM)
	ride:SetAttribute("PolaroidFlash", 0)
	ride:SetAttribute("PolaroidAlbum", "[]")
	ride:SetAttribute("OpenAir", 0)
	ride:SetAttribute("Band", "calm")
	ride:SetAttribute("FalseStopBonus", 0)
	ride:SetAttribute("BoardStop", "")
	ride:SetAttribute("BoardMinutes", 0)
	ride:SetAttribute("HoldAt", 0)
	ride:SetAttribute("HoldFor", 0)
	ride:SetAttribute("Held", false)
	ride:SetAttribute("StareIntervalScale", 1)
	-- 1 open, 0 closed. Client sound listens; the door leaves still ease toward this.
	ride:SetAttribute("DoorTarget", 1)
	ride:SetAttribute("ChoiceActive", false)
	ride:SetAttribute("ChoiceUntil", 0)
	ride:SetAttribute("MaskActive", false)
	ride:SetAttribute("MaskUntil", 0)
	ride:SetAttribute("MaskA", "")
	ride:SetAttribute("MaskB", "")
	ride:SetAttribute("MaskC", "")
	ride:SetAttribute("TrialActive", false)
	ride:SetAttribute("TrialUntil", 0)
	ride:SetAttribute("TrialA", "")
	ride:SetAttribute("TrialB", "")
	ride:SetAttribute("TrialC", "")
	ride:SetAttribute("TrialSlots", 0)
	ride:SetAttribute("TrialChime", 0)

	local trialSpace = TrialSpace.build()
	local carReturn = car.board.CFrame * CFrame.new(0, 3, 0)

	CarBuilder.addTells(
		car.passengers,
		AnomalySystem.ANNOUNCE_ID,
		Lines.ANNOUNCEMENT,
		AnomalySystem.COUNTDOWN_ID,
		Lines.COUNTDOWN
	)
	CarBuilder.addCatalogProps(car.passengers)

	local paToken = 0
	local subToken = 0
	local hintToken = 0
	local feedbackToken = 0

	local function showTimed(attr: string, text: string, seconds: number, tokenName: string): number
		local token = 0
		if tokenName == "pa" then
			paToken += 1
			token = paToken
		elseif tokenName == "sub" then
			subToken += 1
			token = subToken
		else
			hintToken += 1
			token = hintToken
		end
		ride:SetAttribute(attr, text)
		task.delay(seconds, function()
			local current = if tokenName == "pa" then paToken elseif tokenName == "sub" then subToken else hintToken
			if current == token then
				ride:SetAttribute(attr, "")
			end
		end)
		return token
	end

	local function showPa(text: string, seconds: number)
		local line = text
		if ride:GetAttribute("Band") == "watched" then
			line = Band.glitchLine(text)
		end
		showTimed("PaText", line, seconds, "pa")
	end

	local function showSub(text: string, seconds: number)
		showTimed("Subtitle", text, seconds, "sub")
	end

	local function showHint(text: string, seconds: number)
		showTimed("Hint", text, seconds, "hint")
	end

	local function showFeedback(kind: string, text: string, sticky: boolean)
		feedbackToken += 1
		local token = feedbackToken
		ride:SetAttribute("FeedbackKind", kind)
		ride:SetAttribute("Feedback", text)
		if not sticky then
			task.delay(2.6, function()
				if feedbackToken == token then
					ride:SetAttribute("FeedbackKind", "")
					ride:SetAttribute("Feedback", "")
				end
			end)
		end
	end

	local doorOpen = 1
	local doorTarget = 1
	local function setDoorTarget(value: number)
		doorTarget = value
		ride:SetAttribute("DoorTarget", value)
	end
	local dim = 1
	local dimFrom = 1
	local dimTo = 1
	local dimStart = 0
	local dimDuration = 1
	local dimming = false
	local forcedOff = false

	local function blackout()
		-- Flicker tick only. Callers are the two segments whose tick is "flicker".
		-- Watched / hunted lengthens the tick slightly; still not a hold blackout.
		local seconds = Constants.FLICKER_TICK_SECONDS
		local bandAttr = ride:GetAttribute("Band")
		if bandAttr == "hunted" then
			seconds *= Constants.FLICKER_HUNTED_SCALE
		elseif bandAttr == "watched" then
			seconds *= Constants.FLICKER_WATCHED_SCALE
		end
		forcedOff = true
		task.delay(seconds, function()
			forcedOff = false
		end)
	end

	local function beginDim(target: number, seconds: number)
		dimFrom = dim
		dimTo = target
		dimStart = os.clock()
		dimDuration = math.max(0.1, seconds)
		dimming = true
	end

	-- A single LightStrip can go dark on its own. That is not the door tick.
	local stripHold: { [BasePart]: boolean } = {}
	local posterOriginal: { [BasePart]: Color3 } = {}

	local function applyLights()
		local k = if forcedOff then 0 else dim
		local color = Constants.COLOR.lightOff:Lerp(Constants.COLOR.lightOn, k)
		for _, lamp in car.lamps do
			if forcedOff or stripHold[lamp.part] ~= true then
				lamp.part.Color = color
			end
			local point = lamp.light
			if point ~= nil then
				point.Brightness = Constants.LAMP_BRIGHTNESS * k
				point.Range = Constants.meters(Constants.LAMP_RANGE_M)
				point.Enabled = k > 0.03
			end
		end
	end

	local odo = 0
	local leaving, arriving = Scenery.build()
	Scenery.setName(leaving, Route.stopName(1))
	local trestlePlan: Trestle.Plan = Trestle.plan(0, false, 0, 1)
	local lastOpenAir = -1

	type Stretch = {
		start: number,
		origin: number,
		accel: number,
		cruise: number,
		brake: number,
		top: number,
		holdAt: number,
		holdFor: number,
	}
	local stretch: Stretch? = nil
	local nightmareOn = false
	local practiceOn = false
	local startChapter = 1
	local trestleBadgeChecked = false
	local anomalyTypesSeen: { [string]: boolean } = {}
	local pendingStart: { nightmare: boolean, chapter: number }? = nil
	local pendingAgain = false
	local metaUserId: number? = nil

	local function publishOpenAir(level: number)
		if math.abs(level - lastOpenAir) < 0.03 then
			return
		end
		lastOpenAir = level
		ride:SetAttribute("OpenAir", level)
		Scenery.setOpenAirLevel(level)
		WorldLight.setOpenAir(level)
		if level > 0.4 and not trestleBadgeChecked then
			trestleBadgeChecked = true
		end
	end

	local function beginStretch(seg: Route.Segment, holdAt: number, holdFor: number)
		local accel = Constants.ACCEL
		local brake = Constants.BRAKE
		local cruise = Nightmare.cruiseSeconds(seg.sliceCruise, nightmareOn)
		local top = Nightmare.topSpeed(Constants.TOP_SPEED_MPS, nightmareOn)
		-- Whichever platform is already at the doors is the one we leave.
		if math.abs(arriving.base - odo) < math.abs(leaving.base - odo) then
			local swap = leaving
			leaving = arriving
			arriving = swap
		end
		leaving.base = odo
		local dist = Motion.segmentDistance(accel, cruise, brake, top)
		arriving.base = odo + dist
		Scenery.setName(arriving, Route.stopName(seg.stop))
		-- Newtown Creek: open-air 21 St approach / departure (web gameState trestle).
		trestlePlan = Trestle.plan(seg.stop, seg.b, odo, dist)
		Scenery.setOpenAir(leaving, Trestle.leavingOpenAir(seg.stop))
		Scenery.setOpenAir(arriving, Trestle.arrivingOpenAir(seg.stop, seg.b))
		local now = workspace:GetServerTimeNow()
		stretch = {
			start = now,
			origin = odo,
			accel = accel,
			cruise = cruise,
			brake = brake,
			top = top,
			holdAt = holdAt,
			holdFor = holdFor,
		}
		ride:SetAttribute("StretchStart", now)
		ride:SetAttribute("StretchAccel", accel)
		ride:SetAttribute("StretchCruise", cruise)
		ride:SetAttribute("StretchBrake", brake)
		ride:SetAttribute("HoldAt", holdAt)
		ride:SetAttribute("HoldFor", holdFor)
		ride:SetAttribute("Held", false)
		ride:SetAttribute("StareIntervalScale", Hold.stareScale(false, Constants.HOLD_STARE_MULTIPLIER))
	end

	local slide = Constants.meters(Constants.DOOR_SLIDE_M)
	RunService.Heartbeat:Connect(function(dt: number)
		local current = stretch
		if current ~= nil then
			local elapsed = workspace:GetServerTimeNow() - current.start
			local motionT = Hold.motionTime(elapsed, current.holdAt, current.holdFor)
			odo = current.origin + Motion.distance(motionT, current.accel, current.cruise, current.brake, current.top)
		end
		local openLevel = if ride:GetAttribute("Phase") == "trial" then 0 else Trestle.outsideLevel(odo, trestlePlan)
		publishOpenAir(openLevel)
		Scenery.place(odo)
		doorOpen += (doorTarget - doorOpen) * (1 - math.exp(-7 * dt))
		for _, leaf in car.doors do
			local x = leaf.x0 + leaf.side * slide * doorOpen
			leaf.model:PivotTo(CFrame.new(x, leaf.y, leaf.z))
		end
		if dimming then
			local alpha = math.clamp((os.clock() - dimStart) / dimDuration, 0, 1)
			dim = dimFrom + (dimTo - dimFrom) * alpha
			if alpha >= 1 then
				dimming = false
			end
		end
		applyLights()
	end)

	local flagged: { [string]: boolean } = {}
	local falseFlags = 0
	local caught = false
	local suspicion = 0
	local peakSuspicion = 0
	local sanity = Constants.SANITY_START
	local bandStop = 1
	local sanSamples: { number } = {}
	local interventions = 0
	local intervening = false
	local restraintState: Restraint.State? = nil
	local restraintDone = false
	local restraintOK = false
	local restraintHeld = false
	local restraintHidden: { string } = {}
	local restraintMomRest: { [BasePart]: Color3 } = {}
	local accCorrect = 0
	local accMiss = 0
	local trialStops: { number } = {}
	local finalExit: Endings.ExitChoice = "escalators"
	local pendingExitChoice: string? = nil
	local exitEpoch = 0
	local stopHadAnomaly = false
	local stopNoticed = false
	local stopFalseAlarm = false
	local posterLive = false
	local inFinal = false
	local huntedDim = false
	local maskUsed: { [string]: boolean } = {}
	local maskLast: string? = nil
	local maskBusy = false
	local chatPlan = Dialogue.buildChatPlan(function()
		return math.random()
	end)

	local hasRecorder = false
	local evpState = Evp.newState(function()
		return math.random()
	end)
	local currentSegStop: number? = nil
	local cameraRaised = false
	local albumOpen = false
	local filmLeft = Polaroid.STARTING_FILM
	local nextShotAt = 0
	local polaroidPhotos: { Polaroid.Photo } = {}
	local photoSeq = 0
	local psychLog = PsychLog.newRide()
	local gazeTarget: string? = nil
	local gazeSince = 0
	local stareAnomalyCharged = false
	local stareParentCharged = false
	local falseStopReacted = false
	local falseStopOpen = false
	local stretchMovedM = 0
	-- Per player. One shared position adds the distance between riders every frame.
	local lastRootPos: { [number]: Vector3 } = {}
	local hasRootPos: { [number]: boolean } = {}

	local function publishSanity()
		ride:SetAttribute("Sanity", sanity)
		ride:SetAttribute("SanityTier", Sanity.tierOf(sanity))
	end

	local function applySanity(delta: number)
		local lo, hi = Sanity.bandForStop(bandStop, restraintOK, Constants.RESTRAINT_RAISE)
		sanity = Sanity.apply(sanity, delta, lo, hi)
		publishSanity()
	end

	local function sampleSanity()
		local lo, hi = Sanity.bandForStop(bandStop, restraintOK, Constants.RESTRAINT_RAISE)
		table.insert(sanSamples, Sanity.bandPosition(sanity, lo, hi))
		ride:SetAttribute("SanityRetained", Sanity.retainedPercent(sanSamples))
	end

	local function setWalkLocked(locked: boolean)
		for _, player in game:GetService("Players"):GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				if locked then
					humanoid.WalkSpeed = 0
				else
					humanoid.WalkSpeed = Constants.WALK_SPEED_MPS * Constants.STUDS_PER_METER
				end
			end
		end
	end

	local function publishEvp()
		ride:SetAttribute("EvpRaised", evpState.raised)
		ride:SetAttribute("EvpKhz", evpState.khz)
		ride:SetAttribute("EvpMeter", evpState.meter)
		ride:SetAttribute("EvpLocked", evpState.lockedKind)
		ride:SetAttribute("EvpRecordT", evpState.recordT)
		ride:SetAttribute("EvpTapes", HttpService:JSONEncode(evpState.tapes))
		local riding = ride:GetAttribute("Phase") == "ride"
		ride:SetAttribute("EvpStatus", Evp.statusLine(evpState, riding == true))
	end

	local function publishCamera()
		ride:SetAttribute("CameraRaised", cameraRaised)
		ride:SetAttribute("AlbumOpen", albumOpen)
		ride:SetAttribute("FilmLeft", filmLeft)
		local slim = {}
		for _, photo in polaroidPhotos do
			table.insert(slim, { id = photo.id, stop = photo.stop })
		end
		ride:SetAttribute("PolaroidAlbum", HttpService:JSONEncode(slim))
	end

	local function handsBusy(): boolean
		return ride:GetAttribute("ChoiceActive") == true
			or ride:GetAttribute("MaskActive") == true
			or ride:GetAttribute("TrialActive") == true
			or ride:GetAttribute("Phase") == "trial"
			or ride:GetAttribute("RestraintActive") == true
			or ride:GetAttribute("Intervening") == true
			or ride:GetAttribute("ExitActive") == true
	end

	local function lowerCamera()
		cameraRaised = false
		publishCamera()
	end

	local function giveRecorder(where: string)
		if hasRecorder or ride:GetAttribute("Phase") == "end" then
			return
		end
		hasRecorder = true
		ride:SetAttribute("HasRecorder", true)
		if where == "haven" then
			showSub(Lines.DAD_RECORDER_HAVEN, 4.2)
		else
			showSub(Lines.DAD_RECORDER_TRAIN, 4.2)
		end
		showHint(Lines.RECORDER_HINT, 5)
	end

	publishEvp()
	publishCamera()

	evpToggleRemote.OnServerEvent:Connect(function(_player: Player)
		if not hasRecorder then
			showHint(Lines.RECORDER_NONE, 2.5)
			return
		end
		if evpState.raised then
			Evp.lower(evpState)
			publishEvp()
			return
		end
		local phase = ride:GetAttribute("Phase")
		if phase ~= "ride" and phase ~= "stop" and phase ~= "haven" and phase ~= "intro" then
			return
		end
		if handsBusy() then
			showHint(Lines.RECORDER_BUSY, 2)
			return
		end
		lowerCamera()
		albumOpen = false
		Evp.raise(evpState)
		publishEvp()
		publishCamera()
	end)

	evpTuneRemote.OnServerEvent:Connect(function(_player: Player, delta: any)
		if not evpState.raised then
			return
		end
		if typeof(delta) ~= "number" then
			return
		end
		Evp.tune(evpState, math.clamp(delta, -5, 5))
		publishEvp()
	end)

	evpRecordRemote.OnServerEvent:Connect(function(_player: Player, on: any)
		if not evpState.raised then
			return
		end
		if typeof(on) ~= "boolean" then
			return
		end
		Evp.setRecording(evpState, on)
		publishEvp()
	end)

	evpPlayRemote.OnServerEvent:Connect(function(_player: Player, signalId: any)
		if typeof(signalId) ~= "string" then
			return
		end
		if not Evp.hasTape(evpState, signalId) then
			return
		end
		local sig = Evp.signalById(signalId)
		if sig == nil then
			return
		end
		ride:SetAttribute("EvpPlayId", signalId)
		showSub("Tape: " .. sig.title, 3.5)
		local phase = ride:GetAttribute("Phase")
		if (phase == "ride" or phase == "stop") and math.random() < Evp.TAPE_GLANCE_CHANCE then
			task.delay(0.8, function()
				ride:SetAttribute("TapeGlance", workspace:GetServerTimeNow())
			end)
		end
		task.delay(4, function()
			if ride:GetAttribute("EvpPlayId") == signalId then
				ride:SetAttribute("EvpPlayId", "")
			end
		end)
	end)

	polaroidToggleRemote.OnServerEvent:Connect(function(_player: Player)
		local phase = ride:GetAttribute("Phase")
		if phase ~= "ride" and phase ~= "stop" and phase ~= "haven" and phase ~= "intro" then
			return
		end
		if cameraRaised then
			lowerCamera()
			return
		end
		if handsBusy() then
			showHint(Lines.CAMERA_BUSY, 2)
			return
		end
		if evpState.raised then
			Evp.lower(evpState)
			publishEvp()
		end
		albumOpen = false
		cameraRaised = true
		publishCamera()
	end)

	polaroidAlbumRemote.OnServerEvent:Connect(function(_player: Player)
		albumOpen = not albumOpen
		if albumOpen then
			lowerCamera()
		end
		publishCamera()
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		if handsBusy() then
			if cameraRaised then
				lowerCamera()
			end
			if evpState.raised then
				Evp.lower(evpState)
				publishEvp()
			end
			return
		end
		if not evpState.raised then
			return
		end
		local stopLabel = ""
		local stopAttr = ride:GetAttribute("NextStop")
		if typeof(stopAttr) == "string" then
			stopLabel = stopAttr
		end
		local ridingStop: number? = nil
		if ride:GetAttribute("Phase") == "ride" then
			ridingStop = currentSegStop
		end
		local tape = Evp.update(evpState, dt, ridingStop, stopLabel)
		publishEvp()
		if tape ~= nil then
			ride:SetAttribute("EvpSaved", tape.title)
			showSub("Saved to tape: " .. tape.title, 2.6)
			task.delay(2.8, function()
				if ride:GetAttribute("EvpSaved") == tape.title then
					ride:SetAttribute("EvpSaved", "")
				end
			end)
		end
	end)

	local function blinkBandTube()
		for _, lamp in car.lamps do
			if lamp.part.Name == Constants.BAND_STRIP_NAME then
				stripHold[lamp.part] = true
				lamp.part.Color = Constants.COLOR.lightOff
				local part = lamp.part
				task.delay(Constants.UNEASY_TUBE_BLINK, function()
					stripHold[part] = nil
				end)
				break
			end
		end
	end

	local function publishBand()
		local band = Band.fromSuspicion(suspicion, Constants.BAND_CALM_MAX, Constants.BAND_UNEASY_MAX, Constants.BAND_WATCHED_MAX)
		ride:SetAttribute("Band", band)
		-- Fixed route. The bonus is not used to pick a false stop.
		ride:SetAttribute("FalseStopBonus", Band.falseStopBonus(band, Constants.WATCHED_FALSE_STOP_BONUS))
		local effect = Band.light(band)
		if effect == "dim" and not inFinal then
			if not huntedDim then
				huntedDim = true
				beginDim(Band.dimTarget(Constants.HUNTED_DIM), Constants.HUNTED_DIM_SECONDS)
			end
		elseif huntedDim then
			huntedDim = false
			beginDim(Band.dimTarget(1), Constants.HUNTED_DIM_SECONDS)
		end
	end

	local maybeIntervene: () -> ()

	local function applySuspicion(delta: number)
		suspicion = Score.apply(suspicion, delta, Constants.SUSPICION_MIN, Constants.SUSPICION_MAX)
		-- Product decision: clamp at 100, never end the ride (SUSPICION_HARD_FAIL = false).
		if suspicion > peakSuspicion then
			peakSuspicion = suspicion
			ride:SetAttribute("PeakSuspicion", peakSuspicion)
		end
		ride:SetAttribute("Suspicion", suspicion)
		publishBand()
		maybeIntervene()
	end

	local function publishRestraint()
		local active = restraintState ~= nil
		ride:SetAttribute("RestraintActive", active)
		ride:SetAttribute("RestraintProgress", if restraintState ~= nil then Restraint.progress(restraintState) else 0)
		ride:SetAttribute("RestraintOK", restraintOK)
		setWalkLocked(active or intervening)
	end

	local function restoreRestraintVisuals()
		local mom = car.passengers:FindFirstChild(AnomalySystem.MOMFACE_ID)
		if mom ~= nil and mom:IsA("Model") then
			for part, color in restraintMomRest do
				part.Color = color
			end
		end
		table.clear(restraintMomRest)
		for _, id in restraintHidden do
			CarBuilder.setPassengerShown(car.passengers, id, true)
		end
		table.clear(restraintHidden)
	end

	local function endRestraint(ok: boolean, why: string)
		restraintState = nil
		restraintDone = true
		restraintOK = ok
		restraintHeld = false
		restoreRestraintVisuals()
		beginDim(1, 1.2)
		publishRestraint()
		if ok then
			applySanity(Constants.SANITY_RESTRAINT_OK)
			showSub(Lines.RESTRAINT_OK, 3.0)
		else
			applySuspicion(Constants.RESTRAINT_FAIL_SUSPICION)
			applySanity(-Constants.SANITY_RESTRAINT_FAIL)
			showSub(if why ~= "" then why else Lines.RESTRAINT_FAIL, 3.0)
		end
		ride:SetAttribute("RestraintOK", restraintOK)
	end

	local function startRestraintMoment()
		if restraintState ~= nil or restraintDone then
			return
		end
		if intervening or maskBusy or ride:GetAttribute("ChoiceActive") == true then
			return
		end
		if cameraRaised then
			cameraRaised = false
			albumOpen = false
			publishCamera()
		end
		if evpState.raised then
			Evp.lower(evpState)
			publishEvp()
		end
		restraintState = Restraint.newState(Constants.RESTRAINT_DURATION)
		publishRestraint()
		-- Keep the banner up for the full grab window (web shows 6s on a 5s wait).
		showHint(Lines.RESTRAINT_HINT, Constants.RESTRAINT_WAIT)
	end

	local function updateRestraint(dt: number)
		local state = restraintState
		if state == nil then
			return
		end
		local outcome = Restraint.tick(state, dt, restraintHeld)
		ride:SetAttribute("RestraintProgress", Restraint.progress(state))
		if outcome == "fail_wait" then
			endRestraint(false, Lines.RESTRAINT_FAIL_WAIT)
			return
		end
		if outcome == "fail_release" then
			endRestraint(false, Lines.RESTRAINT_FAIL)
			return
		end
		if outcome == "ok" then
			endRestraint(true, "Held")
			return
		end
		if outcome == "holding" then
			dim = Restraint.dimFraction(state.t)
			applyLights()
			if Restraint.shouldFireBeat(state, Restraint.BEAT_MOM) then
				local mom = car.passengers:FindFirstChild(AnomalySystem.MOMFACE_ID)
				if mom ~= nil and mom:IsA("Model") then
					for _, desc in mom:GetDescendants() do
						if desc:IsA("BasePart") and (desc.Name == "Head" or desc.Name == "Hair" or desc.Name == "Eye") then
							restraintMomRest[desc] = desc.Color
							if desc.Name == "Eye" then
								desc.Color = Color3.fromRGB(20, 20, 28)
							else
								desc.Color = Color3.fromRGB(223, 217, 206)
							end
						end
					end
				end
			end
			if Restraint.shouldFireBeat(state, Restraint.BEAT_DAD) then
				showSub(Lines.RESTRAINT_DAD, 3.2)
			end
			if Restraint.shouldFireBeat(state, Restraint.BEAT_EMPTY) then
				for _, id in { "s1", "s2", "s3", AnomalySystem.EXTRA_ID, "c1", "c2", "c3", "c4", "c5" } do
					local model = car.passengers:FindFirstChild(id)
					if model ~= nil and model:GetAttribute("Hidden") ~= true then
						table.insert(restraintHidden, id)
						CarBuilder.setPassengerShown(car.passengers, id, false)
					end
				end
			end
			if Restraint.shouldFireBeat(state, Restraint.BEAT_MOUTH) then
				showSub(Lines.RESTRAINT_MOM_MOUTH, 3.4)
			end
		end
	end

	local function triggerConcernedIntervention()
		if intervening or restraintState ~= nil then
			return
		end
		if ride:GetAttribute("ChoiceActive") == true or ride:GetAttribute("MaskActive") == true then
			return
		end
		if suspicion < Constants.INTERVENE_SUSPICION then
			return
		end
		intervening = true
		interventions += 1
		ride:SetAttribute("Intervening", true)
		ride:SetAttribute("Interventions", interventions)
		setWalkLocked(true)
		restraintHeld = false
		if cameraRaised then
			cameraRaised = false
			publishCamera()
		end
		if evpState.raised then
			Evp.lower(evpState)
			publishEvp()
		end
		showSub(Lines.INTERVENTION_DAD, 2.6)
		task.delay(2.7, function()
			if not intervening then
				return
			end
			showSub(Lines.INTERVENTION_MOM, 3.0)
		end)
		task.delay(5.9, function()
			if not intervening then
				return
			end
			showSub(Lines.INTERVENTION_YOU, 2.4)
		end)
		task.delay(8.4, function()
			if not intervening then
				return
			end
			intervening = false
			ride:SetAttribute("Intervening", false)
			setWalkLocked(restraintState ~= nil)
			applySanity(-Constants.SANITY_INTERVENTION)
			suspicion = Constants.INTERVENTION_RESET_SUSPICION
			ride:SetAttribute("Suspicion", suspicion)
			publishBand()
			-- No hard fail: intervention cools the meter; the ride continues.
		end)
	end

	maybeIntervene = function()
		-- Rojo product decision: no hard fail at suspicion 100. Intervention
		-- cools the meter at INTERVENE_SUSPICION; the ride always continues.
		if Constants.SUSPICION_HARD_FAIL then
			return
		end
		if suspicion >= Constants.INTERVENE_SUSPICION then
			triggerConcernedIntervention()
		end
	end

	holdRemote.OnServerEvent:Connect(function(player: Player, held: any)
		if typeof(held) ~= "boolean" then
			return
		end
		if player.Character == nil then
			return
		end
		if restraintState == nil then
			restraintHeld = false
			return
		end
		restraintHeld = held
	end)

	exitRemote.OnServerEvent:Connect(function(player: Player, choice: any)
		if ride:GetAttribute("ExitActive") ~= true then
			return
		end
		-- Single-player slice: ignore Exit from anyone not in the ride.
		if player.Character == nil then
			return
		end
		if typeof(choice) ~= "string" then
			return
		end
		pendingExitChoice = choice
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		if restraintState ~= nil then
			updateRestraint(dt)
		end
	end)

	polaroidSnapRemote.OnServerEvent:Connect(function(
		_player: Player,
		px: any,
		py: any,
		pz: any,
		lx: any,
		ly: any,
		lz: any
	)
		if not cameraRaised then
			return
		end
		if typeof(px) ~= "number" or typeof(py) ~= "number" or typeof(pz) ~= "number" then
			return
		end
		if typeof(lx) ~= "number" or typeof(ly) ~= "number" or typeof(lz) ~= "number" then
			return
		end
		local phase = ride:GetAttribute("Phase")
		if phase ~= "ride" and phase ~= "stop" and phase ~= "haven" and phase ~= "intro" then
			return
		end
		if handsBusy() then
			showHint(Lines.CAMERA_BUSY, 2)
			return
		end
		local now = os.clock()
		if now < nextShotAt then
			return
		end
		if filmLeft <= 0 then
			showHint(Lines.CAMERA_OUT_OF_FILM, 2.5)
			return
		end

		filmLeft = Polaroid.clampFilm(filmLeft - 1)
		nextShotAt = now + Polaroid.SHUTTER_COOLDOWN
		ride:SetAttribute("PolaroidFlash", workspace:GetServerTimeNow())

		local camPos = Vector3.new(px, py, pz)
		local lookDir = Vector3.new(lx, ly, lz)
		local framed: { string } = {}
		local liveIds: { string } = {}

		-- Poster tell has no mesh: any shot while it is live frames it.
		if posterLive then
			table.insert(liveIds, "poster_changed")
			table.insert(framed, "poster_changed")
		end
		for _, id in {
			AnomalySystem.ANNOUNCE_ID,
			AnomalySystem.COUNTDOWN_ID,
			AnomalySystem.EXTRA_ID,
			AnomalySystem.STICKER_ID,
			AnomalySystem.MAP_ID,
			AnomalySystem.NEARWORD_ID,
			AnomalySystem.LIGHT_ID,
			AnomalySystem.EMPTY_ID,
			AnomalySystem.MOVED_ID,
			AnomalySystem.FACETURN_ID,
			AnomalySystem.MOMFACE_ID,
		} do
			local model = car.passengers:FindFirstChild(id)
			if
				model ~= nil
				and model:IsA("Model")
				and model:GetAttribute("Anomaly") == true
				and model:GetAttribute("Hidden") ~= true
			then
				table.insert(liveIds, id)
				local at = model:GetPivot().Position
				if Polaroid.inFrame(camPos, lookDir, at, Constants.STUDS_PER_METER) then
					table.insert(framed, id)
				end
			end
		end

		photoSeq += 1
		local stopLabel = ""
		local stopAttr = ride:GetAttribute("NextStop")
		if typeof(stopAttr) == "string" then
			stopLabel = stopAttr
		end
		local photo: Polaroid.Photo = {
			id = string.format("p%d", photoSeq),
			stop = stopLabel,
			framed = framed,
			developed = false,
		}
		table.insert(polaroidPhotos, 1, photo)
		while #polaroidPhotos > 16 do
			table.remove(polaroidPhotos)
		end

		-- Privately marks the stop as noticed; no on-screen Caught (web photo path).
		if phase == "ride" and Polaroid.photoCatches(framed, liveIds) then
			caught = true
			stopNoticed = true
			for _, id in framed do
				anomalyTypesSeen[id] = true
				local kind = if id == AnomalySystem.EXTRA_ID
					then "extra"
					elseif id == AnomalySystem.MOVED_ID then "moved"
					elseif id == AnomalySystem.FACETURN_ID then "faceturn"
					elseif id == AnomalySystem.MOMFACE_ID then "momface"
					else id
				PsychLog.markCaught(psychLog, kind, stopLabel)
			end
			anomalyTypesSeen["photo"] = true
			applySuspicion(Score.flagDelta(true, true, Constants.FALSE_ALARM_SUSPICION, Constants.CORRECT_FLAG_SUSPICION))
		end

		if phase == "ride" or phase == "stop" then
			local bandAttr = ride:GetAttribute("Band")
			local band = if typeof(bandAttr) == "string" then bandAttr else "calm"
			if Polaroid.flashWatched(band) then
				applySuspicion(Polaroid.FLASH_WATCH_SUSPICION)
				showHint(Lines.CAMERA_FLASH_WATCH, 2.5)
			elseif math.random() < Polaroid.FLASH_GLANCE_CHANCE then
				ride:SetAttribute("FlashGlance", workspace:GetServerTimeNow())
			end
		end

		publishCamera()
	end)

	publishBand()

	task.spawn(function()
		while ride.Parent ~= nil do
			task.wait(Constants.UNEASY_TUBE_EVERY)
			if ride:GetAttribute("Band") == "uneasy" and ride:GetAttribute("Phase") == "ride" then
				blinkBandTube()
			end
		end
	end)

	local function playerNearDoors(): boolean
		local range = Constants.meters(Constants.FALSE_STOP_DOOR_RANGE_M)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
			if root ~= nil and root:IsA("BasePart") then
				for _, leaf in car.doors do
					local part = leaf.model.PrimaryPart
					if part ~= nil and (part.Position - root.Position).Magnitude <= range then
						return true
					end
				end
			end
		end
		return false
	end

	-- True when the player stands near an open door leaf during a false-stop dwell.
	local function playerReactedAtFalseStop(): boolean
		return falseStopReacted
	end

	-- Passenger, on purpose. The player cannot close doors or dispatch.
	-- EARLY_DEPARTURE_SUSPICION stays unused; no fail state.
	local function playerAskedToDepartEarly(): boolean
		return false
	end

	local function parentsAlert(): boolean
		local bandAttr = ride:GetAttribute("Band")
		if bandAttr == "watched" or bandAttr == "hunted" then
			return true
		end
		local scale = ride:GetAttribute("StareIntervalScale")
		if typeof(scale) == "number" and scale > 1 and (bandAttr == "uneasy" or bandAttr == "watched" or bandAttr == "hunted") then
			return true
		end
		return false
	end

	local function anomalyKindForId(passengerId: string): string?
		local model = car.passengers:FindFirstChild(passengerId)
		if model == nil or not model:IsA("Model") then
			return nil
		end
		if model:GetAttribute("Hidden") == true then
			return nil
		end
		local tell = model:GetAttribute("Tell")
		if typeof(tell) == "string" then
			return tell
		end
		if model:GetAttribute("Anomaly") == true then
			if passengerId == AnomalySystem.EXTRA_ID then
				return "extra"
			end
			if passengerId == AnomalySystem.MOVED_ID then
				return "moved"
			end
			if passengerId == AnomalySystem.FACETURN_ID then
				return "faceturn"
			end
			if passengerId == AnomalySystem.MOMFACE_ID then
				return "momface"
			end
			return "extra"
		end
		return nil
	end

	local function processGaze(dt: number)
		local phase = ride:GetAttribute("Phase")
		if phase ~= "ride" and phase ~= "stop" then
			return
		end
		local id = gazeTarget
		if id == nil then
			return
		end
		gazeSince += dt
		local scaleAttr = ride:GetAttribute("StareIntervalScale")
		local scale = if typeof(scaleAttr) == "number" then scaleAttr else 1
		local anomalyNeed = Constants.STARE_ANOMALY_SECONDS / math.max(1, scale)
		local parentNeed = Constants.STARE_PARENT_SECONDS / math.max(1, scale)
		if id == "mom" or id == "dad" then
			if not stareParentCharged and gazeSince >= parentNeed then
				stareParentCharged = true
				applySuspicion(Score.stareDelta(true, Constants.STARE_PARENT_SUSPICION))
				showHint(Lines.STARE_PARENT, 2.2)
			end
			return
		end
		if not parentsAlert() or stareAnomalyCharged then
			return
		end
		local kind = anomalyKindForId(id)
		if kind == nil then
			return
		end
		if gazeSince >= anomalyNeed then
			stareAnomalyCharged = true
			applySuspicion(Score.stareDelta(true, Constants.STARE_ANOMALY_SUSPICION))
			showHint(Lines.STARE_CAUGHT, 2.4)
			local stopLabel = ""
			local stopAttr = ride:GetAttribute("NextStop")
			if typeof(stopAttr) == "string" then
				stopLabel = stopAttr
			end
			PsychLog.markSeen(psychLog, kind, stopLabel)
		end
	end

	RunService.Heartbeat:Connect(function(dt: number)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
			if root ~= nil and root:IsA("BasePart") then
				local userId = player.UserId
				if hasRootPos[userId] then
					local previous = lastRootPos[userId]
					stretchMovedM += (root.Position - previous).Magnitude / Constants.STUDS_PER_METER
				end
				hasRootPos[userId] = true
				lastRootPos[userId] = root.Position
			end
		end
		if falseStopOpen and not falseStopReacted and playerNearDoors() then
			falseStopReacted = true
			showHint(Lines.FALSE_STOP_REACT, 2.4)
		end
		processGaze(dt)
	end)

	local function beginDwell(seconds: number)
		ride:SetAttribute("DwellUntil", workspace:GetServerTimeNow() + seconds)
	end

	local function endDwell()
		ride:SetAttribute("DwellUntil", 0)
	end

	local function resolveDeparture(elapsedOpen: number)
		suspicion = Dwell.departureSuspicion(
			suspicion,
			elapsedOpen,
			Constants.MIN_DWELL_SECONDS,
			playerAskedToDepartEarly(),
			Constants.EARLY_DEPARTURE_SUSPICION,
			Constants.SUSPICION_MIN,
			Constants.SUSPICION_MAX
		)
		ride:SetAttribute("Suspicion", suspicion)
	end

	local function setTell(id: string, active: boolean)
		local model = car.passengers:FindFirstChild(id)
		if model == nil or not model:IsA("Model") then
			return
		end
		model:SetAttribute("Anomaly", active)
		model:SetAttribute("Hidden", not active)
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") and desc.Name ~= "Root" then
				desc.Transparency = if active then 0 else 1
				desc.CanQuery = active
				desc.Color = if active then Constants.COLOR.warn else Constants.COLOR.dark
			end
		end
	end

	local lighttempStrip: BasePart? = nil
	local lighttempOriginal: Color3? = nil
	local movedHome: CFrame? = nil
	local emptyHidden: { string } = {}
	local faceturnRest: { [BasePart]: CFrame } = {}
	local momfaceRest: { [BasePart]: Color3 } = {}

	local function setPlateText(id: string, text: string)
		local model = car.passengers:FindFirstChild(id)
		if model == nil then
			return
		end
		for _, desc in model:GetDescendants() do
			if desc:IsA("TextLabel") and desc.Name == "Text" then
				desc.Text = text
				return
			end
		end
	end

	local function setCatalogHidden(id: string, active: boolean, color: Color3?)
		local model = car.passengers:FindFirstChild(id)
		if model == nil or not model:IsA("Model") then
			return
		end
		model:SetAttribute("Anomaly", active)
		model:SetAttribute("Hidden", not active)
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") and desc.Name ~= "Root" then
				desc.Transparency = if active then 0 else 1
				desc.CanQuery = active
				if color ~= nil and active then
					desc.Color = color
				elseif not active then
					desc.Color = Constants.COLOR.dark
				end
			end
		end
	end

	local function setCatalogVisible(id: string, active: boolean)
		local model = car.passengers:FindFirstChild(id)
		if model == nil or not model:IsA("Model") then
			return
		end
		model:SetAttribute("Anomaly", active)
		model:SetAttribute("Hidden", false)
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") and desc.Name ~= "Root" then
				desc.CanQuery = true
			end
		end
	end

	local function clearCatalog()
		setCatalogHidden(AnomalySystem.STICKER_ID, false, nil)
		setCatalogHidden(AnomalySystem.LIGHT_ID, false, nil)
		setCatalogHidden(AnomalySystem.EMPTY_ID, false, nil)
		setCatalogVisible(AnomalySystem.MAP_ID, false)
		setPlateText(AnomalySystem.MAP_ID, Lines.MAP_NORMAL)
		setCatalogVisible(AnomalySystem.NEARWORD_ID, false)
		setPlateText(AnomalySystem.NEARWORD_ID, Lines.AD_NORMAL)
		if lighttempStrip ~= nil and lighttempOriginal ~= nil then
			lighttempStrip.Color = lighttempOriginal
			stripHold[lighttempStrip] = nil
		end
		lighttempStrip = nil
		lighttempOriginal = nil
		local moved = car.passengers:FindFirstChild(AnomalySystem.MOVED_ID)
		if moved ~= nil and moved:IsA("Model") then
			moved:SetAttribute("Anomaly", false)
			if movedHome ~= nil then
				moved:PivotTo(movedHome)
			end
		end
		movedHome = nil
		for _, id in emptyHidden do
			CarBuilder.setPassengerShown(car.passengers, id, true)
		end
		table.clear(emptyHidden)
		local s2 = car.passengers:FindFirstChild(AnomalySystem.FACETURN_ID)
		if s2 ~= nil and s2:IsA("Model") then
			s2:SetAttribute("Anomaly", false)
			for part, cf in faceturnRest do
				part.CFrame = cf
			end
		end
		table.clear(faceturnRest)
		local mom = car.passengers:FindFirstChild(AnomalySystem.MOMFACE_ID)
		if mom ~= nil and mom:IsA("Model") then
			mom:SetAttribute("Anomaly", false)
			for part, color in momfaceRest do
				part.Color = color
			end
		end
		table.clear(momfaceRest)
	end

	local function applyLighttemp()
		local stripName = "LightStrip_02"
		local lightModel = car.passengers:FindFirstChild(AnomalySystem.LIGHT_ID)
		if lightModel ~= nil then
			local named = lightModel:GetAttribute("StripName")
			if typeof(named) == "string" then
				stripName = named
			end
		end
		for _, lamp in car.lamps do
			if lamp.part.Name == stripName then
				lighttempStrip = lamp.part
				lighttempOriginal = lamp.part.Color
				stripHold[lamp.part] = true
				lamp.part.Color = Constants.LIGHTTEMP_COLOR
				break
			end
		end
		setCatalogHidden(AnomalySystem.LIGHT_ID, true, Constants.LIGHTTEMP_COLOR)
	end

	local function applySticker()
		setCatalogHidden(AnomalySystem.STICKER_ID, true, Color3.fromRGB(240, 210, 40))
	end

	local function applyNearword()
		setCatalogVisible(AnomalySystem.NEARWORD_ID, true)
		setPlateText(AnomalySystem.NEARWORD_ID, Lines.AD_WARP)
	end

	local function applyMapstop()
		setCatalogVisible(AnomalySystem.MAP_ID, true)
		setPlateText(AnomalySystem.MAP_ID, Lines.MAP_HOLLOW)
	end

	local function applyMoved()
		local model = car.passengers:FindFirstChild(AnomalySystem.MOVED_ID)
		if model == nil or not model:IsA("Model") then
			return
		end
		movedHome = model:GetPivot()
		model:SetAttribute("Anomaly", true)
		local pivot = model:GetPivot()
		local at = pivot.Position
		-- Keep facing; only slide along the car X (web s3 → far doors).
		model:PivotTo(CFrame.new(Constants.meters(Constants.MOVED_FAR_X), at.Y, at.Z) * (pivot - pivot.Position))
	end

	local function applyEmpty()
		for _, id in { "s1", "s2", "s3", AnomalySystem.EXTRA_ID, "c1", "c2", "c3", "c4", "c5" } do
			local model = car.passengers:FindFirstChild(id)
			if model ~= nil and model:GetAttribute("Hidden") ~= true then
				table.insert(emptyHidden, id)
				CarBuilder.setPassengerShown(car.passengers, id, false)
			end
		end
		setCatalogHidden(AnomalySystem.EMPTY_ID, true, Constants.COLOR.warn)
	end

	local function applyFaceturn()
		local model = car.passengers:FindFirstChild(AnomalySystem.FACETURN_ID)
		if model == nil or not model:IsA("Model") then
			return
		end
		model:SetAttribute("Anomaly", true)
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") and (desc.Name == "Head" or desc.Name == "Hair" or desc.Name == "Eye") then
				faceturnRest[desc] = desc.CFrame
				desc.CFrame = desc.CFrame * CFrame.Angles(0, 0, math.rad(55))
			end
		end
	end

	local function applyMomface()
		local model = car.passengers:FindFirstChild(AnomalySystem.MOMFACE_ID)
		if model == nil or not model:IsA("Model") then
			return
		end
		model:SetAttribute("Anomaly", true)
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") and (desc.Name == "Head" or desc.Name == "Hair" or desc.Name == "Eye") then
				momfaceRest[desc] = desc.Color
				if desc.Name == "Eye" then
					desc.Color = Color3.fromRGB(20, 20, 28)
				else
					desc.Color = Color3.fromRGB(223, 217, 206)
				end
			end
		end
	end

	local function applyCatalog(kind: string)
		if kind == "lighttemp" then
			applyLighttemp()
		elseif kind == "sticker" then
			applySticker()
		elseif kind == "nearword" then
			applyNearword()
		elseif kind == "mapstop" then
			applyMapstop()
		elseif kind == "moved" then
			applyMoved()
		elseif kind == "empty" then
			applyEmpty()
		elseif kind == "faceturn" then
			applyFaceturn()
		elseif kind == "momface" then
			applyMomface()
		end
	end

	local function clearTells()
		setTell(AnomalySystem.ANNOUNCE_ID, false)
		setTell(AnomalySystem.COUNTDOWN_ID, false)
		clearCatalog()
		ride:SetAttribute("BoardStop", "")
		ride:SetAttribute("BoardMinutes", 0)
	end

	local function anomalyLive(): boolean
		if posterLive then
			return true
		end
		for _, id in {
			AnomalySystem.ANNOUNCE_ID,
			AnomalySystem.COUNTDOWN_ID,
			AnomalySystem.EXTRA_ID,
			AnomalySystem.STICKER_ID,
			AnomalySystem.MAP_ID,
			AnomalySystem.NEARWORD_ID,
			AnomalySystem.LIGHT_ID,
			AnomalySystem.EMPTY_ID,
			AnomalySystem.MOVED_ID,
			AnomalySystem.FACETURN_ID,
			AnomalySystem.MOMFACE_ID,
		} do
			local model = car.passengers:FindFirstChild(id)
			if model ~= nil and model:GetAttribute("Anomaly") == true and model:GetAttribute("Hidden") ~= true then
				return true
			end
		end
		return false
	end

	local function clearExtra()
		CarBuilder.setPassengerShown(car.passengers, AnomalySystem.EXTRA_ID, false)
	end

	local function stopWord(kind: string): (string, string)
		if kind == "noticed" then
			return "caught", Lines.CAUGHT
		end
		if kind == "missed" then
			return "missed", Lines.MISSED
		end
		if kind == "false" then
			return "false", Lines.FALSE_FLAG
		end
		return "clean", Lines.CLEAN
	end

	local pendingDoorChoice: string? = nil
	local choiceEpoch = 0
	local pendingMaskChoice: string? = nil
	local maskEpoch = 0
	local pendingTrialChoice: number? = nil
	local trialEpoch = 0

	doorsRemote.OnServerEvent:Connect(function(_player: Player, choice: any)
		if ride:GetAttribute("ChoiceActive") ~= true then
			return
		end
		if typeof(choice) ~= "string" then
			return
		end
		if choice ~= "stay" and choice ~= "off" then
			return
		end
		pendingDoorChoice = choice
	end)

	maskRemote.OnServerEvent:Connect(function(_player: Player, choice: any)
		if ride:GetAttribute("MaskActive") ~= true then
			return
		end
		if typeof(choice) ~= "string" then
			return
		end
		if choice ~= "A" and choice ~= "B" and choice ~= "C" then
			return
		end
		pendingMaskChoice = choice
	end)

	trialRemote.OnServerEvent:Connect(function(_player: Player, choice: any)
		if ride:GetAttribute("TrialActive") ~= true then
			return
		end
		if typeof(choice) ~= "number" then
			return
		end
		if choice ~= 0 and choice ~= 1 and choice ~= 2 then
			return
		end
		pendingTrialChoice = choice
	end)

	local function waitForDoorChoice(seconds: number): string
		choiceEpoch += 1
		local epoch = choiceEpoch
		pendingDoorChoice = nil
		ride:SetAttribute("ChoiceActive", true)
		ride:SetAttribute("ChoiceUntil", workspace:GetServerTimeNow() + seconds)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and pendingDoorChoice == nil and epoch == choiceEpoch do
			task.wait(0.05)
		end
		ride:SetAttribute("ChoiceActive", false)
		ride:SetAttribute("ChoiceUntil", 0)
		return Doors.normalize(pendingDoorChoice)
	end

	local function clearMaskUi()
		ride:SetAttribute("MaskActive", false)
		ride:SetAttribute("MaskUntil", 0)
		ride:SetAttribute("MaskA", "")
		ride:SetAttribute("MaskB", "")
		ride:SetAttribute("MaskC", "")
	end

	local function waitForMaskChoice(seconds: number, answers: { { text: string, val: string } }): string?
		maskEpoch += 1
		local epoch = maskEpoch
		pendingMaskChoice = nil
		ride:SetAttribute("MaskA", answers[1].text)
		ride:SetAttribute("MaskB", answers[2].text)
		ride:SetAttribute("MaskC", answers[3].text)
		ride:SetAttribute("MaskActive", true)
		ride:SetAttribute("MaskUntil", workspace:GetServerTimeNow() + seconds)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and pendingMaskChoice == nil and epoch == maskEpoch do
			if ride:GetAttribute("Phase") ~= "ride" then
				break
			end
			task.wait(0.05)
		end
		local picked = pendingMaskChoice
		clearMaskUi()
		if picked == nil then
			return nil
		end
		local index = if picked == "A" then 1 elseif picked == "B" then 2 else 3
		return answers[index].val
	end

	local function clearTrialUi()
		ride:SetAttribute("TrialActive", false)
		ride:SetAttribute("TrialUntil", 0)
		ride:SetAttribute("TrialA", "")
		ride:SetAttribute("TrialB", "")
		ride:SetAttribute("TrialC", "")
		ride:SetAttribute("TrialSlots", 0)
	end

	local function waitForTrialChoice(seconds: number, items: { Trial.ChoiceItem }): number?
		trialEpoch += 1
		local epoch = trialEpoch
		pendingTrialChoice = nil
		ride:SetAttribute("TrialA", items[1].text)
		ride:SetAttribute("TrialB", if items[2] then items[2].text else "")
		ride:SetAttribute("TrialC", if items[3] then items[3].text else "")
		ride:SetAttribute("TrialSlots", #items)
		ride:SetAttribute("TrialActive", true)
		if seconds > 0 then
			ride:SetAttribute("TrialUntil", workspace:GetServerTimeNow() + seconds)
		else
			ride:SetAttribute("TrialUntil", 0)
		end
		local deadline = if seconds > 0 then os.clock() + seconds else math.huge
		while os.clock() < deadline and pendingTrialChoice == nil and epoch == trialEpoch do
			if ride:GetAttribute("Phase") ~= "trial" then
				break
			end
			task.wait(0.05)
		end
		local picked = pendingTrialChoice
		clearTrialUi()
		return picked
	end

	local segToken = 0

	local function runTrial(token: number, stopName: string, stopNumber: number): boolean
		table.insert(trialStops, stopNumber)
		ride:SetAttribute("Phase", "trial")
		clearMaskUi()
		TrialSpace.setVisible(trialSpace.model, true)
		TrialSpace.teleportPlayers(trialSpace.spawn)
		showHint(Lines.TRIAL_HINT, Constants.TRIAL_HINT_SECONDS)

		local state = Trial.start(stopName)
		local rng = function()
			return math.random()
		end
		local clean = false

		while token == segToken do
			local roundState, view = Trial.round(state, rng)
			state = roundState
			TrialSpace.applyRound(trialSpace, view.signs, view.boardDoors)

			local cycleAt = os.clock()
			local events = Trial.cycleEvents(state, rng)
			local eventDone: { [number]: boolean } = {}
			ride:SetAttribute("TrialChime", workspace:GetServerTimeNow())

			local conn = RunService.Heartbeat:Connect(function(dt: number)
				if ride:GetAttribute("Phase") ~= "trial" then
					return
				end
				local elapsed = os.clock() - cycleAt
				if elapsed >= Constants.TRIAL_CYCLE then
					cycleAt = os.clock()
					events = Trial.cycleEvents(state, rng)
					eventDone = {}
					ride:SetAttribute("TrialChime", workspace:GetServerTimeNow())
					elapsed = 0
				end
				for i, event in events do
					if eventDone[i] ~= true and elapsed >= event.at then
						eventDone[i] = true
						local opening = trialSpace.openings[event.index + 1]
						if opening ~= nil then
							if event.kind == "flick" then
								TrialSpace.flick(opening, os.clock() + Constants.TRIAL_FLICK_SECONDS)
							elseif event.kind == "open" then
								TrialSpace.setDoorTarget(opening, 1)
							else
								TrialSpace.setDoorTarget(opening, 0)
							end
						end
					end
				end
				TrialSpace.step(trialSpace, dt, os.clock())
			end)

			local picked = waitForTrialChoice(view.windowSeconds, view.items)
			conn:Disconnect()
			if token ~= segToken then
				break
			end

			task.wait(0.7)
			if token ~= segToken then
				break
			end
			local result = Trial.applyPick(state, picked)
			state = result.state
			if result.subtitle ~= "" then
				showSub(result.subtitle, 3.0)
				task.wait(1.2)
			end
			if result.kind == "exit" then
				clean = result.clean == true
				break
			end
		end

		clearTrialUi()
		TrialSpace.setVisible(trialSpace.model, false)
		TrialSpace.teleportPlayers(carReturn)
		applySuspicion(Constants.TRIAL_EXIT_SUSPICION)
		applySanity(-Constants.TRIAL_SANITY)
		ride:SetAttribute("Phase", "stop")
		if clean then
			showSub(Lines.MOM_TRIAL_CLEAN, 3.4)
		else
			showSub(Lines.MOM_TRIAL_ROUGH, 3.4)
		end
		task.wait(3.6)
		if token ~= segToken then
			return false
		end
		showSub(Lines.DAD_TRIAL_SIT, 2.6)
		task.wait(2.8)
		return token == segToken
	end

	local function runMaskCheck(token: number)
		if maskBusy or token ~= segToken then
			return
		end
		if ride:GetAttribute("Phase") ~= "ride" then
			return
		end
		if ride:GetAttribute("ChoiceActive") == true then
			return
		end
		if ride:GetAttribute("RestraintActive") == true or ride:GetAttribute("Intervening") == true then
			return
		end
		local bandAttr = ride:GetAttribute("Band")
		local bandName = if typeof(bandAttr) == "string" then bandAttr else "calm"
		local pool = Dialogue.maskPoolForBand(bandName, suspicion, Constants.MASK_NEED_SUSPICION)
		local line = Dialogue.pickMask(pool, maskUsed, maskLast, function()
			return math.random()
		end)
		if line == nil then
			return
		end
		maskBusy = true
		maskUsed[line.line] = true
		maskLast = line.line
		showSub(Dialogue.maskPrompt(line.who, line.line), Constants.MASK_PROMPT_SECONDS)
		local answers = Dialogue.shuffleAnswers(line.calm, line.off[1], line.off[2], function()
			return math.random()
		end)
		local val = waitForMaskChoice(Constants.MASK_CHOICE_SECONDS, answers)
		if token ~= segToken then
			maskBusy = false
			return
		end
		if val == nil then
			applySuspicion(Constants.MASK_TIMEOUT_SUSPICION)
			applySanity(-Constants.MASK_TIMEOUT_SANITY)
			showSub(Dialogue.maskHesitate(line.who), 2.6)
		elseif val == "calm" then
			showSub(Dialogue.youAnswer(line.calm, line.who), 2.4)
		else
			applySuspicion(Constants.MASK_FAIL_SUSPICION)
			applySanity(-Constants.MASK_FAIL_SANITY)
			showSub(Dialogue.maskOdd(line.who), 2.8)
		end
		maskBusy = false
	end

	-- Single-car slice: one shared gaze (same as Flag / Meta). Only the
	-- ride owner (metaUserId, else first player) may update it. The id must
	-- name a real passenger model that is not Hidden.
	gazeRemote.OnServerEvent:Connect(function(player: Player, passengerId: any)
		local phase = ride:GetAttribute("Phase")
		if phase ~= "ride" and phase ~= "stop" and phase ~= "haven" then
			gazeTarget = nil
			gazeSince = 0
			return
		end
		local owner = metaUserId
		if owner == nil then
			local list = Players:GetPlayers()
			if #list > 0 then
				owner = list[1].UserId
			end
		end
		if owner == nil or player.UserId ~= owner then
			return
		end
		local id: string? = nil
		if typeof(passengerId) == "string" and passengerId ~= "" then
			local model = car.passengers:FindFirstChild(passengerId)
			if model ~= nil and model:IsA("Model") and model:GetAttribute("Hidden") ~= true then
				id = passengerId
			end
		end
		if id ~= gazeTarget then
			gazeTarget = id
			gazeSince = 0
		end
	end)

	flagRemote.OnServerEvent:Connect(function(player: Player, passengerId: any)
		if typeof(passengerId) ~= "string" then
			return
		end
		if ride:GetAttribute("Phase") ~= "ride" then
			return
		end
		if ride:GetAttribute("RestraintActive") == true or ride:GetAttribute("Intervening") == true then
			return
		end
		if flagged[passengerId] then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") then
			return
		end
		local model = car.passengers:FindFirstChild(passengerId)
		if model == nil or not model:IsA("Model") then
			return
		end
		if model:GetAttribute("Hidden") == true then
			return
		end
		local offset = model:GetPivot().Position - root.Position
		local horizontal = Vector3.new(offset.X, 0, offset.Z)
		-- In the car. The client crosshair picks who; this only rejects a flag
		-- fired from outside the car. Body facing lags the camera, so it is
		-- not used as a second gaze test.
		if horizontal.Magnitude > Constants.meters(Constants.FLAG_RANGE_M) then
			return
		end

		flagged[passengerId] = true
		local labelAttr = model:GetAttribute("Label")
		local label = if typeof(labelAttr) == "string" then labelAttr else passengerId
		local tellKind = model:GetAttribute("Tell")
		local isTell = typeof(tellKind) == "string"
		local marked = model:GetAttribute("Anomaly") == true
		local verdict = AnomalySystem.verdict(marked and not isTell, isTell, marked)
		local live = anomalyLive()
		if verdict == "noticed" then
			caught = true
			stopNoticed = true
			local catchId = if isTell and typeof(tellKind) == "string" then tellKind else "extra"
			if isTell and typeof(tellKind) == "string" then
				anomalyTypesSeen[tellKind] = true
			elseif marked then
				anomalyTypesSeen["extra"] = true
			end
			local stopLabel = ""
			local stopAttr = ride:GetAttribute("NextStop")
			if typeof(stopAttr) == "string" then
				stopLabel = stopAttr
			end
			PsychLog.markCaught(psychLog, catchId, stopLabel)
			showFeedback("caught", Lines.CAUGHT, false)
		else
			falseFlags += 1
			showFeedback("false", Lines.falseFlag(label), false)
			if not live then
				stopFalseAlarm = true
			end
		end
		applySuspicion(Score.flagDelta(verdict == "noticed", live, Constants.FALSE_ALARM_SUSPICION, Constants.CORRECT_FLAG_SUSPICION))
	end)

	local function tapeIds(): { string }
		local ids = {}
		for _, tape in evpState.tapes do
			table.insert(ids, tape.signalId)
		end
		return ids
	end

	local function waitForExitChoice(seconds: number): Endings.ExitChoice
		exitEpoch += 1
		local epoch = exitEpoch
		pendingExitChoice = nil
		ride:SetAttribute("ExitActive", true)
		ride:SetAttribute("ExitUntil", workspace:GetServerTimeNow() + seconds)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and pendingExitChoice == nil and epoch == exitEpoch do
			task.wait(0.05)
		end
		ride:SetAttribute("ExitActive", false)
		ride:SetAttribute("ExitUntil", 0)
		return Endings.normalizeExit(pendingExitChoice)
	end

	local function publishReport(def: Endings.EndingDefinition, summary: Endings.EndingSummary)
		ride:SetAttribute("EndingId", def.id)
		ride:SetAttribute("EndingTitle", def.title)
		ride:SetAttribute("EndingBadge", def.badge)
		ride:SetAttribute("EndingNarrative", def.narrative)
		local restraintLine = if summary.restraintOK then "held" else "failed / skipped"
		local modeLine = if practiceOn
			then "Mode             PRACTICE (nothing saved)"
			elseif nightmareOn then "Mode             NIGHTMARE"
			else "Mode             Standard"
		local stats = table.concat({
			modeLine,
			"Sanity Retained  " .. tostring(summary.sanPct) .. "%",
			"Peak Suspicion   " .. tostring(summary.peak),
			"Anomaly Accuracy " .. tostring(summary.accPct) .. "%  (" .. tostring(accCorrect) .. "/" .. tostring(
				accCorrect + accMiss
			) .. ")",
			"Interventions    " .. tostring(summary.interventions),
			"Trials           " .. tostring(#summary.trialStops),
			"Restraint        " .. restraintLine,
			"Tapes            " .. tostring(#summary.tapes),
			"Exit             " .. summary.exit,
			"False flags      " .. tostring(falseFlags),
		}, "\n")
		ride:SetAttribute("ReportStats", stats)
		ride:SetAttribute("ReportPsych", PsychLog.formatReport(psychLog))
		ride:SetAttribute("ReportReady", true)
	end

	local function formatArchive(data: MetaStore.Save): string
		local endingCount = 0
		for _ in data.endings do
			endingCount += 1
		end
		local lines = {
			"CASE FILES",
			"Runs " .. tostring(data.runsCompleted),
			"Endings " .. tostring(endingCount),
			"Achievements " .. tostring(Achievements.count(data.achievements)),
			"Tapes " .. tostring(#data.tapes),
			"Album " .. tostring(#data.album),
		}
		for _, id in Achievements.IDS do
			if Achievements.has(data.achievements, id) then
				table.insert(lines, "• " .. Achievements.definition(id).title)
			end
		end
		for id, entry in data.endings do
			table.insert(lines, "◇ " .. id .. " ×" .. tostring(entry.count))
		end
		return table.concat(lines, "\n")
	end

	local function refreshMetaPublish()
		local uid = metaUserId
		if uid == nil then
			local list = Players:GetPlayers()
			if #list > 0 then
				uid = list[1].UserId
				metaUserId = uid
			end
		end
		if uid == nil then
			ride:SetAttribute("NightmareUnlocked", false)
			ride:SetAttribute("MetaArchive", "CASE FILES\n(no player yet)")
			return
		end
		local data = MetaStore.load(uid)
		ride:SetAttribute("NightmareUnlocked", data.nightmareUnlocked or data.runsCompleted > 0)
		ride:SetAttribute("MetaArchive", formatArchive(data))
	end

	-- Single-car slice: one shared ride. Progress belongs to metaUserId
	-- (whoever fired MetaStart / MetaAgain). Fallback is first player only.
	local function persistMeta(def: Endings.EndingDefinition)
		if Practice.offRecord(practiceOn, false) then
			return
		end
		local uid = metaUserId
		if uid == nil then
			local list = Players:GetPlayers()
			if #list == 0 then
				return
			end
			uid = list[1].UserId
			metaUserId = uid
		end
		local data = MetaStore.load(uid)
		data.runsCompleted += 1
		data.nightmareUnlocked = true
		MetaStore.recordEnding(data, def.id, os.time())
		local tapes: { MetaStore.TapeEntry } = {}
		for _, tape in evpState.tapes do
			table.insert(tapes, {
				signalId = tape.signalId,
				title = tape.title,
				stop = tape.stop,
				freq = tape.freq,
				transcript = tape.transcript,
			})
		end
		MetaStore.mergeTapes(data, tapes, Constants.META_TAPE_ARCHIVE_MAX)
		local album: { MetaStore.PhotoEntry } = {}
		for _, photo in polaroidPhotos do
			table.insert(album, { id = photo.id, framed = photo.framed })
		end
		MetaStore.mergeAlbum(data, album, Constants.META_ALBUM_ARCHIVE_MAX)
		for id in anomalyTypesSeen do
			data.anomalyTypes[id] = true
		end
		local now = os.time()
		if peakSuspicion == 0 then
			Achievements.unlock(data.achievements, "iron_composure", now, false)
		end
		if def.id ~= "civilian_extraction" then
			Achievements.unlock(data.achievements, "loop_breaker", now, false)
		end
		if accCorrect > 0 then
			Achievements.unlock(data.achievements, "first_anomaly", now, false)
		end
		if anomalyTypesSeen["photo"] == true then
			Achievements.unlock(data.achievements, "photo_evidence", now, false)
		end
		if #evpState.tapes >= 3 then
			Achievements.unlock(data.achievements, "tuning_pro", now, false)
		end
		for _, tape in evpState.tapes do
			if string.sub(tape.signalId, 1, 8) == "station-" then
				Achievements.unlock(data.achievements, "broadcaster_lore", now, false)
				break
			end
		end
		if trestleBadgeChecked then
			Achievements.unlock(data.achievements, "trestle_cross", now, false)
		end
		local documented = 0
		for _ in data.anomalyTypes do
			documented += 1
		end
		if documented >= 6 then
			Achievements.unlock(data.achievements, "master_archivist", now, false)
		end
		MetaStore.save(uid, data)
		refreshMetaPublish()
	end

	local function finishScore()
		local miss = if caught then 0 else 1
		local kind = if caught then "caught" else "missed"
		local word = if caught then Lines.CAUGHT else Lines.MISSED
		showFeedback(kind, word, true)
		showSub(Lines.scoreLine(miss, falseFlags), 8)
	end

	local function endGameAtCourtSq()
		sampleSanity()
		finalExit = waitForExitChoice(Constants.EXIT_CHOICE_SECONDS)
		showSub(Endings.exitLine(finalExit), 3.0)
		task.wait(3.2)
		local summary: Endings.EndingSummary = {
			peak = peakSuspicion,
			interventions = interventions,
			trialStops = trialStops,
			sanPct = Sanity.retainedPercent(sanSamples),
			accPct = Endings.accuracyPercent(accCorrect, accMiss),
			restraintOK = restraintOK,
			tapes = tapeIds(),
			exit = finalExit,
		}
		-- No hard fail at suspicion 100: resolveEnding never invents one.
		local def = Endings.resolve(summary)
		finishScore()
		publishReport(def, summary)
		persistMeta(def)
		ride:SetAttribute("Phase", "end")
		ride:SetAttribute("NextStop", Route.stopName(13))
	end

	-- One named tube, on and off. stripHold keeps applyLights from painting
	-- that tube. No other lamp is touched, and forcedOff is not set.
	local function blinkOneStrip(token: number, seconds: number)
		local deadline = os.clock() + seconds
		task.spawn(function()
			local dark = false
			while token == segToken and os.clock() < deadline do
				dark = not dark
				for _, lamp in car.lamps do
					if lamp.part.Name == Constants.HOLD_STRIP_NAME then
						if dark then
							stripHold[lamp.part] = true
							lamp.part.Color = Constants.COLOR.lightOff
						else
							stripHold[lamp.part] = nil
						end
						break
					end
				end
				task.wait(Constants.HOLD_BLINK)
			end
			for _, lamp in car.lamps do
				if lamp.part.Name == Constants.HOLD_STRIP_NAME then
					stripHold[lamp.part] = nil
					break
				end
			end
		end)
	end

	local function runSegment(seg: Route.Segment)
		segToken += 1
		local token = segToken
		currentSegStop = seg.stop
		ride:SetAttribute("SegStop", seg.stop)
		ride:SetAttribute("Phase", "ride")
		ride:SetAttribute("NextStop", Route.stopName(seg.stop))
		ride:SetAttribute("ChapterLine", Route.chapterLine(seg.stop))
		CarBuilder.setCrowd(car.passengers, seg.crowd)
		clearExtra()
		setDoorTarget(0)

		if not seg.b then
			sampleSanity()
		end
		bandStop = seg.stop
		applySanity(Nightmare.driftDelta(Sanity.driftForStop(seg.stop), nightmareOn))

		local cruiseLen = Nightmare.cruiseSeconds(seg.sliceCruise, nightmareOn)
		local length = Constants.ACCEL + cruiseLen + Constants.BRAKE
		inFinal = seg.final
		if seg.final and huntedDim then
			huntedDim = false
		end
		local held = Hold.applies(seg.stop, seg.b, seg.final, Constants.HOLD_STOP_A, Constants.HOLD_STOP_B)
			and Hold.placed(Constants.HOLD_AT, Constants.HOLD_SECONDS, Constants.ACCEL, cruiseLen)
		local holdAt = if held then Constants.HOLD_AT else 0
		local holdFor = if held then Constants.HOLD_SECONDS else 0
		beginStretch(seg, holdAt, holdFor)
		if seg.final then
			beginDim(Constants.FINAL_DIM, length)
		end

		local picked = AnomalySystem.pick(seg.stop, seg.b, {
			posterStop = Constants.ANOMALY_POSTER_STOP,
			extraStop = Constants.ANOMALY_EXTRA_STOP,
			announceStop = Constants.ANOMALY_ANNOUNCE_STOP,
			countdownStop = Constants.ANOMALY_COUNTDOWN_STOP,
			lighttempStop = Constants.ANOMALY_LIGHTTEMP_STOP,
			stickerStop = Constants.ANOMALY_STICKER_STOP,
			nearwordStop = Constants.ANOMALY_NEARWORD_STOP,
			mapstopStop = Constants.ANOMALY_MAPSTOP_STOP,
			movedStop = Constants.ANOMALY_MOVED_STOP,
			emptyStop = Constants.ANOMALY_EMPTY_STOP,
			faceturnStop = if Constants.ANOMALY_FACETURN_STOP > 0 then Constants.ANOMALY_FACETURN_STOP else nil,
			momfaceStop = if Constants.ANOMALY_MOMFACE_STOP > 0 then Constants.ANOMALY_MOMFACE_STOP else nil,
		})
		stopHadAnomaly = picked ~= nil
		stopNoticed = false
		stopFalseAlarm = false
		posterLive = false
		stareAnomalyCharged = false
		stareParentCharged = false
		gazeSince = 0
		stretchMovedM = 0
		table.clear(lastRootPos)
		table.clear(hasRootPos)
		if picked ~= nil then
			PsychLog.markSeen(psychLog, picked, Route.stopName(seg.stop))
		end
		clearCatalog()
		local wrongCountdown = picked == "wrong_countdown"
		setTell(AnomalySystem.COUNTDOWN_ID, wrongCountdown)
		setTell(AnomalySystem.ANNOUNCE_ID, false)
		ride:SetAttribute("BoardStop", Route.stopName(seg.stop))
		ride:SetAttribute(
			"BoardMinutes",
			AnomalySystem.boardMinutes(Constants.COUNTDOWN_MINUTES, Constants.WRONG_COUNTDOWN_MINUTES, wrongCountdown)
		)

		if not seg.silent then
			task.delay(Constants.NEXT_STOP_AT, function()
				if token ~= segToken then
					return
				end
				local actual = Route.stopName(seg.stop)
				local announced = actual
				if picked == "wrong_announcement" then
					announced = AnomalySystem.wrongStop(
						actual,
						Route.stopName(Constants.WRONG_ANNOUNCE_STOP),
						Route.stopName(Constants.WRONG_ANNOUNCE_FALLBACK_STOP)
					)
					setTell(AnomalySystem.ANNOUNCE_ID, true)
					task.delay(Constants.NEXT_STOP_FOR, function()
						if token ~= segToken then
							return
						end
						setTell(AnomalySystem.ANNOUNCE_ID, false)
					end)
				end
				showPa(Lines.nextStop(announced), Constants.NEXT_STOP_FOR)
			end)
		end
		if seg.kind == "haven" then
			local cueAt = math.max(Constants.NEXT_STOP_AT + 0.5, length - Haven.APPROACH_LEAD)
			task.delay(cueAt, function()
				if token ~= segToken or ride:GetAttribute("Phase") ~= "ride" then
					return
				end
				if ride:GetAttribute("MaskActive") == true then
					return
				end
				showSub(Lines.MOM_HAVEN_CUE, 3.2)
			end)
		end
		if Haven.shouldTrainHandoff(hasRecorder, seg.stop, seg.b) then
			task.delay(Haven.TRAIN_HANDOFF_AT, function()
				if token ~= segToken or ride:GetAttribute("Phase") ~= "ride" then
					return
				end
				giveRecorder("train")
			end)
		end
		local chatIndex = seg.chat
		if chatIndex ~= nil then
			local exchange = Dialogue.chatFor(chatPlan, chatIndex)
			task.delay(Constants.CHAT_AT_1, function()
				if token ~= segToken or ride:GetAttribute("Phase") ~= "ride" then
					return
				end
				if ride:GetAttribute("MaskActive") == true or ride:GetAttribute("ChoiceActive") == true then
					return
				end
				-- Hunted: swap in a band-tuned parent exchange.
				local bandAttr = ride:GetAttribute("Band")
				local use = exchange
				if bandAttr == "hunted" then
					use = Dialogue.huntedChat(function()
						return math.random()
					end)
				end
				if use == nil then
					return
				end
				local first = use[1]
				local second = use[2]
				showSub(Dialogue.chatLine(first.who, first.line), Constants.CHAT_LINE_SECONDS)
				task.delay(Constants.CHAT_AT_2 - Constants.CHAT_AT_1, function()
					if token ~= segToken or ride:GetAttribute("Phase") ~= "ride" then
						return
					end
					if ride:GetAttribute("MaskActive") == true or ride:GetAttribute("ChoiceActive") == true then
						return
					end
					showSub(Dialogue.chatLine(second.who, second.line), Constants.CHAT_LINE_SECONDS)
				end)
			end)
		end
		local maskTimes = seg.masks
		if maskTimes ~= nil then
			for _, at in maskTimes do
				task.delay(at, function()
					if token ~= segToken then
						return
					end
					runMaskCheck(token)
				end)
			end
		end
		if picked == "poster_changed" then
			task.delay(8, function()
				if token ~= segToken then
					return
				end
				for _, desc in car.model:GetDescendants() do
					if desc:IsA("BasePart") and string.sub(desc.Name, 1, 3) == "Ad_" and desc.Transparency < 0.5 then
						posterOriginal[desc] = desc.Color
						desc.Color = Color3.fromRGB(120, 36, 32)
						posterLive = true
						break
					end
				end
			end)
		end
		if picked == "extra" then
			task.delay(Constants.EXTRA_APPEAR_AT, function()
				if token ~= segToken then
					return
				end
				CarBuilder.setPassengerShown(car.passengers, AnomalySystem.EXTRA_ID, true)
			end)
		end
		if
			picked == "lighttemp"
			or picked == "sticker"
			or picked == "nearword"
			or picked == "mapstop"
			or picked == "moved"
			or picked == "empty"
			or picked == "faceturn"
			or picked == "momface"
		then
			task.delay(Constants.CATALOG_APPEAR_AT, function()
				if token ~= segToken then
					return
				end
				applyCatalog(picked)
			end)
		end
		if not seg.b and seg.stop == 5 then
			task.delay(9, function()
				if token ~= segToken then
					return
				end
				for _, lamp in car.lamps do
					if lamp.part.Name == "LightStrip_04" then
						stripHold[lamp.part] = true
						lamp.part.Color = Constants.COLOR.lightOff
						task.delay(0.15, function()
							stripHold[lamp.part] = nil
						end)
						break
					end
				end
			end)
		end
		if seg.final then
			local lastAt = math.max(Constants.NEXT_STOP_AT + Constants.NEXT_STOP_FOR + 0.4, length - 9)
			task.delay(lastAt, function()
				if token ~= segToken then
					return
				end
				showPa(Lines.LAST_PA, 5)
			end)
		end
		if held then
			local rawEffect = if seg.stop == Constants.HOLD_STOP_B then Constants.HOLD_EFFECT_B else Constants.HOLD_EFFECT_A
			local effect = Hold.plan(rawEffect)
			task.delay(holdAt, function()
				if token ~= segToken then
					return
				end
				ride:SetAttribute("Held", true)
				ride:SetAttribute("StareIntervalScale", Hold.stareScale(true, Constants.HOLD_STARE_MULTIPLIER))
				if effect == "dim" then
					beginDim(Hold.dimTarget(Constants.HOLD_DIM), Constants.HOLD_SECONDS)
				else
					blinkOneStrip(token, Constants.HOLD_SECONDS)
				end
				local tell = if seg.stop == Constants.HOLD_TELL_STOP then Hold.tell(Constants.HOLD_TELL) else nil
				if tell == "wrong_countdown" and picked ~= "wrong_countdown" then
					setTell(AnomalySystem.COUNTDOWN_ID, true)
					stopHadAnomaly = true
					ride:SetAttribute("BoardMinutes", AnomalySystem.boardMinutes(Constants.COUNTDOWN_MINUTES, Constants.WRONG_COUNTDOWN_MINUTES, true))
				end
				task.delay(Constants.HOLD_SECONDS, function()
					if token ~= segToken then
						return
					end
					ride:SetAttribute("Held", false)
					ride:SetAttribute("StareIntervalScale", Hold.stareScale(false, Constants.HOLD_STARE_MULTIPLIER))
					if effect == "dim" then
						beginDim(1, Constants.HOLD_RECOVER)
					end
					if tell == "wrong_countdown" and picked ~= "wrong_countdown" then
						setTell(AnomalySystem.COUNTDOWN_ID, false)
						ride:SetAttribute(
							"BoardMinutes",
							AnomalySystem.boardMinutes(Constants.COUNTDOWN_MINUTES, Constants.WRONG_COUNTDOWN_MINUTES, false)
						)
					end
				end)
			end)
		end
		if seg.restraint == true then
			task.delay(Constants.RESTRAINT_START_AT, function()
				if token ~= segToken then
					return
				end
				if ride:GetAttribute("Phase") ~= "ride" then
					return
				end
				startRestraintMoment()
			end)
		end
		task.wait(Hold.wallDuration(length, held, holdFor))
		-- Web waits for the restraint to finish before arrival.
		if token == segToken and seg.restraint == true and not restraintDone then
			if restraintState == nil then
				startRestraintMoment()
			end
			local deadline = os.clock() + Constants.RESTRAINT_DURATION + Constants.RESTRAINT_WAIT + 2
			while token == segToken and restraintState ~= nil and os.clock() < deadline do
				task.wait(0.05)
			end
			if token == segToken and restraintState ~= nil then
				endRestraint(false, Lines.RESTRAINT_FAIL_WAIT)
			end
		end
	end

	local function at(t0: number, t: number)
		local remain = t - (os.clock() - t0)
		if remain > 0 then
			task.wait(remain)
		end
	end

	local function arrive(seg: Route.Segment)
		segToken += 1
		local token = segToken
		maskEpoch += 1
		clearMaskUi()
		maskBusy = false
		currentSegStop = nil
		ride:SetAttribute("SegStop", 0)
		if evpState.raised then
			-- Carriers only while moving; keep the recorder up but clear the lock.
			publishEvp()
		end
		ride:SetAttribute("Phase", "stop")
		if stopHadAnomaly then
			if stopNoticed then
				accCorrect += 1
			else
				accMiss += 1
			end
		end
		local kind = Score.result(stopHadAnomaly, stopNoticed, stopFalseAlarm)
		applySuspicion(Score.endDelta(kind, Constants.CLEAN_STOP_SUSPICION, Constants.DECAY_SUSPICION))
		if kind == "clean" then
			local still = stretchMovedM < Constants.SITTING_STILL_MOVE_M
			applySuspicion(Score.sittingStillDelta(still, Constants.SITTING_STILL_SUSPICION))
		end
		stretchMovedM = 0
		table.clear(lastRootPos)
		table.clear(hasRootPos)
		stareAnomalyCharged = false
		stareParentCharged = false
		gazeSince = 0
		falseStopReacted = false
		falseStopOpen = false
		local feedbackKind, word = stopWord(kind)
		showFeedback(feedbackKind, word, false)
		clearTells()
		clearExtra()
		ride:SetAttribute("Held", false)
		ride:SetAttribute("StareIntervalScale", Hold.stareScale(false, Constants.HOLD_STARE_MULTIPLIER))
		for part, color in posterOriginal do
			part.Color = color
			posterOriginal[part] = nil
		end
		local t0 = os.clock()

		if seg.tick == "flicker" then
			blackout()
		end

		if seg.final then
			at(t0, 2.3)
			setDoorTarget(1)
			-- Doors stay open. There is no departure, so the penalty is not applied.
			beginDwell(Constants.MIN_DWELL_SECONDS)
			task.delay(Constants.MIN_DWELL_SECONDS, function()
				if token ~= segToken then
					return
				end
				endDwell()
			end)
			at(t0, 3.4)
			showSub(Lines.MOM_ARRIVE, 4)
			at(t0, 6.6)
			endGameAtCourtSq()
			return
		end

		if seg.paLie ~= nil then
			at(t0, 0.2)
			local lie = seg.paLie
			if lie ~= nil then
				showPa(lie, 5)
			end
		elseif not seg.silent and seg.kind ~= "false" then
			at(t0, 0.9)
			showPa(Lines.thisIs(Route.stopName(seg.stop)), 3)
		end

		local openAt = 0.35 + (if seg.tick == "doors" then 1.15 else 1.95)
		at(t0, openAt)
		setDoorTarget(1)
		local openedAt = os.clock()
		if seg.kind == "false" then
			falseStopOpen = true
		end

		-- Minimum dwell still runs while the player chooses Stay / Step off.
		beginDwell(Constants.MIN_DWELL_SECONDS)
		task.delay(Constants.MIN_DWELL_SECONDS, function()
			if token ~= segToken then
				return
			end
			endDwell()
		end)
		showHint(Lines.DOOR_PROMPT, Constants.DOOR_CHOICE_SECONDS)
		local picked = waitForDoorChoice(Constants.DOOR_CHOICE_SECONDS)
		if token ~= segToken then
			return
		end
		endDwell()
		if seg.kind == "false" then
			falseStopOpen = false
			applySuspicion(Score.falseStopDelta(playerReactedAtFalseStop(), Constants.FALSE_STOP_REACT_SUSPICION))
		end
		local outcome = Doors.resolve(
			seg.kind,
			seg.forgiving,
			picked,
			{
				realOff = Constants.STEP_OFF_REAL_SUSPICION,
				refuseHaven = Constants.REFUSE_HAVEN_SUSPICION,
				falseOff = Constants.FALSE_STOP_STEP_OFF_SUSPICION,
			},
			Lines.MOM_REAL_OFF,
			Lines.MOM_REFUSE_HAVEN,
			Lines.MOM_FALSE_FORGIVING,
			Lines.HAVEN_STUB,
			Lines.TRIAL_STUB
		)
		if outcome.suspicionDelta ~= 0 then
			applySuspicion(outcome.suspicionDelta)
		end
		if outcome.mode == "haven" then
			ride:SetAttribute("Phase", "haven")
			local h0 = os.clock()
			at(h0, Haven.MOM_STAND_AT)
			if token ~= segToken then
				return
			end
			showSub(Lines.MOM_HAVEN_STAND, 2.6)
			at(h0, Haven.DAD_STOPS_AT)
			if token ~= segToken then
				return
			end
			showSub(Lines.DAD_HAVEN_STOPS, 2.8)
			at(h0, Haven.RECORDER_AT)
			if token ~= segToken then
				return
			end
			giveRecorder("haven")
			at(h0, Haven.SANITY_AT)
			if token ~= segToken then
				return
			end
			applySanity(Constants.SANITY_HAVEN)
			showSub(Lines.HAVEN_BOARD, 2.0)
			at(h0, Haven.DEPART_AT)
			if token ~= segToken then
				return
			end
			ride:SetAttribute("Phase", "stop")
		elseif outcome.mode == "trial" then
			local ok = runTrial(token, Route.stopName(seg.stop), seg.stop)
			if not ok or token ~= segToken then
				return
			end
		else
			if outcome.line ~= "" then
				showSub(outcome.line, math.max(2.5, outcome.holdSeconds))
			end
			if outcome.holdSeconds > 0 then
				task.wait(outcome.holdSeconds)
			end
		end
		if token ~= segToken then
			return
		end
		-- A PA lie keeps doors open at least PA_LIE_HOLD from arrival before leave.
		local lieHold = if seg.paLie ~= nil then Constants.PA_LIE_HOLD else nil
		if lieHold ~= nil then
			local remainLie = lieHold - (os.clock() - t0)
			if remainLie > 0 then
				task.wait(remainLie)
			end
		end
		resolveDeparture(os.clock() - openedAt)
		showPa(Lines.STAND_CLEAR, 3)
		task.wait(1.4)
		setDoorTarget(0)
		task.wait(1.2)
	end

	metaStartRemote.OnServerEvent:Connect(function(player: Player, nightmare: any, chapter: any)
		if ride:GetAttribute("Phase") ~= "menu" then
			return
		end
		if pendingStart ~= nil then
			return
		end
		metaUserId = player.UserId
		local ch = if typeof(chapter) == "number" then Practice.normalizeChapter(chapter) else 1
		local data = MetaStore.load(player.UserId)
		local unlocked = data.nightmareUnlocked or data.runsCompleted > 0
		if ch > 1 and not unlocked then
			ch = 1
		end
		local nm = nightmare == true and unlocked
		pendingStart = { nightmare = nm, chapter = ch }
	end)

	metaAgainRemote.OnServerEvent:Connect(function(player: Player)
		if ride:GetAttribute("Phase") ~= "end" or ride:GetAttribute("ReportReady") ~= true then
			return
		end
		metaUserId = player.UserId
		pendingAgain = true
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		if metaUserId == nil then
			metaUserId = player.UserId
			refreshMetaPublish()
		end
	end)
	for _, player in Players:GetPlayers() do
		if metaUserId == nil then
			metaUserId = player.UserId
		end
	end
	refreshMetaPublish()

	local function clearReport()
		ride:SetAttribute("ReportReady", false)
		ride:SetAttribute("EndingId", "")
		ride:SetAttribute("EndingTitle", "")
		ride:SetAttribute("EndingBadge", "")
		ride:SetAttribute("EndingNarrative", "")
		ride:SetAttribute("ReportStats", "")
		ride:SetAttribute("ReportPsych", "")
	end

	local function resetRunState()
		table.clear(flagged)
		falseFlags = 0
		caught = false
		suspicion = 0
		peakSuspicion = 0
		sanity = Constants.SANITY_START
		bandStop = 1
		table.clear(sanSamples)
		interventions = 0
		intervening = false
		restraintState = nil
		restraintDone = false
		restraintOK = false
		restraintHeld = false
		table.clear(restraintHidden)
		table.clear(restraintMomRest)
		accCorrect = 0
		accMiss = 0
		table.clear(trialStops)
		finalExit = "escalators"
		pendingExitChoice = nil
		stopHadAnomaly = false
		stopNoticed = false
		stopFalseAlarm = false
		posterLive = false
		inFinal = false
		huntedDim = false
		table.clear(maskUsed)
		maskLast = nil
		maskBusy = false
		chatPlan = Dialogue.buildChatPlan(function()
			return math.random()
		end)
		hasRecorder = false
		evpState = Evp.newState(function()
			return math.random()
		end)
		currentSegStop = nil
		cameraRaised = false
		albumOpen = false
		filmLeft = Polaroid.STARTING_FILM
		nextShotAt = 0
		table.clear(polaroidPhotos)
		photoSeq = 0
		trestleBadgeChecked = false
		table.clear(anomalyTypesSeen)
		psychLog = PsychLog.newRide()
		gazeTarget = nil
		gazeSince = 0
		stareAnomalyCharged = false
		stareParentCharged = false
		falseStopReacted = false
		falseStopOpen = false
		stretchMovedM = 0
		table.clear(lastRootPos)
		table.clear(hasRootPos)
		stretch = nil
		odo = 0
		lastOpenAir = -1
		publishOpenAir(0)
		setDoorTarget(1)
		doorOpen = 1
		clearCatalog()
		clearTells()
		clearExtra()
		clearMaskUi()
		clearTrialUi()
		ride:SetAttribute("Suspicion", 0)
		ride:SetAttribute("PeakSuspicion", 0)
		publishSanity()
		ride:SetAttribute("SanityRetained", 0)
		ride:SetAttribute("Interventions", 0)
		ride:SetAttribute("Intervening", false)
		ride:SetAttribute("RestraintActive", false)
		ride:SetAttribute("RestraintProgress", 0)
		ride:SetAttribute("RestraintOK", false)
		ride:SetAttribute("ExitActive", false)
		ride:SetAttribute("ExitUntil", 0)
		ride:SetAttribute("HasRecorder", false)
		ride:SetAttribute("SegStop", 0)
		ride:SetAttribute("EvpRaised", false)
		ride:SetAttribute("EvpKhz", 120)
		ride:SetAttribute("EvpMeter", 0)
		ride:SetAttribute("EvpLocked", "")
		ride:SetAttribute("EvpStatus", "")
		ride:SetAttribute("EvpRecordT", 0)
		ride:SetAttribute("EvpTapes", "[]")
		ride:SetAttribute("EvpSaved", "")
		ride:SetAttribute("EvpPlayId", "")
		ride:SetAttribute("CameraRaised", false)
		ride:SetAttribute("AlbumOpen", false)
		ride:SetAttribute("FilmLeft", Polaroid.STARTING_FILM)
		ride:SetAttribute("PolaroidAlbum", "[]")
		ride:SetAttribute("Band", "calm")
		ride:SetAttribute("FalseStopBonus", 0)
		ride:SetAttribute("BoardStop", "")
		ride:SetAttribute("BoardMinutes", 0)
		ride:SetAttribute("Held", false)
		ride:SetAttribute("ChoiceActive", false)
		ride:SetAttribute("MaskActive", false)
		ride:SetAttribute("TrialActive", false)
		ride:SetAttribute("PaText", "")
		ride:SetAttribute("Subtitle", "")
		ride:SetAttribute("Hint", "")
		ride:SetAttribute("Feedback", "")
		ride:SetAttribute("FeedbackKind", "")
		ride:SetAttribute("NightmareOn", nightmareOn)
		ride:SetAttribute("PracticeOn", practiceOn)
		ride:SetAttribute(
			"PracticeNote",
			if practiceOn then Lines.META_PRACTICE_NOTE else ""
		)
		publishBand()
		publishEvp()
		publishCamera()
		publishRestraint()
		clearReport()
	end

	local function runIntro()
		ride:SetAttribute("Phase", "intro")
		doorOpen = 1
		setDoorTarget(1)
		local openedAt = os.clock()
		beginDwell(Constants.MIN_DWELL_SECONDS)
		task.delay(Constants.MIN_DWELL_SECONDS, function()
			if ride:GetAttribute("Phase") == "intro" then
				endDwell()
			end
		end)
		task.wait(1.2)
		showPa(Lines.INTRO_PA, 4)
		task.wait(1.3)
		showHint(Lines.HINT, 7)
		task.wait(3.5)
		showSub(Lines.DAD_BOARD, 2.8)
		task.wait(3)
		showPa(Lines.STAND_CLEAR, 3)
		task.wait(1.4)
		resolveDeparture(os.clock() - openedAt)
		setDoorTarget(0)
		task.wait(1.2)
	end

	local function runPracticeBoard()
		ride:SetAttribute("Phase", "intro")
		doorOpen = 1
		setDoorTarget(1)
		local originStop = if startChapter == 3 then 10 elseif startChapter == 2 then 5 else 1
		ride:SetAttribute("NextStop", Route.stopName(originStop + 1))
		ride:SetAttribute("ChapterLine", Route.chapterLine(originStop))
		Scenery.setName(leaving, Route.stopName(originStop))
		showPa(Lines.INTRO_PA, 2.5)
		showSub(Lines.META_PRACTICE_NOTE, 3.0)
		if startChapter >= 2 then
			giveRecorder("practice")
		end
		task.wait(2.2)
		showPa(Lines.STAND_CLEAR, 2)
		task.wait(1.2)
		setDoorTarget(0)
		task.wait(1.0)
	end

	task.spawn(function()
		while ride.Parent ~= nil do
			pendingStart = nil
			pendingAgain = false
			clearReport()
			ride:SetAttribute("NightmareOn", false)
			ride:SetAttribute("PracticeOn", false)
			ride:SetAttribute("PracticeNote", "")
			ride:SetAttribute("Phase", "menu")
			ride:SetAttribute("Hint", Lines.META_HINT)
			refreshMetaPublish()
			while pendingStart == nil and ride.Parent ~= nil do
				task.wait(0.1)
			end
			if ride.Parent == nil or pendingStart == nil then
				break
			end
			local choice = pendingStart
			pendingStart = nil
			nightmareOn = choice.nightmare
			startChapter = choice.chapter
			practiceOn = Practice.isPractice(startChapter)
			resetRunState()
			if practiceOn then
				runPracticeBoard()
			else
				runIntro()
			end
			local from = Practice.startIndex(startChapter)
			for i = from, #Route.SEGMENTS do
				local seg = Route.SEGMENTS[i]
				runSegment(seg)
				arrive(seg)
				if seg.final then
					break
				end
			end
			local deadline = os.clock() + Constants.META_REPORT_IDLE_SECONDS
			while ride.Parent ~= nil and not pendingAgain and os.clock() < deadline do
				task.wait(0.1)
			end
			pendingAgain = false
		end
	end)
end

return Ride
