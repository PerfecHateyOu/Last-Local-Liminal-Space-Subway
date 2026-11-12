--!strict
-- Hold Flag (F, or the button) while the crosshair is on a passenger.
-- The hold is 0.7 seconds, the web game's CFG.flagHold. It only fills
-- during a ride, which is when the web game counts a flag.
-- The server decides caught vs false flag. This script does not.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Hud = require(script.Parent.Hud)

local Flag = {}

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
	local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * Constants.meters(Constants.FLAG_RANGE_M), params)
	if result == nil then
		return nil
	end
	return passengerFromHit(result.Instance)
end

function Flag.start(button: TextButton)
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local flagRemote = remotes:WaitForChild("Flag") :: RemoteEvent

	local keyDown = false
	local buttonDown = false
	local locked = false
	local progress = 0
	local currentId: string? = nil

	local function holding(): boolean
		return keyDown or buttonDown
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F then
			keyDown = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.F then
			keyDown = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			buttonDown = false
		end
	end)

	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			buttonDown = true
		end
	end)

	RunService.RenderStepped:Connect(function(dt: number)
		local riding = ride:GetAttribute("Phase") == "ride"
		local down = holding()
		if not down then
			locked = false
			progress = 0
			currentId = nil
			Hud.setProgress(0, false)
			return
		end
		if not riding or locked then
			Hud.setProgress(if locked then 1 else 0, riding)
			return
		end

		local id = gazeId()
		if id == nil or id ~= currentId then
			currentId = id
			progress = 0
		end
		if currentId == nil then
			Hud.setProgress(0, true)
			return
		end
		progress += dt
		local ratio = math.clamp(progress / Constants.FLAG_HOLD, 0, 1)
		Hud.setProgress(ratio, true)
		if progress >= Constants.FLAG_HOLD and currentId ~= nil then
			locked = true
			flagRemote:FireServer(currentId)
		end
	end)
end

return Flag
