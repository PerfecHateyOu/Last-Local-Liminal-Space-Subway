--!strict
-- Cars A (lead) and C (rear) plus walkable gangways. Layout matches
-- subwayCarBuilder.buildAdjacentCars / buildGangways (centres ±19.5 m).
-- Part shells are the default; Models.Car_A / Car_C are optional visuals.
-- Anomalies stay on Car B. Trestle stays out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Passengers = require(ReplicatedStorage.Shared.Passengers)

local Consist = {}

type BuiltCar = {
	model: Model,
	passengers: Folder,
	spawnPassenger: (Passengers.PassengerDef, Folder) -> string,
}

local function metres(x: number, y: number, z: number): Vector3
	local s = Constants.STUDS_PER_METER
	return Vector3.new(x * s, y * s, z * s)
end

local function sizeM(x: number, y: number, z: number): Vector3
	return metres(x, y, z)
end

local function makePart(opts: {
	name: string,
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	collide: boolean?,
	shape: Enum.PartType?,
}): Part
	local part = Instance.new("Part")
	part.Name = opts.name
	part.Anchored = true
	part.Size = opts.size
	part.CFrame = opts.cframe
	part.Color = opts.color or Constants.COLOR.wall
	part.Material = opts.material or Enum.Material.SmoothPlastic
	part.Transparency = opts.transparency or 0
	part.CanCollide = if opts.collide == nil then true else opts.collide
	part.CanTouch = false
	part.CanQuery = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if opts.shape ~= nil then
		part.Shape = opts.shape
	end
	part.Parent = opts.parent
	return part
end

local function tryVisualCar(name: string, parent: Model, centerX: number): boolean
	local models = ReplicatedStorage:FindFirstChild("Models")
	if models == nil then
		return false
	end
	local template = models:FindFirstChild(name) or models:FindFirstChild(string.lower(name))
	if template == nil or not template:IsA("Model") then
		return false
	end
	local clone = template:Clone()
	clone.Name = name .. "_Mesh"
	for _, desc in clone:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.Massless = true
		elseif desc:IsA("BaseScript") or desc:IsA("Humanoid") then
			desc:Destroy()
		end
	end
	clone.Parent = parent
	local ok = pcall(function()
		clone:PivotTo(CFrame.new(metres(centerX, 0, 0)))
	end)
	if not ok then
		clone:Destroy()
		return false
	end
	return true
end

local function buildShell(name: string, centerX: number, benchSpans: { { number } }, poleXs: { number }, lightXs: { number }, gangwayX: number, cabX: number): Model
	local car = Instance.new("Model")
	car.Name = name

	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = car
	local seats = Instance.new("Folder")
	seats.Name = "Seats"
	seats.Parent = car
	local poleFolder = Instance.new("Folder")
	poleFolder.Name = "Poles"
	poleFolder.Parent = car
	local lightFolder = Instance.new("Folder")
	lightFolder.Name = "Lights"
	lightFolder.Parent = car

	makePart({
		name = "Floor",
		parent = shell,
		size = sizeM(18, 0.4, 3.06),
		cframe = CFrame.new(metres(centerX, -0.2, 0)),
		color = Constants.COLOR.floor,
		material = Enum.Material.Concrete,
	})
	for _, side in { -1, 1 } do
		makePart({
			name = "ShellWall",
			parent = shell,
			size = sizeM(18.2, 2.5, 0.08),
			cframe = CFrame.new(metres(centerX, 1.25, side * 1.58)),
			transparency = 1,
		})
	end
	makePart({
		name = "Ceiling",
		parent = shell,
		size = sizeM(18, 0.08, 3.06),
		cframe = CFrame.new(metres(centerX, 2.46, 0)),
		color = Constants.COLOR.ceiling,
		material = Enum.Material.Concrete,
	})

	for _, side in { -1, 1 } do
		local z = side * 1.53
		makePart({
			name = "Kickboard",
			parent = shell,
			size = sizeM(18, 0.9, 0.08),
			cframe = CFrame.new(metres(centerX, 0.45, z)),
			color = Constants.COLOR.lowWall,
			material = Enum.Material.Concrete,
		})
		makePart({
			name = "UpperWall",
			parent = shell,
			size = sizeM(18, 0.7, 0.08),
			cframe = CFrame.new(metres(centerX, 2.05, z)),
			color = Constants.COLOR.wall,
			material = Enum.Material.Concrete,
		})
		makePart({
			name = "Glass",
			parent = shell,
			size = sizeM(18, 0.85, 0.02),
			cframe = CFrame.new(metres(centerX, 1.325, z - side * 0.03)),
			color = Constants.COLOR.glass,
			transparency = 0.86,
			collide = false,
		})

		for index, span in benchSpans do
			local a = span[1]
			local b = span[2]
			local length = b - a
			local cx = (a + b) / 2
			local color = if index % 2 == 1 then Constants.COLOR.seatOrange else Constants.COLOR.seatYellow
			makePart({
				name = "Cushion",
				parent = seats,
				size = sizeM(length, 0.09, 0.46),
				cframe = CFrame.new(metres(cx, 0.455, side * 1.25)),
				color = color,
			})
			makePart({
				name = "Back",
				parent = seats,
				size = sizeM(length, 0.5, 0.08),
				cframe = CFrame.new(metres(cx, 0.76, side * 1.47)),
				color = color,
			})
			makePart({
				name = "Riser",
				parent = seats,
				size = sizeM(length, 0.41, 0.36),
				cframe = CFrame.new(metres(cx, 0.205, side * 1.3)),
				color = Constants.COLOR.underSeat,
			})
			makePart({
				name = "SeatLip",
				parent = seats,
				size = sizeM(length, 2.2, 0.06),
				cframe = CFrame.new(metres(cx, 1.1, side * 1.02)),
				color = Constants.COLOR.underSeat,
				transparency = 1,
			})
		end

		makePart({
			name = "GrabBar",
			parent = poleFolder,
			size = sizeM(17.6, 0.04, 0.04),
			cframe = CFrame.new(metres(centerX, 2.02, side * 0.98)),
			color = Constants.COLOR.steel,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			collide = false,
		})
		for _, x in poleXs do
			makePart({
				name = "Pole",
				parent = poleFolder,
				size = Vector3.new(Constants.meters(2.42), Constants.meters(0.045), Constants.meters(0.045)),
				cframe = CFrame.new(metres(x, 1.21, side * 0.98)) * CFrame.Angles(0, 0, math.rad(90)),
				color = Constants.COLOR.steel,
				material = Enum.Material.Metal,
				shape = Enum.PartType.Cylinder,
				collide = false,
			})
		end
	end

	-- Gangway doorway bulkheads (opening in the aisle).
	makePart({
		name = "Bulkhead",
		parent = shell,
		size = sizeM(0.1, 2.46, 1.05),
		cframe = CFrame.new(metres(gangwayX, 1.23, -0.98)),
		color = Constants.COLOR.wall,
		material = Enum.Material.Concrete,
	})
	makePart({
		name = "Bulkhead",
		parent = shell,
		size = sizeM(0.1, 2.46, 1.05),
		cframe = CFrame.new(metres(gangwayX, 1.23, 0.98)),
		color = Constants.COLOR.wall,
		material = Enum.Material.Concrete,
	})
	makePart({
		name = "Lintel",
		parent = shell,
		size = sizeM(0.1, 0.42, 1),
		cframe = CFrame.new(metres(gangwayX, 2.25, 0)),
		color = Constants.COLOR.wall,
		material = Enum.Material.Concrete,
	})

	-- Cab bulkhead (closed end).
	makePart({
		name = "CabWall",
		parent = shell,
		size = sizeM(0.1, 2.46, 3.06),
		cframe = CFrame.new(metres(cabX, 1.23, 0)),
		color = Constants.COLOR.wall,
		material = Enum.Material.Concrete,
	})
	makePart({
		name = "CabDoor",
		parent = shell,
		size = sizeM(0.12, 1.8, 0.8),
		cframe = CFrame.new(metres(cabX, 1.0, 0)),
		color = Constants.COLOR.dark,
		collide = false,
	})

	for _, x in lightXs do
		local anchor = makePart({
			name = "CeilingLight",
			parent = lightFolder,
			size = Vector3.new(0.3, 0.3, 0.3),
			cframe = CFrame.new(metres(x, 2.2, 0)),
			color = Constants.COLOR.lightOn,
			transparency = 1,
			collide = false,
		})
		local point = Instance.new("PointLight")
		point.Name = "Glow"
		point.Color = Constants.COLOR.lamp
		point.Brightness = Constants.LAMP_BRIGHTNESS
		point.Range = Constants.meters(Constants.LAMP_RANGE_M)
		point.Shadows = true
		point.Parent = anchor
	end

	car.Parent = workspace
	return car
end

local function buildGangway(parent: Folder, centerX: number)
	local bellows = Color3.fromRGB(22, 24, 26)
	local tread = Color3.fromRGB(68, 70, 72)
	local chain = Color3.fromRGB(150, 152, 154)

	makePart({
		name = "Plate",
		parent = parent,
		size = sizeM(1.5, 0.08, 1.02),
		cframe = CFrame.new(metres(centerX, -0.02, 0)),
		color = tread,
		material = Enum.Material.Metal,
	})
	makePart({
		name = "Roof",
		parent = parent,
		size = sizeM(1.5, 0.08, 1.08),
		cframe = CFrame.new(metres(centerX, 2.22, 0)),
		color = bellows,
		collide = false,
	})
	for _, z in { -0.54, 0.54 } do
		for i = 0, 6 do
			makePart({
				name = "Pleat",
				parent = parent,
				size = sizeM(0.12, 2.2, 0.05),
				cframe = CFrame.new(metres(centerX - 0.6 + i * 0.2, 1.1, z)),
				color = bellows,
			})
		end
		makePart({
			name = "Rail",
			parent = parent,
			size = sizeM(1.48, 0.03, 0.03),
			cframe = CFrame.new(metres(centerX, 1.0, z * 0.9)),
			color = chain,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			collide = false,
		})
		makePart({
			name = "Rail",
			parent = parent,
			size = sizeM(1.48, 0.025, 0.025),
			cframe = CFrame.new(metres(centerX, 0.55, z * 0.9)),
			color = chain,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			collide = false,
		})
	end
end

local closedFrames: { [BasePart]: CFrame } = {}

local function setDoorOpen(part: BasePart, open: boolean, isFront: boolean)
	local closed = closedFrames[part]
	if closed == nil then
		return
	end
	part:SetAttribute("Open", open)
	if open then
		local yaw = if isFront then 1.35 else -1.35
		-- Hinge at the −Z edge of the leaf (web pivot).
		local hinge = closed * CFrame.new(0, 0, -part.Size.Z / 2)
		part.CFrame = hinge * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, part.Size.Z / 2)
		part.CanCollide = false
	else
		part.CFrame = closed
		part.CanCollide = true
	end
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt ~= nil then
		prompt.ActionText = if open then "Close" else "Open"
	end
end

local function wireGangwayDoor(part: BasePart, isFront: boolean)
	if part:GetAttribute("GangwayWired") == true then
		return
	end
	closedFrames[part] = part.CFrame
	part.Name = if isFront then "FrontGangwayDoor" else "RearGangwayDoor"
	part:SetAttribute("Gangway", if isFront then "front" else "rear")
	part:SetAttribute("Open", false)
	part:SetAttribute("GangwayWired", true)
	part.CanCollide = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GangwayPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = "Gangway door"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Constants.meters(2.8)
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function()
		local open = part:GetAttribute("Open") == true
		setDoorOpen(part, not open, isFront)
	end)
end

local function wireCarBDoors(carModel: Model)
	-- Prefer named Part shell doors; fall back to legacy GangwayDoor meshes.
	local front: BasePart? = nil
	local rear: BasePart? = nil
	for _, desc in carModel:GetDescendants() do
		if desc:IsA("BasePart") then
			if desc.Name == "FrontGangwayDoor" then
				front = desc
			elseif desc.Name == "RearGangwayDoor" then
				rear = desc
			end
		end
	end
	if front == nil or rear == nil then
		for _, desc in carModel:GetDescendants() do
			if desc:IsA("BasePart") and desc.Name == "GangwayDoor" then
				local x = desc.Position.X / Constants.STUDS_PER_METER
				if x < 0 and front == nil then
					front = desc
				elseif x >= 0 and rear == nil then
					rear = desc
				end
			end
		end
	end
	if front ~= nil then
		wireGangwayDoor(front, true)
	end
	if rear ~= nil then
		wireGangwayDoor(rear, false)
	end
end

function Consist.attach(car: BuiltCar)
	local carA = buildShell(
		"Car_A",
		-19.5,
		{ { -27.5, -23.5 }, { -22.5, -16.5 }, { -15.5, -11.5 } },
		{ -24.0, -15.0 },
		{ -25.5, -21.5, -17.5, -13.5 },
		-10.5,
		-28.5
	)
	local carC = buildShell(
		"Car_C",
		19.5,
		{ { 11.5, 15.5 }, { 16.5, 22.5 }, { 23.5, 27.5 } },
		{ 15.0, 24.0 },
		{ 13.5, 17.5, 21.5, 25.5 },
		10.5,
		28.5
	)

	local importedA = tryVisualCar("Car_A", carA, -19.5)
	local importedC = tryVisualCar("Car_C", carC, 19.5)
	if importedA then
		print("[Last Local] Using modeled Car_A over Part shell.")
	else
		print("[Last Local] Car_A Part fallback (no Models.Car_A).")
	end
	if importedC then
		print("[Last Local] Using modeled Car_C over Part shell.")
	else
		print("[Last Local] Car_C Part fallback (no Models.Car_C).")
	end

	local gangways = Instance.new("Folder")
	gangways.Name = "Gangways"
	gangways.Parent = workspace
	buildGangway(gangways, -9.75)
	buildGangway(gangways, 9.75)

	wireCarBDoors(car.model)

	local notes: { string } = {}
	for _, def in Passengers.ADJACENT do
		table.insert(notes, car.spawnPassenger(def, car.passengers))
	end
	print(string.format("[Last Local] Adjacent passengers: %s", if #notes > 0 then table.concat(notes, ", ") else "none"))
end

return Consist
