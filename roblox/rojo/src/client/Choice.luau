--!strict
-- Stay / Step off UI. Server owns validation; this only fires the Doors remote
-- while ChoiceActive is true. Timeout on the server counts as Stay on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Lines = require(ReplicatedStorage.Shared.Lines)

local Choice = {}

function Choice.start(stayButton: TextButton, offButton: TextButton, setVisible: (boolean) -> (), setCountdown: (string) -> ())
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local doorsRemote = remotes:WaitForChild("Doors") :: RemoteEvent
	local sent = false

	local function active(): boolean
		return ride:GetAttribute("ChoiceActive") == true
	end

	local function pick(choice: string)
		if not active() or sent then
			return
		end
		sent = true
		doorsRemote:FireServer(choice)
	end

	stayButton.MouseButton1Click:Connect(function()
		pick("stay")
	end)
	offButton.MouseButton1Click:Connect(function()
		pick("off")
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not active() then
			return
		end
		if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
			pick("stay")
		elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
			pick("off")
		end
	end)

	local function refresh()
		local on = active()
		setVisible(on)
		if not on then
			sent = false
			setCountdown("")
			return
		end
		local deadline = ride:GetAttribute("ChoiceUntil")
		if typeof(deadline) ~= "number" or deadline <= 0 then
			setCountdown("")
			return
		end
		local remain = math.ceil(deadline - workspace:GetServerTimeNow())
		if remain < 1 then
			remain = 1
		end
		setCountdown(Lines.dwellCountdown(remain) .. " · default Stay on")
	end

	ride.AttributeChanged:Connect(function(name: string)
		if name == "ChoiceActive" or name == "ChoiceUntil" then
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

return Choice
