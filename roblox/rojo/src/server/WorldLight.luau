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
-- The flicker tick and the slow dim still own those.

local Lighting = game:GetService("Lighting")

local WorldLight = {}

local applying = false

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

	-- Future so shadows and exposure actually apply. Brightness 0 and
	-- midnight kill the sun. Scales at 0 kill the skybox fill.
	Lighting.Technology = Enum.Technology.Future
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
	-- App.tsx: fog 0x040504, near 9 m, far 30 m.
	Lighting.FogColor = Color3.fromRGB(4, 5, 4)
	Lighting.FogStart = 9 * 3
	Lighting.FogEnd = 30 * 3

	local air = atmosphere()
	air.Density = 0.45
	air.Offset = 0
	air.Color = Color3.fromRGB(4, 5, 4)
	air.Decay = Color3.fromRGB(3, 4, 3)
	air.Glare = 0
	air.Haze = 1.1

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

function WorldLight.bind()
	WorldLight.apply()
	Lighting.Changed:Connect(function(property: string)
		if property == "Brightness" or property == "Ambient" or property == "OutdoorAmbient" or property == "ClockTime" or property == "Technology" or property == "ExposureCompensation" or property == "EnvironmentDiffuseScale" then
			WorldLight.apply()
		end
	end)
	Lighting.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Sky") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end)
end

return WorldLight
