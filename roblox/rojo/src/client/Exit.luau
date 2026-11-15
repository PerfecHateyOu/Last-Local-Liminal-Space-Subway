--!strict
-- Court Square exit pick. Server owns resolveEnding; this fires Remotes.Exit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Lines = require(ReplicatedStorage.Shared.Lines)

local Exit = {}

function Exit.start(
	buttonA: TextButton,
	buttonB: TextButton,
	buttonC: TextButton,
	setVisible: (boolean) -> (),
	setCountdown: (string) -> (),
	setLabels: (string, string, string) -> ()
)
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local exitRemote = remotes:WaitForChild("Exit") :: RemoteEvent
	local sent = false

	local function active(): boolean
		return ride:GetAttribute("ExitActive") == true
	end

	local function pick(choice: string)
		if not active() or sent then
			return
		end
		sent = true
		exitRemote:FireServer(choice)
	end

	buttonA.MouseButton1Click:Connect(function()
		pick("escalators")
	end)
	buttonB.MouseButton1Click:Connect(function()
		pick("lower_level")
	end)
	buttonC.MouseButton1Click:Connect(function()
		pick("surface_hatch")
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not active() then
			return
		end
		if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
			pick("escalators")
		elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
			pick("lower_level")
		elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			pick("surface_hatch")
		end
	end)

	local function refresh()
		local on = active()
		setVisible(on)
		if on then
			setLabels(Lines.EXIT_ESCALATORS, Lines.EXIT_LOWER, Lines.EXIT_HATCH)
		end
		if not on then
			sent = false
			setCountdown("")
			return
		end
		local deadline = ride:GetAttribute("ExitUntil")
		if typeof(deadline) ~= "number" or deadline <= 0 then
			setCountdown("")
			return
		end
		local remain = math.ceil(deadline - workspace:GetServerTimeNow())
		if remain < 1 then
			remain = 1
		end
		setCountdown(tostring(remain) .. "s · " .. Lines.EXIT_DEFAULT)
	end

	ride.AttributeChanged:Connect(function(name: string)
		if name == "ExitActive" or name == "ExitUntil" then
			refresh()
		end
	end)
	RunService.Heartbeat:Connect(function()
		if active() then
			refresh()
		end
	end)
	refresh()
end

return Exit
