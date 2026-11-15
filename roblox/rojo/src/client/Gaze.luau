--!strict
-- Center gaze report for caught-staring. Server owns the meter; this only
-- raycasts and tells Remotes.Gaze who (if anyone) is under the crosshair.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Gaze = {}

local function passengerFromHit(inst: Instance): string?
	local found: string? = nil
	local hidden = false
	local current: Instance? = inst
	while current ~= nil and current ~= workspace do
		local id = current:GetAttribute("PassengerId")
		if typeof(id) == "string" then
			found = id
		end
		if current:GetAttribute("Hidden") == true then
			hidden = true
		end
		current = current.Parent
	end
	if hidden then
		return nil
	end
	return found
end

local function gazeId(): string?
	local camera = workspace.CurrentCamera
	if camera == nil then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	if character ~= nil then
		params.FilterDescendantsInstances = { character }
	end
	local result =
		workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * Constants.meters(Constants.FLAG_RANGE_M), params)
	if result == nil then
		return nil
	end
	return passengerFromHit(result.Instance)
end

function Gaze.start()
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local gazeRemote = remotes:WaitForChild("Gaze") :: RemoteEvent
	local lastSent: string? = nil
	local lastAt = 0

	RunService.Heartbeat:Connect(function()
		local phase = ride:GetAttribute("Phase")
		if phase ~= "ride" and phase ~= "stop" and phase ~= "haven" then
			if lastSent ~= nil then
				lastSent = nil
				gazeRemote:FireServer(nil)
			end
			return
		end
		local now = os.clock()
		if now - lastAt < 0.12 then
			return
		end
		lastAt = now
		local id = gazeId()
		if id == lastSent then
			return
		end
		lastSent = id
		gazeRemote:FireServer(id)
	end)
end

return Gaze
