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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnomalySystem = require(script.Parent.AnomalySystem)
local CarBuilder = require(script.Parent.CarBuilder)
local Scenery = require(script.Parent.Scenery)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Dwell = require(ReplicatedStorage.Shared.Dwell)
local Hold = require(ReplicatedStorage.Shared.Hold)
local Lines = require(ReplicatedStorage.Shared.Lines)
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

	ride:SetAttribute("Phase", "intro")
	ride:SetAttribute("PaText", "")
	ride:SetAttribute("Subtitle", "")
	ride:SetAttribute("Hint", "")
	ride:SetAttribute("Feedback", "")
	ride:SetAttribute("FeedbackKind", "")
	ride:SetAttribute("NextStop", Route.stopName(2))
	ride:SetAttribute("ChapterLine", Route.chapterLine(1))
	ride:SetAttribute("DwellUntil", 0)
	ride:SetAttribute("Suspicion", 0)
	ride:SetAttribute("Band", "calm")
	ride:SetAttribute("FalseStopBonus", 0)
	ride:SetAttribute("BoardStop", "")
	ride:SetAttribute("BoardMinutes", 0)
	ride:SetAttribute("HoldAt", 0)
	ride:SetAttribute("HoldFor", 0)
	ride:SetAttribute("Held", false)
	ride:SetAttribute("StareIntervalScale", 1)

	CarBuilder.addTells(
		car.passengers,
		AnomalySystem.ANNOUNCE_ID,
		Lines.ANNOUNCEMENT,
		AnomalySystem.COUNTDOWN_ID,
		Lines.COUNTDOWN
	)

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
	local dim = 1
	local dimFrom = 1
	local dimTo = 1
	local dimStart = 0
	local dimDuration = 1
	local dimming = false
	local forcedOff = false

	local function blackout()
		-- Flicker tick only. Callers are the two segments whose tick is "flicker".
		forcedOff = true
		task.delay(Constants.FLICKER_TICK_SECONDS, function()
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

	type Stretch = {
		start: number,
		origin: number,
		accel: number,
		cruise: number,
		brake: number,
		holdAt: number,
		holdFor: number,
	}
	local stretch: Stretch? = nil

	local function beginStretch(seg: Route.Segment, holdAt: number, holdFor: number)
		local accel = Constants.ACCEL
		local brake = Constants.BRAKE
		local cruise = seg.sliceCruise
		-- Whichever platform is already at the doors is the one we leave.
		if math.abs(arriving.base - odo) < math.abs(leaving.base - odo) then
			local swap = leaving
			leaving = arriving
			arriving = swap
		end
		leaving.base = odo
		local dist = Motion.segmentDistance(accel, cruise, brake, Constants.TOP_SPEED_MPS)
		arriving.base = odo + dist
		Scenery.setName(arriving, Route.stopName(seg.stop))
		local now = workspace:GetServerTimeNow()
		stretch = {
			start = now,
			origin = odo,
			accel = accel,
			cruise = cruise,
			brake = brake,
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
			odo = current.origin + Motion.distance(motionT, current.accel, current.cruise, current.brake, Constants.TOP_SPEED_MPS)
		end
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
	local stopHadAnomaly = false
	local stopNoticed = false
	local stopFalseAlarm = false
	local posterLive = false
	local inFinal = false
	local huntedDim = false

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

	local function applySuspicion(delta: number)
		suspicion = Score.apply(suspicion, delta, Constants.SUSPICION_MIN, Constants.SUSPICION_MAX)
		ride:SetAttribute("Suspicion", suspicion)
		publishBand()
	end

	publishBand()

	task.spawn(function()
		while ride.Parent ~= nil do
			task.wait(Constants.UNEASY_TUBE_EVERY)
			if ride:GetAttribute("Band") == "uneasy" and ride:GetAttribute("Phase") == "ride" then
				blinkBandTube()
			end
		end
	end)

	-- Intentionally unused. Nothing here can see a player stand at the
	-- doors, walk to them, or stare on a false stop. A detector would
	-- return true and FALSE_STOP_REACT_SUSPICION would be added.
	local function playerReactedAtFalseStop(): boolean
		return false
	end

	-- Passenger, on purpose. The player is the kid riding with Mom and Dad.
	-- They cannot close the doors or dispatch the train, so this stays
	-- false. It is intentionally unused. A depart control would return
	-- true and add EARLY_DEPARTURE_SUSPICION. There is no such control,
	-- and there is no fail state.
	local function playerAskedToDepartEarly(): boolean
		return false
	end

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

	local function clearTells()
		setTell(AnomalySystem.ANNOUNCE_ID, false)
		setTell(AnomalySystem.COUNTDOWN_ID, false)
		ride:SetAttribute("BoardStop", "")
		ride:SetAttribute("BoardMinutes", 0)
	end

	local function anomalyLive(): boolean
		if posterLive then
			return true
		end
		for _, id in { AnomalySystem.ANNOUNCE_ID, AnomalySystem.COUNTDOWN_ID, AnomalySystem.EXTRA_ID } do
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

	flagRemote.OnServerEvent:Connect(function(player: Player, passengerId: any)
		if typeof(passengerId) ~= "string" then
			return
		end
		if ride:GetAttribute("Phase") ~= "ride" then
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

	local function finishScore()
		local miss = if caught then 0 else 1
		local kind = if caught then "caught" else "missed"
		local word = if caught then Lines.CAUGHT else Lines.MISSED
		showFeedback(kind, word, true)
		showSub(Lines.scoreLine(miss, falseFlags), 30)
	end

	local segToken = 0

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
		ride:SetAttribute("Phase", "ride")
		ride:SetAttribute("NextStop", Route.stopName(seg.stop))
		ride:SetAttribute("ChapterLine", Route.chapterLine(seg.stop))
		CarBuilder.setCrowd(car.passengers, seg.crowd)
		clearExtra()
		doorTarget = 0

		local length = Route.segmentLength(seg, Constants.ACCEL, Constants.BRAKE)
		inFinal = seg.final
		if seg.final and huntedDim then
			huntedDim = false
		end
		local held = Hold.applies(seg.stop, seg.b, seg.final, Constants.HOLD_STOP_A, Constants.HOLD_STOP_B)
			and Hold.placed(Constants.HOLD_AT, Constants.HOLD_SECONDS, Constants.ACCEL, seg.sliceCruise)
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
		})
		stopHadAnomaly = picked ~= nil
		stopNoticed = false
		stopFalseAlarm = false
		posterLive = false
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
		task.wait(Hold.wallDuration(length, held, holdFor))
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
		ride:SetAttribute("Phase", "stop")
		local kind = Score.result(stopHadAnomaly, stopNoticed, stopFalseAlarm)
		applySuspicion(Score.endDelta(kind, Constants.CLEAN_STOP_SUSPICION, Constants.DECAY_SUSPICION))
		if seg.kind == "false" then
			applySuspicion(Score.falseStopDelta(playerReactedAtFalseStop(), Constants.FALSE_STOP_REACT_SUSPICION))
		end
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
			doorTarget = 1
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
			finishScore()
			ride:SetAttribute("Phase", "end")
			ride:SetAttribute("NextStop", Route.stopName(13))
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
		doorTarget = 1
		local openedAt = os.clock()

		-- The banner counts the minimum only. A PA lie keeps its own hold,
		-- measured from arrival. That hold is not a second dwell.
		local lieHold = if seg.paLie ~= nil then Constants.PA_LIE_HOLD else nil
		local departAt = Dwell.departTime(openAt, Constants.MIN_DWELL_SECONDS, lieHold)
		beginDwell(Constants.MIN_DWELL_SECONDS)
		task.delay(Constants.MIN_DWELL_SECONDS, function()
			if token ~= segToken then
				return
			end
			endDwell()
		end)
		at(t0, departAt)
		endDwell()
		resolveDeparture(os.clock() - openedAt)
		showPa(Lines.STAND_CLEAR, 3)
		at(t0, departAt + 1.4)
		doorTarget = 0
		-- 2.6s after stand-clear is the next stretch, not the dwell.
		at(t0, departAt + 2.6)
	end

	task.spawn(function()
		ride:SetAttribute("Phase", "intro")
		doorOpen = 1
		doorTarget = 1
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
		doorTarget = 0
		task.wait(1.2)

		for _, seg in Route.SEGMENTS do
			runSegment(seg)
			arrive(seg)
			if seg.final then
				break
			end
		end
	end)
end

return Ride
