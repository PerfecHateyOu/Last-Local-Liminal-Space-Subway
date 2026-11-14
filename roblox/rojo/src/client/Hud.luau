--!strict
-- On-screen text. The words come from the server (Shared.Lines). This file
-- only places them: the amber PA line, the station card, the suspicion
-- meter, the flag button. Suspicion number and band are Ride attributes;
-- Score and Band stay on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Lines = require(ReplicatedStorage.Shared.Lines)
local Route = require(ReplicatedStorage.Shared.Route)

local Hud = {}

local flagButton: TextButton? = nil
local muteButton: TextButton? = nil
local stayButton: TextButton? = nil
local offButton: TextButton? = nil
local choiceFrame: Frame? = nil
local choiceCountdown: TextLabel? = nil
local maskFrame: Frame? = nil
local maskCountdown: TextLabel? = nil
local maskButtonA: TextButton? = nil
local maskButtonB: TextButton? = nil
local maskButtonC: TextButton? = nil
local trialFrame: Frame? = nil
local trialCountdown: TextLabel? = nil
local trialButtonA: TextButton? = nil
local trialButtonB: TextButton? = nil
local trialButtonC: TextButton? = nil
local recorderButton: TextButton? = nil
local evidenceButton: TextButton? = nil
local progressFill: Frame? = nil

local function corner(parent: Instance, radius: number)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
end

local function label(parent: Instance, text: string, size: number, color: Color3): TextLabel
	local ui = Instance.new("TextLabel")
	ui.BackgroundTransparency = 1
	ui.Font = Enum.Font.GothamMedium
	ui.Text = text
	ui.TextSize = size
	ui.TextColor3 = color
	ui.TextXAlignment = Enum.TextXAlignment.Left
	ui.TextYAlignment = Enum.TextYAlignment.Center
	ui.TextWrapped = true
	ui.Parent = parent
	return ui
end

function Hud.flagButton(): TextButton
	assert(flagButton ~= nil, "Hud.start must run first")
	return flagButton
end

function Hud.muteButton(): TextButton
	assert(muteButton ~= nil, "Hud.start must run first")
	return muteButton
end

function Hud.stayButton(): TextButton
	assert(stayButton ~= nil, "Hud.start must run first")
	return stayButton
end

function Hud.offButton(): TextButton
	assert(offButton ~= nil, "Hud.start must run first")
	return offButton
end

function Hud.setChoiceVisible(visible: boolean)
	local frame = choiceFrame
	if frame ~= nil then
		frame.Visible = visible
	end
end

function Hud.setChoiceCountdown(text: string)
	local countdown = choiceCountdown
	if countdown ~= nil then
		countdown.Text = text
	end
end

function Hud.maskButtonA(): TextButton
	assert(maskButtonA ~= nil, "Hud.start must run first")
	return maskButtonA
end

function Hud.maskButtonB(): TextButton
	assert(maskButtonB ~= nil, "Hud.start must run first")
	return maskButtonB
end

function Hud.maskButtonC(): TextButton
	assert(maskButtonC ~= nil, "Hud.start must run first")
	return maskButtonC
end

function Hud.setMaskVisible(visible: boolean)
	local frame = maskFrame
	if frame ~= nil then
		frame.Visible = visible
	end
end

function Hud.setMaskCountdown(text: string)
	local countdown = maskCountdown
	if countdown ~= nil then
		countdown.Text = text
	end
end

function Hud.setMaskLabels(a: string, b: string, c: string)
	local ba = maskButtonA
	local bb = maskButtonB
	local bc = maskButtonC
	if ba ~= nil then
		ba.Text = "[1]  " .. a
	end
	if bb ~= nil then
		bb.Text = "[2]  " .. b
	end
	if bc ~= nil then
		bc.Text = "[3]  " .. c
	end
end

function Hud.trialButtonA(): TextButton
	assert(trialButtonA ~= nil, "Hud.start must run first")
	return trialButtonA
end

function Hud.trialButtonB(): TextButton
	assert(trialButtonB ~= nil, "Hud.start must run first")
	return trialButtonB
end

function Hud.trialButtonC(): TextButton
	assert(trialButtonC ~= nil, "Hud.start must run first")
	return trialButtonC
end

function Hud.setTrialVisible(visible: boolean)
	local frame = trialFrame
	if frame ~= nil then
		frame.Visible = visible
	end
end

function Hud.setTrialCountdown(text: string)
	local countdown = trialCountdown
	if countdown ~= nil then
		countdown.Text = text
	end
end

function Hud.setTrialLabels(a: string, b: string, c: string, slots: number)
	local ba = trialButtonA
	local bb = trialButtonB
	local bc = trialButtonC
	if ba ~= nil then
		ba.Text = "[1]  " .. a
		ba.Visible = slots >= 1
	end
	if bb ~= nil then
		bb.Text = "[2]  " .. b
		bb.Visible = slots >= 2
	end
	if bc ~= nil then
		bc.Text = "[3]  " .. c
		bc.Visible = slots >= 3
	end
end

function Hud.recorderButton(): TextButton
	assert(recorderButton ~= nil, "Hud.start must run first")
	return recorderButton
end

function Hud.evidenceButton(): TextButton
	assert(evidenceButton ~= nil, "Hud.start must run first")
	return evidenceButton
end

function Hud.setProgress(ratio: number, holding: boolean)
	local fill = progressFill
	local button = flagButton
	if fill == nil or button == nil then
		return
	end
	local clamped = math.clamp(ratio, 0, 1)
	fill.Size = UDim2.fromScale(clamped, 1)
	fill.BackgroundTransparency = if clamped > 0 then 0 else 1
	if holding and clamped > 0 then
		button.BackgroundColor3 = Color3.fromRGB(28, 46, 22)
	else
		button.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	end
end

function Hud.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local ride = ReplicatedStorage:WaitForChild("Ride")

	local gui = Instance.new("ScreenGui")
	gui.Name = "LastLocalHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local card = Instance.new("Frame")
	card.Name = "Station"
	card.AnchorPoint = Vector2.new(0, 0)
	card.Position = UDim2.fromOffset(12, 10)
	card.Size = UDim2.new(0.62, 0, 0, 58)
	card.BackgroundColor3 = Color3.new(0, 0, 0)
	card.BackgroundTransparency = 0.35
	card.BorderSizePixel = 0
	card.Parent = gui
	corner(card, 10)

	local badge = Instance.new("TextLabel")
	badge.Name = "Line"
	badge.BackgroundColor3 = Constants.COLOR.gLine
	badge.TextColor3 = Color3.new(0, 0, 0)
	badge.Font = Enum.Font.GothamBold
	badge.Text = "G"
	badge.TextSize = 16
	badge.AnchorPoint = Vector2.new(0, 0)
	badge.Position = UDim2.fromOffset(8, 8)
	badge.Size = UDim2.fromOffset(26, 26)
	badge.Parent = card
	corner(badge, 13)

	local nextLabel = label(card, Lines.NEXT_LABEL, 14, Color3.fromRGB(180, 176, 166))
	nextLabel.Position = UDim2.fromOffset(42, 6)
	nextLabel.Size = UDim2.fromOffset(48, 20)

	local nextName = label(card, "", 16, Constants.COLOR.cream)
	nextName.Name = "NextStop"
	nextName.Font = Enum.Font.GothamBold
	nextName.Position = UDim2.fromOffset(92, 6)
	nextName.Size = UDim2.new(1, -100, 0, 20)

	local chapter = label(card, "", 11, Color3.fromRGB(210, 206, 196))
	chapter.Name = "Chapter"
	chapter.Font = Enum.Font.Gotham
	chapter.Position = UDim2.fromOffset(42, 30)
	chapter.Size = UDim2.new(1, -50, 0, 20)

	local susCard = Instance.new("Frame")
	susCard.Name = "Suspicion"
	susCard.AnchorPoint = Vector2.new(0, 0)
	susCard.Position = UDim2.fromOffset(12, 76)
	susCard.Size = UDim2.fromOffset(168, 48)
	susCard.BackgroundColor3 = Color3.new(0, 0, 0)
	susCard.BackgroundTransparency = 0.35
	susCard.BorderSizePixel = 0
	susCard.Parent = gui
	corner(susCard, 10)

	local susTitle = label(susCard, "SUSPICION", 11, Color3.fromRGB(180, 176, 166))
	susTitle.Name = "Title"
	susTitle.Font = Enum.Font.Code
	susTitle.Position = UDim2.fromOffset(10, 4)
	susTitle.Size = UDim2.new(1, -20, 0, 14)

	local susValue = label(susCard, Lines.suspicionMeter(0, "calm"), 16, Constants.COLOR.warn)
	susValue.Name = "Value"
	susValue.Font = Enum.Font.GothamBold
	susValue.Position = UDim2.fromOffset(10, 18)
	susValue.Size = UDim2.new(1, -20, 0, 18)

	local susBarBack = Instance.new("Frame")
	susBarBack.Name = "Bar"
	susBarBack.Position = UDim2.fromOffset(10, 38)
	susBarBack.Size = UDim2.new(1, -20, 0, 4)
	susBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	susBarBack.BorderSizePixel = 0
	susBarBack.Parent = susCard
	corner(susBarBack, 2)

	local susBarFill = Instance.new("Frame")
	susBarFill.Name = "Fill"
	susBarFill.Size = UDim2.fromScale(0, 1)
	susBarFill.BackgroundColor3 = Constants.COLOR.gLine
	susBarFill.BorderSizePixel = 0
	susBarFill.Parent = susBarBack
	corner(susBarFill, 2)

	local pa = Instance.new("TextLabel")
	pa.Name = "PA"
	pa.AnchorPoint = Vector2.new(0.5, 0)
	pa.Position = UDim2.new(0.5, 0, 0, 132)
	pa.Size = UDim2.new(0.92, 0, 0, 28)
	pa.AutomaticSize = Enum.AutomaticSize.Y
	pa.BackgroundColor3 = Constants.COLOR.paBg
	pa.BackgroundTransparency = 0.05
	pa.BorderSizePixel = 0
	pa.Font = Enum.Font.GothamBold
	pa.TextColor3 = Constants.COLOR.warn
	pa.TextSize = 18
	pa.TextWrapped = true
	pa.Text = ""
	pa.Visible = false
	pa.Parent = gui
	corner(pa, 6)

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0, 174)
	hint.Size = UDim2.new(0.9, 0, 0, 28)
	hint.AutomaticSize = Enum.AutomaticSize.Y
	hint.BackgroundColor3 = Color3.new(0, 0, 0)
	hint.BackgroundTransparency = 0.25
	hint.BorderSizePixel = 0
	hint.Font = Enum.Font.Gotham
	hint.TextColor3 = Constants.COLOR.cream
	hint.TextSize = 14
	hint.TextWrapped = true
	hint.Text = ""
	hint.Visible = false
	hint.Parent = gui
	corner(hint, 6)

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 1)
	subtitle.Position = UDim2.new(0.5, 0, 1, -118)
	subtitle.Size = UDim2.new(0.9, 0, 0, 48)
	subtitle.BackgroundColor3 = Color3.new(0, 0, 0)
	subtitle.BackgroundTransparency = 0.25
	subtitle.BorderSizePixel = 0
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextColor3 = Constants.COLOR.cream
	subtitle.TextSize = 16
	subtitle.TextWrapped = true
	subtitle.Text = ""
	subtitle.Visible = false
	subtitle.Parent = gui
	corner(subtitle, 6)

	local feedback = Instance.new("TextLabel")
	feedback.Name = "Feedback"
	feedback.AnchorPoint = Vector2.new(0.5, 1)
	feedback.Position = UDim2.new(0.5, 0, 1, -172)
	feedback.Size = UDim2.new(0.86, 0, 0, 32)
	feedback.BackgroundTransparency = 1
	feedback.Font = Enum.Font.GothamBold
	feedback.TextColor3 = Constants.COLOR.cream
	feedback.TextSize = 20
	feedback.TextWrapped = true
	feedback.Text = ""
	feedback.Visible = false
	feedback.Parent = gui

	local strip = label(gui, "[F] FLAG   ·   [R] REC   ·   [TAB] EVIDENCE   ·   [M] MUTE", 13, Color3.fromRGB(220, 216, 206))
	strip.AnchorPoint = Vector2.new(0, 1)
	strip.Position = UDim2.new(0, 14, 1, -18)
	strip.Size = UDim2.fromOffset(460, 22)
	strip.Font = Enum.Font.Code

	local mute = Instance.new("TextButton")
	mute.Name = "Mute"
	mute.AnchorPoint = Vector2.new(0, 1)
	mute.Position = UDim2.new(0, 14, 1, -48)
	mute.Size = UDim2.fromOffset(72, 28)
	mute.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	mute.BackgroundTransparency = 0.15
	mute.BorderSizePixel = 0
	mute.AutoButtonColor = true
	mute.Font = Enum.Font.GothamBold
	mute.Text = Lines.MUTE
	mute.TextColor3 = Constants.COLOR.cream
	mute.TextSize = 12
	mute.Parent = gui
	corner(mute, 6)
	muteButton = mute

	local recorder = Instance.new("TextButton")
	recorder.Name = "Recorder"
	recorder.AnchorPoint = Vector2.new(0, 1)
	recorder.Position = UDim2.new(0, 94, 1, -48)
	recorder.Size = UDim2.fromOffset(64, 28)
	recorder.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	recorder.BackgroundTransparency = 0.15
	recorder.BorderSizePixel = 0
	recorder.AutoButtonColor = true
	recorder.Font = Enum.Font.GothamBold
	recorder.Text = "REC"
	recorder.TextColor3 = Constants.COLOR.cream
	recorder.TextSize = 12
	recorder.Visible = false
	recorder.Parent = gui
	corner(recorder, 6)
	recorderButton = recorder

	local evidenceBtn = Instance.new("TextButton")
	evidenceBtn.Name = "Evidence"
	evidenceBtn.AnchorPoint = Vector2.new(0, 1)
	evidenceBtn.Position = UDim2.new(0, 166, 1, -48)
	evidenceBtn.Size = UDim2.fromOffset(88, 28)
	evidenceBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	evidenceBtn.BackgroundTransparency = 0.15
	evidenceBtn.BorderSizePixel = 0
	evidenceBtn.AutoButtonColor = true
	evidenceBtn.Font = Enum.Font.GothamBold
	evidenceBtn.Text = "EVIDENCE"
	evidenceBtn.TextColor3 = Constants.COLOR.cream
	evidenceBtn.TextSize = 11
	evidenceBtn.Visible = false
	evidenceBtn.Parent = gui
	corner(evidenceBtn, 6)
	evidenceButton = evidenceBtn

	local barBack = Instance.new("Frame")
	barBack.Name = "FlagBar"
	barBack.AnchorPoint = Vector2.new(1, 1)
	barBack.Position = UDim2.new(1, -16, 1, -112)
	barBack.Size = UDim2.fromOffset(88, 6)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBack.BorderSizePixel = 0
	barBack.Parent = gui
	corner(barBack, 3)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Constants.COLOR.gLine
	fill.BorderSizePixel = 0
	fill.Parent = barBack
	corner(fill, 3)
	progressFill = fill

	local button = Instance.new("TextButton")
	button.Name = "Flag"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -16, 1, -16)
	button.Size = UDim2.fromOffset(88, 88)
	button.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.Text = "FLAG"
	button.TextColor3 = Constants.COLOR.cream
	button.TextSize = 16
	button.TextYAlignment = Enum.TextYAlignment.Top
	button.Parent = gui
	corner(button, 44)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 22)
	pad.Parent = button
	local hold = label(button, "hold to catch", 11, Color3.fromRGB(210, 206, 196))
	hold.AnchorPoint = Vector2.new(0.5, 0)
	hold.Position = UDim2.new(0.5, 0, 0, 28)
	hold.Size = UDim2.new(1, -8, 0, 28)
	hold.TextXAlignment = Enum.TextXAlignment.Center
	hold.Font = Enum.Font.Gotham
	local buttonScale = Instance.new("UIScale")
	buttonScale.Parent = button
	flagButton = button

	local doorsCard = Instance.new("Frame")
	doorsCard.Name = "DoorChoice"
	doorsCard.AnchorPoint = Vector2.new(0.5, 1)
	doorsCard.Position = UDim2.new(0.5, 0, 1, -214)
	doorsCard.Size = UDim2.fromOffset(340, 118)
	doorsCard.BackgroundColor3 = Color3.new(0, 0, 0)
	doorsCard.BackgroundTransparency = 0.28
	doorsCard.BorderSizePixel = 0
	doorsCard.Visible = false
	doorsCard.Parent = gui
	corner(doorsCard, 10)
	choiceFrame = doorsCard

	local doorsTitle = label(doorsCard, Lines.DOOR_PROMPT, 14, Constants.COLOR.warn)
	doorsTitle.Name = "Title"
	doorsTitle.Font = Enum.Font.GothamBold
	doorsTitle.Position = UDim2.fromOffset(12, 8)
	doorsTitle.Size = UDim2.new(1, -24, 0, 20)
	doorsTitle.TextXAlignment = Enum.TextXAlignment.Center

	local doorsCount = label(doorsCard, "", 12, Color3.fromRGB(180, 176, 166))
	doorsCount.Name = "Countdown"
	doorsCount.Font = Enum.Font.Code
	doorsCount.Position = UDim2.fromOffset(12, 30)
	doorsCount.Size = UDim2.new(1, -24, 0, 16)
	doorsCount.TextXAlignment = Enum.TextXAlignment.Center
	choiceCountdown = doorsCount

	local stay = Instance.new("TextButton")
	stay.Name = "Stay"
	stay.Position = UDim2.fromOffset(16, 56)
	stay.Size = UDim2.fromOffset(148, 48)
	stay.BackgroundColor3 = Color3.fromRGB(28, 46, 22)
	stay.BackgroundTransparency = 0.1
	stay.BorderSizePixel = 0
	stay.AutoButtonColor = true
	stay.Font = Enum.Font.GothamBold
	stay.Text = "[1]  " .. Lines.STAY_ON
	stay.TextColor3 = Constants.COLOR.cream
	stay.TextSize = 15
	stay.Parent = doorsCard
	corner(stay, 8)
	stayButton = stay

	local stepOff = Instance.new("TextButton")
	stepOff.Name = "StepOff"
	stepOff.Position = UDim2.fromOffset(176, 56)
	stepOff.Size = UDim2.fromOffset(148, 48)
	stepOff.BackgroundColor3 = Color3.fromRGB(48, 28, 18)
	stepOff.BackgroundTransparency = 0.1
	stepOff.BorderSizePixel = 0
	stepOff.AutoButtonColor = true
	stepOff.Font = Enum.Font.GothamBold
	stepOff.Text = "[2]  " .. Lines.STEP_OFF
	stepOff.TextColor3 = Constants.COLOR.cream
	stepOff.TextSize = 15
	stepOff.Parent = doorsCard
	corner(stepOff, 8)
	offButton = stepOff

	local masksCard = Instance.new("Frame")
	masksCard.Name = "MaskChoice"
	masksCard.AnchorPoint = Vector2.new(0.5, 1)
	masksCard.Position = UDim2.new(0.5, 0, 1, -214)
	masksCard.Size = UDim2.fromOffset(360, 168)
	masksCard.BackgroundColor3 = Color3.new(0, 0, 0)
	masksCard.BackgroundTransparency = 0.28
	masksCard.BorderSizePixel = 0
	masksCard.Visible = false
	masksCard.Parent = gui
	corner(masksCard, 10)
	maskFrame = masksCard

	local masksTitle = label(masksCard, "Answer carefully.", 14, Constants.COLOR.warn)
	masksTitle.Name = "Title"
	masksTitle.Font = Enum.Font.GothamBold
	masksTitle.Position = UDim2.fromOffset(12, 8)
	masksTitle.Size = UDim2.new(1, -24, 0, 18)
	masksTitle.TextXAlignment = Enum.TextXAlignment.Center

	local masksCount = label(masksCard, "", 12, Color3.fromRGB(180, 176, 166))
	masksCount.Name = "Countdown"
	masksCount.Font = Enum.Font.Code
	masksCount.Position = UDim2.fromOffset(12, 28)
	masksCount.Size = UDim2.new(1, -24, 0, 16)
	masksCount.TextXAlignment = Enum.TextXAlignment.Center
	maskCountdown = masksCount

	local function maskBtn(name: string, y: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Position = UDim2.fromOffset(16, y)
		btn.Size = UDim2.new(1, -32, 0, 36)
		btn.BackgroundColor3 = Color3.fromRGB(22, 28, 36)
		btn.BackgroundTransparency = 0.1
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Font = Enum.Font.GothamMedium
		btn.Text = ""
		btn.TextColor3 = Constants.COLOR.cream
		btn.TextSize = 14
		btn.TextWrapped = true
		btn.Parent = masksCard
		corner(btn, 8)
		return btn
	end

	maskButtonA = maskBtn("MaskA", 50)
	maskButtonB = maskBtn("MaskB", 90)
	maskButtonC = maskBtn("MaskC", 130)

	local trialCard = Instance.new("Frame")
	trialCard.Name = "TrialChoice"
	trialCard.AnchorPoint = Vector2.new(0.5, 1)
	trialCard.Position = UDim2.new(0.5, 0, 1, -214)
	trialCard.Size = UDim2.fromOffset(360, 168)
	trialCard.BackgroundColor3 = Color3.new(0, 0, 0)
	trialCard.BackgroundTransparency = 0.28
	trialCard.BorderSizePixel = 0
	trialCard.Visible = false
	trialCard.Parent = gui
	corner(trialCard, 10)
	trialFrame = trialCard

	local trialTitle = label(trialCard, "Find the way back.", 14, Constants.COLOR.warn)
	trialTitle.Name = "Title"
	trialTitle.Font = Enum.Font.GothamBold
	trialTitle.Position = UDim2.fromOffset(12, 8)
	trialTitle.Size = UDim2.new(1, -24, 0, 18)
	trialTitle.TextXAlignment = Enum.TextXAlignment.Center

	local trialCount = label(trialCard, "", 12, Color3.fromRGB(180, 176, 166))
	trialCount.Name = "Countdown"
	trialCount.Font = Enum.Font.Code
	trialCount.Position = UDim2.fromOffset(12, 28)
	trialCount.Size = UDim2.new(1, -24, 0, 16)
	trialCount.TextXAlignment = Enum.TextXAlignment.Center
	trialCountdown = trialCount

	local function trialBtn(name: string, y: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Position = UDim2.fromOffset(16, y)
		btn.Size = UDim2.new(1, -32, 0, 36)
		btn.BackgroundColor3 = Color3.fromRGB(36, 28, 22)
		btn.BackgroundTransparency = 0.1
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Font = Enum.Font.GothamMedium
		btn.Text = ""
		btn.TextColor3 = Constants.COLOR.cream
		btn.TextSize = 14
		btn.TextWrapped = true
		btn.Parent = trialCard
		corner(btn, 8)
		return btn
	end

	trialButtonA = trialBtn("TrialA", 50)
	trialButtonB = trialBtn("TrialB", 90)
	trialButtonC = trialBtn("TrialC", 130)

	local dwellCard = Instance.new("Frame")
	dwellCard.Name = "Dwell"
	dwellCard.AnchorPoint = Vector2.new(0.5, 1)
	dwellCard.Position = UDim2.new(0.5, 0, 1, -340)
	dwellCard.Size = UDim2.fromOffset(280, 54)
	dwellCard.BackgroundColor3 = Color3.new(0, 0, 0)
	dwellCard.BackgroundTransparency = 0.35
	dwellCard.BorderSizePixel = 0
	dwellCard.Visible = false
	dwellCard.Parent = gui
	corner(dwellCard, 10)

	local dwellTitle = label(dwellCard, Lines.MIN_DWELL, 13, Constants.COLOR.warn)
	dwellTitle.Name = "Title"
	dwellTitle.Font = Enum.Font.GothamBold
	dwellTitle.Position = UDim2.fromOffset(12, 4)
	dwellTitle.Size = UDim2.new(1, -24, 0, 18)

	local dwellCount = label(dwellCard, "", 22, Constants.COLOR.cream)
	dwellCount.Name = "Countdown"
	dwellCount.Font = Enum.Font.GothamBold
	dwellCount.Position = UDim2.fromOffset(12, 22)
	dwellCount.Size = UDim2.new(1, -24, 0, 28)

	local boardCard = Instance.new("Frame")
	boardCard.Name = "CountdownBoard"
	boardCard.AnchorPoint = Vector2.new(1, 0)
	boardCard.Position = UDim2.new(1, -12, 0, 10)
	boardCard.Size = UDim2.fromOffset(168, 58)
	boardCard.BackgroundColor3 = Color3.new(0, 0, 0)
	boardCard.BackgroundTransparency = 0.35
	boardCard.BorderSizePixel = 0
	boardCard.Visible = false
	boardCard.Parent = gui
	corner(boardCard, 10)

	local boardNext = label(boardCard, Lines.NEXT_LABEL, 13, Color3.fromRGB(180, 176, 166))
	boardNext.Position = UDim2.fromOffset(10, 6)
	boardNext.Size = UDim2.new(1, -20, 0, 16)

	local boardName = label(boardCard, "", 15, Constants.COLOR.cream)
	boardName.Name = "Stop"
	boardName.Font = Enum.Font.GothamBold
	boardName.Position = UDim2.fromOffset(10, 22)
	boardName.Size = UDim2.new(1, -20, 0, 16)

	local boardMinutes = label(boardCard, "", 13, Constants.COLOR.warn)
	boardMinutes.Name = "Minutes"
	boardMinutes.Font = Enum.Font.GothamBold
	boardMinutes.Position = UDim2.fromOffset(10, 38)
	boardMinutes.Size = UDim2.new(1, -20, 0, 16)

	local cross = Instance.new("Frame")
	cross.Name = "Crosshair"
	cross.AnchorPoint = Vector2.new(0.5, 0.5)
	cross.Position = UDim2.fromScale(0.5, 0.5)
	cross.Size = UDim2.fromOffset(5, 5)
	cross.BackgroundColor3 = Constants.COLOR.cream
	cross.BackgroundTransparency = 0.15
	cross.BorderSizePixel = 0
	cross.Active = false
	cross.Parent = gui
	corner(cross, 3)

	local function textOf(name: string): string
		local value = ride:GetAttribute(name)
		if typeof(value) == "string" then
			return value
		end
		return ""
	end

	local function refresh()
		local stopName = textOf("NextStop")
		nextName.Text = stopName
		nextLabel.Visible = stopName ~= ""
		local chapterLine = textOf("ChapterLine")
		local character = Players.LocalPlayer.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if root ~= nil and root:IsA("BasePart") then
			local xMetres = root.Position.X / Constants.STUDS_PER_METER
			chapter.Text = Route.withCarLabel(chapterLine, Route.carLabel(xMetres))
		else
			chapter.Text = chapterLine
		end

		local susAttr = ride:GetAttribute("Suspicion")
		local sus = if typeof(susAttr) == "number" then susAttr else 0
		local band = textOf("Band")
		if band == "" then
			band = "calm"
		end
		susValue.Text = Lines.suspicionMeter(sus, band)
		local ratio = math.clamp(sus / 100, 0, 1)
		susBarFill.Size = UDim2.fromScale(ratio, 1)
		if band == "hunted" then
			susValue.TextColor3 = Color3.fromRGB(220, 96, 72)
			susBarFill.BackgroundColor3 = Color3.fromRGB(220, 96, 72)
		elseif band == "watched" or band == "uneasy" then
			susValue.TextColor3 = Constants.COLOR.warn
			susBarFill.BackgroundColor3 = Constants.COLOR.warn
		else
			susValue.TextColor3 = Constants.COLOR.cream
			susBarFill.BackgroundColor3 = Constants.COLOR.gLine
		end

		local boardStop = textOf("BoardStop")
		local minutesValue = ride:GetAttribute("BoardMinutes")
		local minutes = if typeof(minutesValue) == "number" then minutesValue else nil
		boardCard.Visible = boardStop ~= "" and minutes ~= nil
		boardName.Text = boardStop
		boardMinutes.Text = if minutes ~= nil then Lines.minutesLabel(minutes) else ""

		local paText = textOf("PaText")
		pa.Text = paText
		pa.Visible = paText ~= ""

		local hintText = textOf("Hint")
		hint.Text = hintText
		hint.Visible = hintText ~= ""

		local subText = textOf("Subtitle")
		subtitle.Text = subText
		subtitle.Visible = subText ~= ""

		local feedbackText = textOf("Feedback")
		feedback.Text = feedbackText
		feedback.Visible = feedbackText ~= ""
		local kind = textOf("FeedbackKind")
		if kind == "caught" then
			feedback.TextColor3 = Constants.COLOR.gLine
		elseif kind == "false" or kind == "missed" then
			feedback.TextColor3 = Constants.COLOR.warn
		else
			feedback.TextColor3 = Constants.COLOR.cream
		end
	end

	RunService.Heartbeat:Connect(function()
		local chapterLine = textOf("ChapterLine")
		local character = Players.LocalPlayer.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if root ~= nil and root:IsA("BasePart") then
			local xMetres = root.Position.X / Constants.STUDS_PER_METER
			chapter.Text = Route.withCarLabel(chapterLine, Route.carLabel(xMetres))
		end

		local deadline = ride:GetAttribute("DwellUntil")
		if typeof(deadline) ~= "number" or deadline <= 0 then
			dwellCard.Visible = false
			return
		end
		local remain = deadline - workspace:GetServerTimeNow()
		if remain <= 0 then
			dwellCard.Visible = false
			return
		end
		dwellCard.Visible = true
		dwellCount.Text = Lines.dwellCountdown(remain)
	end)

	ride.AttributeChanged:Connect(function(name: string)
		if name == "Feedback" and textOf("Feedback") ~= "" then
			buttonScale.Scale = 1.08
			task.delay(0.18, function()
				buttonScale.Scale = 1
			end)
		end
		refresh()
	end)
	refresh()
end

return Hud
