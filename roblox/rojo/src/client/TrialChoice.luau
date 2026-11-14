--!strict
-- False Stop Trial pick UI. Server owns validation; fires Remotes.Trial with 0/1/2.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TrialChoice = {}

function TrialChoice.start(
	buttonA: TextButton,
	buttonB: TextButton,
	buttonC: TextButton,
	setVisible: (boolean) -> (),
	setCountdown: (string) -> (),
	setLabels: (string, string, string, number) -> ()
)
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local trialRemote = remotes:WaitForChild("Trial") :: RemoteEvent
	local sent = false

	local function active(): boolean
		return ride:GetAttribute("TrialActive") == true
	end

	local function slots(): number
		local value = ride:GetAttribute("TrialSlots")
		if typeof(value) == "number" then
			return value
		end
		return 0
	end

	local function pick(val: number)
		if not active() or sent then
			return
		end
		sent = true
		trialRemote:FireServer(val)
	end

	buttonA.MouseButton1Click:Connect(function()
		pick(0)
	end)
	buttonB.MouseButton1Click:Connect(function()
		if slots() == 2 then
			pick(2)
		else
			pick(1)
		end
	end)
	buttonC.MouseButton1Click:Connect(function()
		pick(2)
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not active() then
			return
		end
		if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
			pick(0)
		elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
			if slots() == 2 then
				pick(2)
			else
				pick(1)
			end
		elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
			if slots() >= 3 then
				pick(2)
			end
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
			setLabels("", "", "", 0)
			return
		end
		local n = slots()
		setLabels(textOf("TrialA"), textOf("TrialB"), textOf("TrialC"), n)
		local deadline = ride:GetAttribute("TrialUntil")
		if typeof(deadline) ~= "number" or deadline <= 0 then
			setCountdown("Watch the lights · signs lie")
			return
		end
		local remain = math.ceil(deadline - workspace:GetServerTimeNow())
		if remain < 1 then
			remain = 1
		end
		setCountdown(tostring(remain) .. "s · watch the lights")
	end

	ride.AttributeChanged:Connect(function(name: string)
		if
			name == "TrialActive"
			or name == "TrialUntil"
			or name == "TrialA"
			or name == "TrialB"
			or name == "TrialC"
			or name == "TrialSlots"
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

return TrialChoice
