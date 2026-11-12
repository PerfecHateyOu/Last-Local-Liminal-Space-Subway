--!strict
-- The tunnel and the two platforms. The car stays in place (players are in
-- it). Scenery streams toward +X as the odometer rises, which is the web
-- game's FORWARD_X = -1: something still ahead sits at negative X.
--
-- Tunnel lamps are Neon parts with no PointLight. They cannot light the
-- car, so a lamp passing a window does not flicker the interior. The only
-- lights that fill the car are the ceiling lamps in CarBuilder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Scenery = {}

export type Station = {
	model: Model,
	base: number,
	labels: { TextLabel },
}

type Piece = {
	part: BasePart,
	base: number,
	y: number,
	z: number,
	period: number,
	rotation: CFrame,
}

local pieces: { Piece } = {}
local stations: { Station } = {}

local WALL = Color3.fromRGB(24, 26, 24)
local PIER = Color3.fromRGB(36, 39, 36)
local LAMP = Color3.fromRGB(255, 216, 150)
local PLATFORM = Color3.fromRGB(141, 138, 130)
local YELLOW = Color3.fromRGB(227, 195, 65)
local COLUMN = Color3.fromRGB(45, 72, 56)
local TRIM = Color3.fromRGB(63, 122, 82)
local BED = Color3.fromRGB(18, 18, 16)

local LOOP = 84

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

	trackPart(model, "Wall", metres(44, 3.2, 0.16), CFrame.new(metres(0, 1.35, -2.55)), Color3.fromRGB(42, 48, 44))
	trackPart(model, "Trim", metres(44, 0.16, 0.06), CFrame.new(metres(0, 2.35, -2.46)), TRIM)
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
	}
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
			})
		end
	end

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

function Scenery.place(odo: number)
	for _, piece in pieces do
		local x = Constants.meters(loopX(piece.base, odo, piece.period))
		piece.part.CFrame = CFrame.new(x, piece.y, piece.z) * piece.rotation
	end
	for _, station in stations do
		local x = Constants.meters(-(station.base - odo))
		station.model:PivotTo(CFrame.new(x, 0, 0))
	end
end

return Scenery
