--!strict
-- Parent mask check UI. Server owns validation; this only fires Remotes.Mask
-- while MaskActive is true. Timeout on the server counts as hesitation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Mask = {}

function Mask.start(
	buttonA: TextButton,
	buttonB: TextButton,
	buttonC: TextButton,
	setVisible: (boolean) -> (),
	setCountdown: (string) -> (),
	setLabels: (string, string, string) -> ()
)
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local maskRemote = remotes:WaitForChild("Mask") :: RemoteEvent
	local sent = false

	local function active(): boolean
		return ride:GetAttribute("MaskActive") == true
	end

	local function pick(slot: string)
		if not active() or sent then
			return
		end
		sent = true
		maskRemote:FireServer(slot)
	end

	buttonA.MouseButton1Click:Connect(function()
		pick("A")
	end)
	buttonB.MouseButton1Click:Connect(function()
		pick("B")
	end)
	buttonC.MouseButton1Click:Connect(function()
		pick("C")
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not active() then
			return
		end
		if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
			pick("A")
		elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
			pick("B")
		elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			pick("C")
		end
	end)

	local function textOf(name: string): string
		local value = ride:GetAttribute(name)
		if typeof(value) == "string" then
			return value
		end
		return ""
	end

	local function refresh()
		local on = active()
		setVisible(on)
		if not on then
			sent = false
			setCountdown("")
			setLabels("", "", "")
			return
		end
		setLabels(textOf("MaskA"), textOf("MaskB"), textOf("MaskC"))
		local deadline = ride:GetAttribute("MaskUntil")
		if typeof(deadline) ~= "number" or deadline <= 0 then
			setCountdown("")
			return
		end
		local remain = math.ceil(deadline - workspace:GetServerTimeNow())
		if remain < 1 then
			remain = 1
		end
		setCountdown(tostring(remain) .. "s · hesitate raises suspicion")
	end

	ride.AttributeChanged:Connect(function(name: string)
		if
			name == "MaskActive"
			or name == "MaskUntil"
			or name == "MaskA"
			or name == "MaskB"
			or name == "MaskC"
		then
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

return Mask
