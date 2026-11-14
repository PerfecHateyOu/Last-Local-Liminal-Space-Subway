--!strict

local Hud = require(script.Hud)
local Flag = require(script.Flag)
local Walk = require(script.Walk)
local Sway = require(script.Sway)
local Glance = require(script.Glance)
local Audio = require(script.Audio)

Hud.start()
Flag.start(Hud.flagButton())
Audio.start(Hud.muteButton())
Walk.start()
Sway.start()
Glance.start()
