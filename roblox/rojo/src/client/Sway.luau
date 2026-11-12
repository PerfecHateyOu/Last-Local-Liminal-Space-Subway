--!strict
-- Subtle view motion while the train is moving. The body stays where the
-- walk code put it. Bob stays at or under BOB_Y_M (2.2 cm) and roll under
-- one degree, both times speed/top speed, so a station is still.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Motion = require(ReplicatedStorage.Shared.Motion)

local Sway = {}

local function sample(): (number, number)
	local ride = ReplicatedStorage:FindFirstChild("Ride")
	if ride == nil then
		return 0, 0
	end
	local start = ride:GetAttribute("StretchStart")
	local accel = ride:GetAttribute("StretchAccel")
	local cruise = ride:GetAttribute("StretchCruise")
	local brake = ride:GetAttribute("StretchBrake")
	if typeof(start) ~= "number" or typeof(accel) ~= "number" or typeof(cruise) ~= "number" or typeof(brake) ~= "number" then
		return 0, 0
	end
	local top = Constants.TOP_SPEED_MPS
	local t = workspace:GetServerTimeNow() - start
	local velocity = Motion.speed(t, accel, cruise, brake, top)
	local fraction = if top > 0 then math.clamp(velocity / top, 0, 1) else 0
	local pitch = 0
	if t >= 0 and t < accel and accel > 0 then
		pitch = math.sin(math.clamp(t / accel, 0, 1) * math.pi)
	elseif brake > 0 and t > accel + cruise and t < accel + cruise + brake then
		local u = (t - accel - cruise) / brake
		pitch = -math.sin(math.clamp(u, 0, 1) * math.pi)
	end
	return fraction, pitch
end

function Sway.start()
	RunService:BindToRenderStep("LastLocalSway", Enum.RenderPriority.Camera.Value + 1, function()
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local fraction, pitchBias = sample()
		local now = os.clock()
		local bobY = (math.sin(now * 1.5) * 0.72 + math.sin(now * 2.7) * 0.28) * Constants.BOB_Y_M * fraction
		local bobZ = math.sin(now * 0.85) * Constants.BOB_X_M * fraction
		local lurch = pitchBias * 0.012 * fraction
		local roll = math.rad(math.sin(now * 0.7) * Constants.ROLL_DEG * fraction)
		local pitch = math.rad(pitchBias * Constants.PITCH_DEG)
		-- Assigning CFrame forces CameraType to Scriptable, which drops
		-- LockFirstPerson and leaves the camera on the avatar. Capture the
		-- type, nudge the view, then put the type back so the next frame's
		-- camera script still sits in the head.
		local cameraType = camera.CameraType
		local offset = Vector3.new(Constants.meters(lurch), Constants.meters(bobY), Constants.meters(bobZ))
		camera.CFrame = CFrame.new(offset) * (camera.CFrame * CFrame.Angles(pitch, 0, roll))
		if cameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = cameraType
		end
	end)
end

return Sway
