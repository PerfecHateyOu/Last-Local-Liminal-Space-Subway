--!strict
-- Builds the car, then runs the stop cycle. Characters load after the car
-- exists so nobody spawns into the void.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBuilder = require(script.CarBuilder)
local Ride = require(script.Ride)
local WorldLight = require(script.WorldLight)
local Constants = require(ReplicatedStorage.Shared.Constants)

Players.CharacterAutoLoads = false
workspace.StreamingEnabled = false
workspace.Gravity = 196.2
workspace.FallenPartsDestroyHeight = -50

-- Forced again if Studio resets Lighting when play starts.
WorldLight.bind()

local car = CarBuilder.build()
Ride.start(car)

local function prepare(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Constants.WALK_SPEED_MPS * Constants.STUDS_PER_METER
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.RespawnLocation = car.board

	humanoid.Died:Connect(function()
		task.wait(2)
		if player.Parent == Players then
			player:LoadCharacterAsync()
		end
	end)
end

local function spawnPlayer(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		prepare(player, character)
	end)
	player:LoadCharacterAsync()
end

Players.PlayerAdded:Connect(spawnPlayer)
for _, player in Players:GetPlayers() do
	spawnPlayer(player)
end
