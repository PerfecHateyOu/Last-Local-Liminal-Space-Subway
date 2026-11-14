--!strict
-- Tape recorder UI: raise/lower, tune, hold-to-record, Evidence list + playback.
-- Server owns meter/lock/tapes; this only fires remotes and draws attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Evp = {}

local function corner(parent: Instance, radius: number)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
end

local function parseTapes(raw: string): { { signalId: string, title: string, stop: string, freq: string, transcript: string } }
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or typeof(data) ~= "table" then
		return {}
	end
	local out = {}
	for _, item in data do
		if typeof(item) == "table" and typeof(item.signalId) == "string" and typeof(item.title) == "string" then
			table.insert(out, {
				signalId = item.signalId,
				title = item.title,
				stop = if typeof(item.stop) == "string" then item.stop else "",
				freq = if typeof(item.freq) == "string" then item.freq else "",
				transcript = if typeof(item.transcript) == "string" then item.transcript else "",
			})
		end
	end
	return out
end

function Evp.start(recorderButton: TextButton, evidenceButton: TextButton)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local toggleRemote = remotes:WaitForChild("EvpToggle") :: RemoteEvent
	local tuneRemote = remotes:WaitForChild("EvpTune") :: RemoteEvent
	local recordRemote = remotes:WaitForChild("EvpRecord") :: RemoteEvent
	local playRemote = remotes:WaitForChild("EvpPlay") :: RemoteEvent

	local gui = playerGui:WaitForChild("LastLocalHud") :: ScreenGui

	local panel = Instance.new("Frame")
	panel.Name = "EvpRecorder"
	panel.AnchorPoint = Vector2.new(1, 1)
	panel.Position = UDim2.new(1, -16, 1, -120)
	panel.Size = UDim2.fromOffset(280, 168)
	panel.BackgroundColor3 = Color3.fromRGB(18, 16, 12)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 10)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Code
	title.Text = "MICROCASSETTE"
	title.TextSize = 11
	title.TextColor3 = Color3.fromRGB(180, 176, 166)
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -48, 0, 16)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local lower = Instance.new("TextButton")
	lower.Name = "Lower"
	lower.AnchorPoint = Vector2.new(1, 0)
	lower.Position = UDim2.new(1, -8, 0, 4)
	lower.Size = UDim2.fromOffset(28, 28)
	lower.BackgroundColor3 = Color3.fromRGB(40, 36, 30)
	lower.BorderSizePixel = 0
	lower.Font = Enum.Font.GothamBold
	lower.Text = "×"
	lower.TextColor3 = Constants.COLOR.cream
	lower.TextSize = 16
	lower.Parent = panel
	corner(lower, 14)

	local khzLabel = Instance.new("TextLabel")
	khzLabel.Name = "Khz"
	khzLabel.BackgroundTransparency = 1
	khzLabel.Font = Enum.Font.GothamBold
	khzLabel.Text = "120.0 kHz"
	khzLabel.TextSize = 18
	khzLabel.TextColor3 = Constants.COLOR.cream
	khzLabel.Position = UDim2.fromOffset(12, 28)
	khzLabel.Size = UDim2.fromOffset(120, 24)
	khzLabel.TextXAlignment = Enum.TextXAlignment.Left
	khzLabel.Parent = panel

	local lockDot = Instance.new("Frame")
	lockDot.Name = "Lock"
	lockDot.Position = UDim2.fromOffset(140, 34)
	lockDot.Size = UDim2.fromOffset(12, 12)
	lockDot.BackgroundColor3 = Color3.fromRGB(44, 58, 40)
	lockDot.BorderSizePixel = 0
	lockDot.Parent = panel
	corner(lockDot, 6)

	local meterBack = Instance.new("Frame")
	meterBack.Name = "MeterBack"
	meterBack.Position = UDim2.fromOffset(12, 58)
	meterBack.Size = UDim2.new(1, -24, 0, 8)
	meterBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	meterBack.BorderSizePixel = 0
	meterBack.Parent = panel
	corner(meterBack, 4)

	local meterFill = Instance.new("Frame")
	meterFill.Name = "Fill"
	meterFill.Size = UDim2.fromScale(0, 1)
	meterFill.BackgroundColor3 = Constants.COLOR.gLine
	meterFill.BorderSizePixel = 0
	meterFill.Parent = meterBack
	corner(meterFill, 4)

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.Text = ""
	status.TextSize = 12
	status.TextColor3 = Constants.COLOR.cream
	status.TextWrapped = true
	status.Position = UDim2.fromOffset(12, 72)
	status.Size = UDim2.new(1, -24, 0, 40)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.Parent = panel

	local tuneLeft = Instance.new("TextButton")
	tuneLeft.Position = UDim2.fromOffset(12, 118)
	tuneLeft.Size = UDim2.fromOffset(40, 36)
	tuneLeft.BackgroundColor3 = Color3.fromRGB(40, 36, 30)
	tuneLeft.BorderSizePixel = 0
	tuneLeft.Font = Enum.Font.GothamBold
	tuneLeft.Text = "["
	tuneLeft.TextColor3 = Constants.COLOR.cream
	tuneLeft.TextSize = 16
	tuneLeft.Parent = panel
	corner(tuneLeft, 8)

	local tuneRight = Instance.new("TextButton")
	tuneRight.Position = UDim2.fromOffset(56, 118)
	tuneRight.Size = UDim2.fromOffset(40, 36)
	tuneRight.BackgroundColor3 = Color3.fromRGB(40, 36, 30)
	tuneRight.BorderSizePixel = 0
	tuneRight.Font = Enum.Font.GothamBold
	tuneRight.Text = "]"
	tuneRight.TextColor3 = Constants.COLOR.cream
	tuneRight.TextSize = 16
	tuneRight.Parent = panel
	corner(tuneRight, 8)

	local rec = Instance.new("TextButton")
	rec.Name = "Record"
	rec.Position = UDim2.fromOffset(108, 118)
	rec.Size = UDim2.new(1, -120, 0, 36)
	rec.BackgroundColor3 = Color3.fromRGB(80, 28, 24)
	rec.BorderSizePixel = 0
	rec.Font = Enum.Font.GothamBold
	rec.Text = "HOLD  REC"
	rec.TextColor3 = Constants.COLOR.cream
	rec.TextSize = 13
	rec.Parent = panel
	corner(rec, 8)

	local evidence = Instance.new("Frame")
	evidence.Name = "EvidenceLog"
	evidence.AnchorPoint = Vector2.new(0.5, 0.5)
	evidence.Position = UDim2.fromScale(0.5, 0.48)
	evidence.Size = UDim2.fromOffset(360, 280)
	evidence.BackgroundColor3 = Color3.fromRGB(14, 12, 10)
	evidence.BackgroundTransparency = 0.05
	evidence.BorderSizePixel = 0
	evidence.Visible = false
	evidence.Parent = gui
	corner(evidence, 12)

	local evTitle = Instance.new("TextLabel")
	evTitle.BackgroundTransparency = 1
	evTitle.Font = Enum.Font.GothamBold
	evTitle.Text = "Evidence Log — Tapes"
	evTitle.TextSize = 16
	evTitle.TextColor3 = Constants.COLOR.cream
	evTitle.Position = UDim2.fromOffset(14, 10)
	evTitle.Size = UDim2.new(1, -50, 0, 24)
	evTitle.TextXAlignment = Enum.TextXAlignment.Left
	evTitle.Parent = evidence

	local evClose = Instance.new("TextButton")
	evClose.AnchorPoint = Vector2.new(1, 0)
	evClose.Position = UDim2.new(1, -10, 0, 8)
	evClose.Size = UDim2.fromOffset(28, 28)
	evClose.BackgroundColor3 = Color3.fromRGB(40, 36, 30)
	evClose.BorderSizePixel = 0
	evClose.Font = Enum.Font.GothamBold
	evClose.Text = "×"
	evClose.TextColor3 = Constants.COLOR.cream
	evClose.TextSize = 16
	evClose.Parent = evidence
	corner(evClose, 14)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(12, 44)
	list.Size = UDim2.new(1, -24, 1, -56)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.Parent = evidence

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = list

	local recordingHeld = false

	local function hasRecorder(): boolean
		return ride:GetAttribute("HasRecorder") == true
	end

	local function raised(): boolean
		return ride:GetAttribute("EvpRaised") == true
	end

	local function refreshRecorderButton()
		recorderButton.Visible = hasRecorder()
		recorderButton.Text = if raised() then "LOWER" else "REC"
		recorderButton.BackgroundColor3 = if raised()
			then Color3.fromRGB(48, 28, 18)
			else Color3.fromRGB(8, 8, 8)
	end

	local function refreshPanel()
		panel.Visible = raised()
		if not raised() then
			return
		end
		local khz = ride:GetAttribute("EvpKhz")
		local meter = ride:GetAttribute("EvpMeter")
		local locked = ride:GetAttribute("EvpLocked")
		local statusText = ride:GetAttribute("EvpStatus")
		local saved = ride:GetAttribute("EvpSaved")
		khzLabel.Text = string.format("%.1f kHz", if typeof(khz) == "number" then khz else 120)
		meterFill.Size = UDim2.fromScale(math.clamp(if typeof(meter) == "number" then meter else 0, 0, 1), 1)
		local lockedOn = typeof(locked) == "string" and locked ~= ""
		lockDot.BackgroundColor3 = if lockedOn then Constants.COLOR.gLine else Color3.fromRGB(44, 58, 40)
		if typeof(saved) == "string" and saved ~= "" then
			status.Text = "Saved to tape: " .. saved
		elseif typeof(statusText) == "string" then
			status.Text = statusText
		else
			status.Text = ""
		end
		local recordT = ride:GetAttribute("EvpRecordT")
		if typeof(recordT) == "number" and recordT > 0 then
			rec.Text = string.format("REC  %.1fs", recordT)
		else
			rec.Text = "HOLD  REC"
		end
	end

	local function rebuildEvidence()
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local raw = ride:GetAttribute("EvpTapes")
		local tapes = parseTapes(if typeof(raw) == "string" then raw else "[]")
		if #tapes == 0 then
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.Gotham
			empty.Text = "No tapes yet. Raise the recorder (R), tune, and hold REC on a voice."
			empty.TextSize = 13
			empty.TextColor3 = Color3.fromRGB(180, 176, 166)
			empty.TextWrapped = true
			empty.Size = UDim2.new(1, 0, 0, 48)
			empty.Parent = list
		else
			for _, tape in tapes do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 52)
				btn.BackgroundColor3 = Color3.fromRGB(28, 26, 22)
				btn.BorderSizePixel = 0
				btn.AutoButtonColor = true
				btn.Font = Enum.Font.GothamMedium
				btn.Text = tape.title .. "\n" .. tape.freq .. " · " .. tape.stop .. "  [Play]"
				btn.TextColor3 = Constants.COLOR.cream
				btn.TextSize = 13
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = list
				corner(btn, 8)
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft = UDim.new(0, 10)
				pad.PaddingTop = UDim.new(0, 6)
				pad.Parent = btn
				local id = tape.signalId
				btn.MouseButton1Click:Connect(function()
					playRemote:FireServer(id)
				end)
			end
		end
		list.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
	end

	recorderButton.MouseButton1Click:Connect(function()
		toggleRemote:FireServer()
	end)
	evidenceButton.MouseButton1Click:Connect(function()
		evidence.Visible = not evidence.Visible
		if evidence.Visible then
			rebuildEvidence()
		end
	end)
	lower.MouseButton1Click:Connect(function()
		if raised() then
			toggleRemote:FireServer()
		end
	end)
	evClose.MouseButton1Click:Connect(function()
		evidence.Visible = false
	end)
	tuneLeft.MouseButton1Click:Connect(function()
		tuneRemote:FireServer(-0.5)
	end)
	tuneRight.MouseButton1Click:Connect(function()
		tuneRemote:FireServer(0.5)
	end)

	local function setRecording(on: boolean)
		if recordingHeld == on then
			return
		end
		recordingHeld = on
		recordRemote:FireServer(on)
	end

	rec.MouseButton1Down:Connect(function()
		setRecording(true)
	end)
	rec.MouseButton1Up:Connect(function()
		setRecording(false)
	end)
	rec.MouseLeave:Connect(function()
		setRecording(false)
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			toggleRemote:FireServer()
		elseif input.KeyCode == Enum.KeyCode.Tab then
			evidence.Visible = not evidence.Visible
			if evidence.Visible then
				rebuildEvidence()
			end
		elseif raised() then
			if input.KeyCode == Enum.KeyCode.LeftBracket then
				tuneRemote:FireServer(-0.5)
			elseif input.KeyCode == Enum.KeyCode.RightBracket then
				tuneRemote:FireServer(0.5)
			elseif input.KeyCode == Enum.KeyCode.Space then
				setRecording(true)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject, _processed: boolean)
		if input.KeyCode == Enum.KeyCode.Space then
			setRecording(false)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject, processed: boolean)
		if processed or not raised() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local z = input.Position.Z
			tuneRemote:FireServer(if z > 0 then 0.5 else -0.5)
		end
	end)

	ride.AttributeChanged:Connect(function(name: string)
		if
			name == "HasRecorder"
			or name == "EvpRaised"
			or name == "EvpKhz"
			or name == "EvpMeter"
			or name == "EvpLocked"
			or name == "EvpStatus"
			or name == "EvpSaved"
			or name == "EvpRecordT"
		then
			refreshRecorderButton()
			refreshPanel()
		elseif name == "EvpTapes" and evidence.Visible then
			rebuildEvidence()
		end
	end)

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
	end)

	RunService.Heartbeat:Connect(function()
		evidenceButton.Visible = hasRecorder()
		refreshRecorderButton()
	end)

	refreshRecorderButton()
	refreshPanel()
end

return Evp
