--!strict
-- The tunnel and the two platforms. The car stays in place (players are in
-- it). Scenery streams toward +X as the odometer rises, which is the web
-- game's FORWARD_X = -1: something still ahead sits at negative X.
--
-- Tunnel lamps are Neon parts with no PointLight. They cannot light the
-- car, so a lamp passing a window does not flicker the interior. The only
-- lights that fill the car are the ceiling lamps in CarBuilder.
--
-- Near 21 St the Newtown Creek trestle replaces the tunnel loop: steel
-- bents, rain strips, dusk fog, open-air platforms (setOpenAir).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Scenery = {}

export type Station = {
	model: Model,
	base: number,
	labels: { TextLabel },
	wall: BasePart?,
	trim: BasePart?,
}

type Piece = {
	part: BasePart,
	base: number,
	y: number,
	z: number,
	period: number,
	rotation: CFrame,
	tunnel: boolean?,
}

local pieces: { Piece } = {}
local stations: { Station } = {}
local trestleSteel: { Piece } = {}
local trestleFolder: Folder? = nil
local rainParts: { BasePart } = {}
local openAirLevel = 0

local WALL = Color3.fromRGB(24, 26, 24)
local PIER = Color3.fromRGB(36, 39, 36)
local LAMP = Color3.fromRGB(255, 216, 150)
local PLATFORM = Color3.fromRGB(141, 138, 130)
local YELLOW = Color3.fromRGB(227, 195, 65)
local COLUMN = Color3.fromRGB(45, 72, 56)
local TRIM = Color3.fromRGB(63, 122, 82)
local BED = Color3.fromRGB(18, 18, 16)
local STEEL = Color3.fromRGB(42, 46, 51)
local RUST = Color3.fromRGB(58, 42, 36)
local WATER = Color3.fromRGB(7, 9, 18)
local SKY = Color3.fromRGB(12, 16, 34)
local HAZE = Color3.fromRGB(255, 153, 68)

local LOOP = 84
local BENT_SPACING = 9
local BENT_WRAP = 90

local function metres(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z) * Constants.STUDS_PER_METER
end

local function loopX(base: number, odo: number, period: number): number
	local rel = (base - odo) % period
	if rel < 0 then
		rel += period
	end
	if rel > period / 2 then
		rel -= period
	end
	return -rel
end

local function trackPart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = parent
	return part
end

local function addLoop(
	parent: Instance,
	name: string,
	count: number,
	spacing: number,
	length: number,
	y: number,
	z: number,
	height: number,
	depth: number,
	color: Color3,
	material: Enum.Material?
)
	local period = count * spacing
	for i = 0, count - 1 do
		local part = trackPart(parent, name, metres(length, height, depth), CFrame.new(metres(0, y, z)), color, material)
		table.insert(pieces, {
			part = part,
			base = i * spacing,
			y = part.Position.Y,
			z = part.Position.Z,
			period = period,
			rotation = CFrame.identity,
			tunnel = true,
		})
	end
end

local function addSign(model: Model, labels: { TextLabel }, x: number)
	local part = trackPart(model, "Sign", metres(3.6, 0.42, 0.08), CFrame.new(metres(x, 1.72, -2.22)), Color3.fromRGB(8, 8, 8))
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Name"
		gui.Face = face
		gui.LightInfluence = 0
		gui.MaxDistance = 140
		gui.CanvasSize = Vector2.new(480, 72)
		gui.Parent = part
		local label = Instance.new("TextLabel")
		label.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		label.BorderSizePixel = 0
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Constants.COLOR.cream
		label.TextScaled = true
		label.Text = ""
		label.Parent = gui
		table.insert(labels, label)
	end
end

local function buildStation(): Station
	local model = Instance.new("Model")
	model.Name = "Station"
	local labels: { TextLabel } = {}

	local wall = trackPart(model, "Wall", metres(44, 3.2, 0.16), CFrame.new(metres(0, 1.35, -2.55)), Color3.fromRGB(42, 48, 44))
	local trim = trackPart(model, "Trim", metres(44, 0.16, 0.06), CFrame.new(metres(0, 2.35, -2.46)), TRIM)
	trackPart(model, "Floor", metres(44, 0.16, 0.9), CFrame.new(metres(0, -0.08, -2.05)), PLATFORM, Enum.Material.Concrete)
	trackPart(model, "Edge", metres(44, 0.04, 0.14), CFrame.new(metres(0, 0.02, -1.68)), YELLOW)
	for x = -20, 20, 5 do
		trackPart(model, "Column", metres(0.18, 3.1, 0.18), CFrame.new(metres(x, 1.5, -2.15)), COLUMN)
	end
	for x = -15, 15, 10 do
		addSign(model, labels, x)
	end
	-- Neon only. A PointLight here would wash the car when the platform arrives.
	for x = -18, 18, 6 do
		local lamp = trackPart(model, "PlatformLamp", metres(1.4, 0.06, 0.14), CFrame.new(metres(x, 2.85, -2.0)), LAMP)
		lamp.Material = Enum.Material.Neon
	end

	local root = trackPart(model, "Root", Vector3.new(0.2, 0.2, 0.2), CFrame.new(), WALL)
	root.Transparency = 1
	model.PrimaryPart = root
	model.Parent = workspace
	return {
		model = model,
		base = 0,
		labels = labels,
		wall = wall,
		trim = trim,
	}
end

local function buildTrestle()
	local folder = Instance.new("Folder")
	folder.Name = "Trestle"
	folder.Parent = workspace
	trestleFolder = folder

	-- Dusk dome stand-in: large inverted shell (Part), not a skybox art pass.
	local dome = trackPart(folder, "Sky", metres(160, 80, 160), CFrame.new(metres(0, 20, 0)), SKY)
	dome.Transparency = 0.35
	dome.Material = Enum.Material.SmoothPlastic
	dome.Shape = Enum.PartType.Ball
	local haze = trackPart(folder, "Haze", metres(120, 4, 120), CFrame.new(metres(0, -2, 0)), HAZE)
	haze.Transparency = 0.7

	local water = trackPart(folder, "Water", metres(200, 0.2, 200), CFrame.new(metres(0, -12, 0)), WATER)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.15

	-- Simple skyline slabs (far silhouettes).
	for i = 0, 11 do
		local ang = i / 12 * math.pi * 2
		local h = 8 + (i % 5) * 3
		local slab = trackPart(
			folder,
			"Tower",
			metres(4, h, 4),
			CFrame.new(metres(math.sin(ang) * 55, h / 2 - 4, math.cos(ang) * 55)),
			Color3.fromRGB(8, 9, 14)
		)
		slab.Transparency = 0.05
	end

	-- Continuous guard rails.
	for _, z in { -2.45, 2.45 } do
		trackPart(folder, "Guard", metres(80, 0.07, 0.07), CFrame.new(metres(0, 0.85, z)), STEEL, Enum.Material.Metal)
	end

	-- Rain strips just outside the windows (opacity driven by open-air level).
	for _, z in { -1.6, 1.6 } do
		local strip = trackPart(folder, "Rain", metres(40, 0.85, 0.02), CFrame.new(metres(0, 1.325, z)), Color3.fromRGB(180, 190, 210))
		strip.Transparency = 1
		strip.Material = Enum.Material.Glass
		table.insert(rainParts, strip)
	end

	local bentCount = BENT_WRAP / BENT_SPACING
	for i = 0, bentCount - 1 do
		local base = i * BENT_SPACING
		for _, z in { -2.6, 2.6 } do
			local leg = trackPart(folder, "BentLeg", metres(0.35, 12, 0.35), CFrame.new(metres(0, -6.6, z)), STEEL, Enum.Material.Metal)
			table.insert(trestleSteel, {
				part = leg,
				base = base,
				y = leg.Position.Y,
				z = leg.Position.Z,
				period = BENT_WRAP,
				rotation = CFrame.identity,
			})
			local brace = trackPart(folder, "BentBrace", metres(0.12, 7, 0.12), CFrame.new(metres(0, -4.5, z)), RUST, Enum.Material.Metal)
			table.insert(trestleSteel, {
				part = brace,
				base = base,
				y = brace.Position.Y,
				z = brace.Position.Z,
				period = BENT_WRAP,
				rotation = CFrame.Angles(math.rad(if z < 0 then -28 else 28), 0, 0),
			})
			local post = trackPart(folder, "RailPost", metres(0.08, 1.3, 0.08), CFrame.new(metres(0, 0.2, z * 0.94)), STEEL, Enum.Material.Metal)
			table.insert(trestleSteel, {
				part = post,
				base = base,
				y = post.Position.Y,
				z = post.Position.Z,
				period = BENT_WRAP,
				rotation = CFrame.identity,
			})
		end
		local beam = trackPart(folder, "BentBeam", metres(0.4, 0.5, 5.6), CFrame.new(metres(0, -0.75, 0)), STEEL, Enum.Material.Metal)
		table.insert(trestleSteel, {
			part = beam,
			base = base,
			y = beam.Position.Y,
			z = beam.Position.Z,
			period = BENT_WRAP,
			rotation = CFrame.identity,
		})
	end

	folder.Parent = workspace
end

function Scenery.setName(station: Station, name: string)
	for _, label in station.labels do
		label.Text = name
	end
end

function Scenery.build(): (Station, Station)
	local tunnel = Instance.new("Folder")
	tunnel.Name = "Tunnel"
	tunnel.Parent = workspace

	local chunks = 3
	local spacing = LOOP / chunks
	local length = spacing + 1.2
	for _, z in { -2.9, 2.9 } do
		addLoop(tunnel, "Wall", chunks, spacing, length, 1.35, z, 4.4, 0.28, WALL)
	end
	addLoop(tunnel, "Ceiling", chunks, spacing, length, 3.45, 0, 0.18, 6.4, WALL)
	addLoop(tunnel, "Bed", chunks, spacing, length, -0.62, 0, 0.16, 6.4, BED, Enum.Material.Concrete)

	for _, z in { -2.05, 2.15 } do
		addLoop(tunnel, "Rail", chunks, spacing, length, -0.28, z - 0.28, 0.06, 0.06, Constants.COLOR.steel, Enum.Material.Metal)
		addLoop(tunnel, "Rail", chunks, spacing, length, -0.28, z + 0.28, 0.06, 0.06, Constants.COLOR.steel, Enum.Material.Metal)
	end

	local tieCount = LOOP / 2
	for i = 0, tieCount - 1 do
		local base = i * 2
		for _, z in { -2.05, 2.15 } do
			local part = trackPart(tunnel, "Tie", metres(0.28, 0.06, 0.9), CFrame.new(metres(0, -0.36, z)), PIER)
			table.insert(pieces, {
				part = part,
				base = base,
				y = part.Position.Y,
				z = part.Position.Z,
				period = LOOP,
				rotation = CFrame.identity,
				tunnel = true,
			})
		end
	end

	local pierCount = 28
	for i = 0, pierCount - 1 do
		local base = i * (LOOP / pierCount)
		-- Platform side sits behind the station wall so a stop hides the piers.
		for _, z in { -2.78, 2.55 } do
			local part = trackPart(tunnel, "Pier", metres(0.28, 3.3, 0.24), CFrame.new(metres(0, 1.2, z)), PIER, Enum.Material.Concrete)
			table.insert(pieces, {
				part = part,
				base = base,
				y = part.Position.Y,
				z = part.Position.Z,
				period = LOOP,
				rotation = CFrame.identity,
				tunnel = true,
			})
		end
	end

	local lampCount = 12
	local lampSpacing = LOOP / lampCount
	for i = 0, lampCount - 1 do
		local base = i * lampSpacing
		for index, z in { -2.72, 2.42 } do
			local part = trackPart(tunnel, "TunnelLight", metres(0.55, 0.1, 0.16), CFrame.new(metres(0, 2.15, z)), LAMP)
			part.Material = Enum.Material.Neon
			-- Stagger one wall so the two rows don't pass the windows in step.
			local stagger = if index == 2 then lampSpacing / 2 else 0
			table.insert(pieces, {
				part = part,
				base = base + stagger,
				y = part.Position.Y,
				z = part.Position.Z,
				period = LOOP,
				rotation = CFrame.identity,
				tunnel = true,
			})
		end
	end

	buildTrestle()

	local leaving = buildStation()
	leaving.model.Name = "StationLeaving"
	local arriving = buildStation()
	arriving.model.Name = "StationArriving"
	leaving.base = 0
	arriving.base = 4000
	table.insert(stations, leaving)
	table.insert(stations, arriving)
	Scenery.place(0)
	return leaving, arriving
end

-- Web setOpenAir: hide tiled back wall / trim on elevated platforms.
function Scenery.setOpenAir(station: Station, on: boolean)
	local wall = station.wall
	local trim = station.trim
	if wall ~= nil then
		wall.Transparency = if on then 1 else 0
	end
	if trim ~= nil then
		trim.Transparency = if on then 1 else 0
	end
end

function Scenery.setOpenAirLevel(level: number)
	openAirLevel = math.clamp(level, 0, 1)
end

function Scenery.place(odo: number)
	local hideTunnel = openAirLevel > 0.35
	local showTrestle = openAirLevel > 0.05
	for _, piece in pieces do
		local x = Constants.meters(loopX(piece.base, odo, piece.period))
		piece.part.CFrame = CFrame.new(x, piece.y, piece.z) * piece.rotation
		if piece.tunnel == true then
			piece.part.Transparency = if hideTunnel then 1 else 0
			if piece.part.Material == Enum.Material.Neon then
				piece.part.Color = if hideTunnel then Color3.fromRGB(12, 10, 8) else LAMP
			end
		end
	end
	for _, station in stations do
		local x = Constants.meters(-(station.base - odo))
		station.model:PivotTo(CFrame.new(x, 0, 0))
	end

	local folder = trestleFolder
	if folder ~= nil then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") and child.Name ~= "Rain" and not string.find(child.Name, "Bent", 1, true) and child.Name ~= "RailPost" then
				if not showTrestle then
					child.Transparency = 1
				elseif child.Name == "Sky" then
					child.Transparency = 0.35
				elseif child.Name == "Haze" then
					child.Transparency = 0.7
				elseif child.Name == "Water" then
					child.Transparency = 0.15
				else
					child.Transparency = 0.05
				end
			end
		end
	end
	for _, piece in trestleSteel do
		local x = Constants.meters(loopX(piece.base, odo, piece.period))
		piece.part.CFrame = CFrame.new(x, piece.y, piece.z) * piece.rotation
		piece.part.Transparency = if showTrestle then 0 else 1
	end
	for _, rain in rainParts do
		-- ~0.55 opacity * outside level (web rainMats).
		rain.Transparency = if showTrestle then 1 - 0.55 * openAirLevel else 1
	end
end

return Scenery
