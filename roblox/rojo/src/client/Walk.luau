--!strict
-- First person, and the standing-passenger keep-out.
-- Roblox walks the character. This pushes the root back to the 0.75 m circle
-- if physics lets it inside (the solid cylinder should already stop it).
-- A shove smaller than a tenth of a stud is left alone so the two don't jitter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local KeepOut = require(ReplicatedStorage.Shared.KeepOut)

local Walk = {}

local function circles(): { KeepOut.Circle }
	local list: { KeepOut.Circle } = {}
	local car = workspace:FindFirstChild("SubwayCar")
	if car == nil then
		return list
	end
	local folder = car:FindFirstChild("Passengers")
	if folder == nil then
		return list
	end
	local radius = KeepOut.radiusStuds()
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Standing") == true and child:GetAttribute("Hidden") ~= true then
			local pos = child:GetPivot().Position
			table.insert(list, { x = pos.X, z = pos.Z, r = radius })
		end
	end
	return list
end

local function conceal(character: Model)
	local function hide(inst: Instance)
		if inst:IsA("BasePart") then
			inst.LocalTransparencyModifier = 1
		elseif inst:IsA("Decal") then
			inst.Transparency = 1
		end
	end
	for _, descendant in character:GetDescendants() do
		hide(descendant)
	end
	character.DescendantAdded:Connect(hide)
end

local function lockView(player: Player)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5
end

local function hideCore()
	task.spawn(function()
		for _ = 1, 20 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
			end)
			if ok then
				return
			end
			task.wait(0.25)
		end
	end)
end

function Walk.start()
	local player = Players.LocalPlayer
	lockView(player)
	hideCore()
	local function onCharacter(character: Model)
		lockView(player)
		conceal(character)
	end
	local existing = player.Character
	if existing ~= nil then
		onCharacter(existing)
	end
	player.CharacterAdded:Connect(onCharacter)

	local lastX: number? = nil
	local lastZ: number? = nil

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") then
			lastX = nil
			lastZ = nil
			return
		end
		local x = root.Position.X
		local z = root.Position.Z
		local prevX = if lastX ~= nil then lastX else x
		local prevZ = if lastZ ~= nil then lastZ else z
		local nx, nz = KeepOut.pushOut(x, z, circles(), prevX, prevZ)
		local dx = nx - x
		local dz = nz - z
		if dx * dx + dz * dz > 0.08 * 0.08 then
			root.CFrame = CFrame.new(nx, root.Position.Y, nz) * root.CFrame.Rotation
			root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			lastX = nx
			lastZ = nz
		else
			lastX = x
			lastZ = z
		end

		if root.Position.Y < -15 then
			local car = workspace:FindFirstChild("SubwayCar")
			local board = car and car:FindFirstChild("Board")
			if board ~= nil and board:IsA("BasePart") then
				root.CFrame = board.CFrame + Vector3.new(0, 5, 0)
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

return Walk
