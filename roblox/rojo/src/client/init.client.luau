--!strict

local Hud = require(script.Hud)
local Flag = require(script.Flag)
local Walk = require(script.Walk)
local Sway = require(script.Sway)
local Glance = require(script.Glance)
local Audio = require(script.Audio)
local Choice = require(script.Choice)

Hud.start()
Flag.start(Hud.flagButton())
Audio.start(Hud.muteButton())
Choice.start(Hud.stayButton(), Hud.offButton(), Hud.setChoiceVisible, Hud.setChoiceCountdown)
Walk.start()
Sway.start()
Glance.start()
