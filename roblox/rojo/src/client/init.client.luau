--!strict

local Hud = require(script.Hud)
local Flag = require(script.Flag)
local Walk = require(script.Walk)
local Sway = require(script.Sway)

Hud.start()
Flag.start(Hud.flagButton())
Walk.start()
Sway.start()
