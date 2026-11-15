--!strict
-- Night lighting matched to the web game's scene setup (App.tsx and
-- subwayCarBuilder.setupLighting / gameState.applyLighting).
--
-- Web: background 0x030403, fog 0x040504 from 9 m to 30 m, ACES exposure 1.05,
-- ambient white at 0.15, hemisphere 0xfff3dc / 0x5a5850 at 0.65 then scaled
-- in applyLighting, point lights 0xfff0d4 at intensity 0.55. Roblox's default
-- Future exposure plus SmoothPlastic turns that same paint white, which is
-- what the Studio playtest showed. Exposure is pulled down and the fill is
-- kept low so the ceiling pools stay local.
--
-- This only touches the Lighting service. It never writes the car lamps.
-- The flicker tick and the slow dim still own those. A Held At Signal
-- pause does not come through here: one strip or a slow dim stays on the
-- car lamps, and this service never blacks the car out.
--
-- Lighting.Technology is a place property only (default.project.json Future).
-- Runtime writes need RobloxScript and abort server init before Ride.start.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trestle = require(ReplicatedStorage.Shared.Trestle)

local WorldLight = {}

local applying = false
local openAir = 0

local function killDefaultSky()
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end
end

local function atmosphere(): Atmosphere
	local existing = Lighting:FindFirstChild("TunnelAir")
	if existing ~= nil and existing:IsA("Atmosphere") then
		return existing
	end
	if existing ~= nil then
		existing:Destroy()
	end
	local air = Instance.new("Atmosphere")
	air.Name = "TunnelAir"
	air.Parent = Lighting
	return air
end

local function grade(): ColorCorrectionEffect
	local existing = Lighting:FindFirstChild("CarGrade")
	if existing ~= nil and existing:IsA("ColorCorrectionEffect") then
		return existing
	end
	if existing ~= nil then
		existing:Destroy()
	end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "CarGrade"
	effect.Parent = Lighting
	return effect
end

local function bloom(): BloomEffect
	local existing = Lighting:FindFirstChild("LampBloom")
	if existing ~= nil and existing:IsA("BloomEffect") then
		return existing
	end
	if existing ~= nil then
		existing:Destroy()
	end
	local effect = Instance.new("BloomEffect")
	effect.Name = "LampBloom"
	effect.Parent = Lighting
	return effect
end

function WorldLight.apply()
	if applying then
		return
	end
	applying = true

	killDefaultSky()

	-- Do not write Lighting.Technology (place property / RobloxScript only).
	-- Brightness 0 and midnight kill the sun. Scales at 0 kill the skybox fill.
	Lighting.Brightness = 0
	Lighting.ClockTime = 0
	Lighting.GeographicLatitude = 0
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
	Lighting.ExposureCompensation = -0.85
	-- Web ambient is 0.15 white, which is a dim fill, not a white wash.
	Lighting.Ambient = Color3.fromRGB(12, 11, 10)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	-- App.tsx: fog 0x040504, near 9 m, far 30 m. Trestle outside lerps to sodium dusk.
	local k = openAir
	local tunnelFog = Color3.fromRGB(Trestle.TUNNEL_FOG_RGB[1], Trestle.TUNNEL_FOG_RGB[2], Trestle.TUNNEL_FOG_RGB[3])
	local trestleFog = Color3.fromRGB(Trestle.FOG_RGB[1], Trestle.FOG_RGB[2], Trestle.FOG_RGB[3])
	Lighting.FogColor = tunnelFog:Lerp(trestleFog, k)
	Lighting.FogStart = Trestle.TUNNEL_FOG_START + (Trestle.OPEN_FOG_START - Trestle.TUNNEL_FOG_START) * k
	Lighting.FogEnd = Trestle.TUNNEL_FOG_END + (Trestle.OPEN_FOG_END - Trestle.TUNNEL_FOG_END) * k

	local air = atmosphere()
	air.Density = 0.45 - 0.12 * k
	air.Offset = 0
	air.Color = tunnelFog:Lerp(trestleFog, k)
	air.Decay = Color3.fromRGB(3, 4, 3):Lerp(Color3.fromRGB(40, 24, 16), k)
	air.Glare = 0.05 * k
	air.Haze = 1.1 + 0.4 * k

	local correction = grade()
	correction.Brightness = -0.05
	correction.Contrast = 0.16
	correction.Saturation = -0.14
	correction.TintColor = Color3.fromRGB(206, 222, 198)

	-- Only the hottest pixels (the tubes) bloom. Walls stay matte.
	local glow = bloom()
	glow.Enabled = true
	glow.Intensity = 0.12
	glow.Size = 14
	glow.Threshold = 1.45

	applying = false
end

-- 0 = tunnel murk, 1 = Newtown Creek open air (web trestleOutside).
function WorldLight.setOpenAir(level: number)
	local nextLevel = math.clamp(level, 0, 1)
	if math.abs(nextLevel - openAir) < 0.02 then
		return
	end
	openAir = nextLevel
	local ok, err = pcall(WorldLight.apply)
	if not ok then
		warn("[WorldLight] setOpenAir apply failed: ", err)
	end
end

function WorldLight.bind()
	-- Never let a restricted Lighting write abort server init before Ride.
	local ok, err = pcall(WorldLight.apply)
	if not ok then
		warn("[WorldLight] bind apply failed: ", err)
	end
	Lighting.Changed:Connect(function(property: string)
		if
			property == "Brightness"
			or property == "Ambient"
			or property == "OutdoorAmbient"
			or property == "ClockTime"
			or property == "ExposureCompensation"
			or property == "EnvironmentDiffuseScale"
		then
			local reOk, reErr = pcall(WorldLight.apply)
			if not reOk then
				warn("[WorldLight] re-apply failed: ", reErr)
			end
		end
	end)
	Lighting.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Sky") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end)
end

return WorldLight
