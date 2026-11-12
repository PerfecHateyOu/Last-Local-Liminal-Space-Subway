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
local Lines = require(ReplicatedStorage.Shared.Lines)
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
		showTimed("PaText", text, seconds, "pa")
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
	}
	local stretch: Stretch? = nil

	local function beginStretch(seg: Route.Segment)
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
		}
		ride:SetAttribute("StretchStart", now)
		ride:SetAttribute("StretchAccel", accel)
		ride:SetAttribute("StretchCruise", cruise)
		ride:SetAttribute("StretchBrake", brake)
	end

	local slide = Constants.meters(Constants.DOOR_SLIDE_M)
	RunService.Heartbeat:Connect(function(dt: number)
		local current = stretch
		if current ~= nil then
			local t = workspace:GetServerTimeNow() - current.start
			odo = current.origin + Motion.distance(t, current.accel, current.cruise, current.brake, Constants.TOP_SPEED_MPS)
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
		if model:GetAttribute("Anomaly") == true then
			caught = true
			showFeedback("caught", Lines.CAUGHT, false)
		else
			falseFlags += 1
			showFeedback("false", Lines.falseFlag(label), false)
		end
	end)

	local function finishScore()
		local miss = if caught then 0 else 1
		local kind = if caught then "caught" else "missed"
		local word = if caught then Lines.CAUGHT else Lines.MISSED
		showFeedback(kind, word, true)
		showSub(Lines.scoreLine(miss, falseFlags), 30)
	end

	local segToken = 0

	local function runSegment(seg: Route.Segment)
		segToken += 1
		local token = segToken
		ride:SetAttribute("Phase", "ride")
		ride:SetAttribute("NextStop", Route.stopName(seg.stop))
		ride:SetAttribute("ChapterLine", Route.chapterLine(seg.stop))
		CarBuilder.setCrowd(car.passengers, seg.crowd)
		doorTarget = 0
		beginStretch(seg)

		local length = Route.segmentLength(seg, Constants.ACCEL, Constants.BRAKE)
		if seg.final then
			beginDim(Constants.FINAL_DIM, length)
		end

		if not seg.silent then
			task.delay(Constants.NEXT_STOP_AT, function()
				if token ~= segToken then
					return
				end
				showPa(Lines.nextStop(Route.stopName(seg.stop)), Constants.NEXT_STOP_FOR)
			end)
		end
		local function anomalyWanted(kind: string): boolean
			for _, name in AnomalySystem.types() do
				if name == kind then
					return true
				end
			end
			return false
		end
		if anomalyWanted("poster_changed") and not seg.b and seg.stop == 3 then
			task.delay(8, function()
				if token ~= segToken then
					return
				end
				for _, desc in car.model:GetDescendants() do
					if desc:IsA("BasePart") and string.sub(desc.Name, 1, 3) == "Ad_" and desc.Transparency < 0.5 then
						posterOriginal[desc] = desc.Color
						desc.Color = Color3.fromRGB(120, 36, 32)
						break
					end
				end
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
		task.wait(length)
	end

	local function at(t0: number, t: number)
		local remain = t - (os.clock() - t0)
		if remain > 0 then
			task.wait(remain)
		end
	end

	local function arrive(seg: Route.Segment)
		segToken += 1
		for part, color in posterOriginal do
			part.Color = color
			posterOriginal[part] = nil
		end
		ride:SetAttribute("Phase", "stop")
		local t0 = os.clock()

		if seg.tick == "flicker" then
			blackout()
		end

		if seg.final then
			at(t0, 2.3)
			doorTarget = 1
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

		local departAt = openAt + 2.6
		if seg.paLie ~= nil then
			departAt = math.max(departAt, 5.4)
		end
		at(t0, departAt)
		showPa(Lines.STAND_CLEAR, 3)
		at(t0, departAt + 1.4)
		doorTarget = 0
		at(t0, departAt + 2.6)
	end

	task.spawn(function()
		ride:SetAttribute("Phase", "intro")
		doorOpen = 1
		doorTarget = 1
		task.wait(1.2)
		showPa(Lines.INTRO_PA, 4)
		task.wait(1.3)
		showHint(Lines.HINT, 7)
		task.wait(3.5)
		showSub(Lines.DAD_BOARD, 2.8)
		task.wait(3)
		showPa(Lines.STAND_CLEAR, 3)
		task.wait(1.4)
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
