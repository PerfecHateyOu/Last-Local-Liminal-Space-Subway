--!strict
-- Heads, from the band the server already chose. Uneasy: one glance while
-- you walk. Watched: heads stay turned toward you. No new parts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Band = require(ReplicatedStorage.Shared.Band)
local Constants = require(ReplicatedStorage.Shared.Constants)

local Glance = {}

type Cluster = {
	head: BasePart,
	parts: { BasePart },
	rest: { [BasePart]: CFrame },
}

local function clusterOf(model: Model): Cluster?
	if model:GetAttribute("Tell") ~= nil then
		return nil
	end
	if model:GetAttribute("Hidden") == true then
		return nil
	end
	local head = model:FindFirstChild("Head", true)
	if head == nil or not head:IsA("BasePart") then
		return nil
	end
	local parts = {}
	local rest = {}
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and (desc.Name == "Head" or desc.Name == "Hair" or desc.Name == "Eye") then
			table.insert(parts, desc)
			rest[desc] = desc.CFrame
		end
	end
	if #parts == 0 then
		return nil
	end
	return { head = head, parts = parts, rest = rest }
end

local function yawTo(face: Vector3, toward: Vector3): number
	local a = Vector3.new(face.X, 0, face.Z)
	local b = Vector3.new(toward.X, 0, toward.Z)
	if a.Magnitude < 0.05 or b.Magnitude < 0.05 then
		return 0
	end
	a = a.Unit
	b = b.Unit
	return math.atan2(a:Cross(b).Y, a:Dot(b))
end

local function pose(group: Cluster, angle: number)
	local headRest = group.rest[group.head]
	local origin = headRest.Position
	local spin = CFrame.Angles(0, angle, 0)
	for _, part in group.parts do
		local rest = group.rest[part]
		local rel = rest.Position - origin
		part.CFrame = CFrame.new(origin) * spin * CFrame.new(rel) * (rest - rest.Position)
	end
end

local function restore(group: Cluster)
	for _, part in group.parts do
		local rest = group.rest[part]
		part.CFrame = rest
	end
end

function Glance.start()
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local player = Players.LocalPlayer
	local groups: { Cluster } = {}
	local known: { [Model]: boolean } = {}
	local glanceGroup: Cluster? = nil
	local glanceStart = 0
	local nextGlance = 0

	local function collect()
		local car = workspace:FindFirstChild("SubwayCar")
		local folder = if car ~= nil then car:FindFirstChild("Passengers") else nil
		if folder == nil then
			return
		end
		for _, child in folder:GetChildren() do
			if child:IsA("Model") and known[child] ~= true then
				local group = clusterOf(child)
				if group ~= nil then
					known[child] = true
					table.insert(groups, group)
				end
			end
		end
	end

	local function angleToward(group: Cluster, maxRad: number): number
		local character = player.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if root == nil or not root:IsA("BasePart") then
			return 0
		end
		local rest = group.rest[group.head]
		local face = -rest.LookVector
		local yaw = yawTo(face, root.Position - rest.Position)
		return math.clamp(yaw, -maxRad, maxRad)
	end

	local function moving(): boolean
		local character = player.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		return humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.05
	end

	RunService.Heartbeat:Connect(function()
		collect()
		local band = ride:GetAttribute("Band")
		local look = if typeof(band) == "string" then Band.look(band) else "none"
		if look == "none" then
			for _, group in groups do
				restore(group)
			end
			glanceGroup = nil
			return
		end
		if look == "turn" then
			glanceGroup = nil
			local maxRad = math.rad(Constants.TURN_YAW_DEG)
			for _, group in groups do
				pose(group, angleToward(group, maxRad))
			end
			return
		end
		local now = os.clock()
		if glanceGroup == nil and moving() and now >= nextGlance and #groups > 0 then
			glanceGroup = groups[math.random(1, #groups)]
			glanceStart = now
			nextGlance = now + Constants.GLANCE_COOLDOWN
		end
		local active = glanceGroup
		for _, group in groups do
			if active ~= nil and group == active then
				local u = (now - glanceStart) / Constants.GLANCE_SECONDS
				if u >= 1 then
					restore(group)
					glanceGroup = nil
				else
					local weight = math.sin(math.pi * math.clamp(u, 0, 1))
					pose(group, angleToward(group, math.rad(Constants.GLANCE_YAW_DEG)) * weight)
				end
			else
				restore(group)
			end
		end
	end)
end

return Glance
