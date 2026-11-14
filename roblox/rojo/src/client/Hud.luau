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

local Hud = {}

local flagButton: TextButton? = nil
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

	local strip = label(gui, "[F] FLAG   ·   [WASD] WALK", 13, Color3.fromRGB(220, 216, 206))
	strip.AnchorPoint = Vector2.new(0, 1)
	strip.Position = UDim2.new(0, 14, 1, -18)
	strip.Size = UDim2.fromOffset(220, 22)
	strip.Font = Enum.Font.Code

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

	local dwellCard = Instance.new("Frame")
	dwellCard.Name = "Dwell"
	dwellCard.AnchorPoint = Vector2.new(0.5, 1)
	dwellCard.Position = UDim2.new(0.5, 0, 1, -214)
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
		chapter.Text = textOf("ChapterLine")

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
