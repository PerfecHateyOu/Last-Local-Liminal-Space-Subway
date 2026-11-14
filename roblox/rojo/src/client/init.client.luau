--!strict

local Hud = require(script.Hud)
local Flag = require(script.Flag)
local Walk = require(script.Walk)
local Sway = require(script.Sway)
local Glance = require(script.Glance)
local Audio = require(script.Audio)
local Choice = require(script.Choice)
local Mask = require(script.Mask)
local TrialChoice = require(script.TrialChoice)

Hud.start()
Flag.start(Hud.flagButton())
Audio.start(Hud.muteButton())
Choice.start(Hud.stayButton(), Hud.offButton(), Hud.setChoiceVisible, Hud.setChoiceCountdown)
Mask.start(
	Hud.maskButtonA(),
	Hud.maskButtonB(),
	Hud.maskButtonC(),
	Hud.setMaskVisible,
	Hud.setMaskCountdown,
	Hud.setMaskLabels
)
TrialChoice.start(
	Hud.trialButtonA(),
	Hud.trialButtonB(),
	Hud.trialButtonC(),
	Hud.setTrialVisible,
	Hud.setTrialCountdown,
	Hud.setTrialLabels
)
Walk.start()
Sway.start()
Glance.start()
