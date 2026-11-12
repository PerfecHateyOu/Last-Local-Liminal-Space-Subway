--!strict
-- One G-train car, in parts, from the measurements in subwayCarBuilder.ts.
-- Passengers stand or sit on the web game's spots. A model named in
-- ReplicatedStorage.Models replaces the part figure; a missing model does not
-- stop the car from building.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local KeepOut = require(ReplicatedStorage.Shared.KeepOut)
local Passengers = require(ReplicatedStorage.Shared.Passengers)

local CarBuilder = {}

export type DoorLeaf = {
	model: Model,
	x0: number,
	y: number,
	z: number,
	side: number,
}

export type Lamp = {
	part: BasePart,
	light: PointLight?,
}

export type BuiltCar = {
	model: Model,
	doors: { DoorLeaf },
	lamps: { Lamp },
	passengers: Folder,
	board: SpawnLocation,
}

local function metres(x: number, y: number, z: number): Vector3
	local s = Constants.STUDS_PER_METER
	return Vector3.new(x * s, y * s, z * s)
end

local function sizeM(x: number, y: number, z: number): Vector3
	return metres(x, y, z)
end

type PartOpts = {
	name: string,
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	collide: boolean?,
	query: boolean?,
	shape: Enum.PartType?,
}

local function makePart(opts: PartOpts): Part
	local part = Instance.new("Part")
	part.Name = opts.name
	part.Anchored = true
	part.Size = opts.size
	part.CFrame = opts.cframe
	part.Color = opts.color or Constants.COLOR.wall
	part.Material = opts.material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = if opts.collide == nil then true else opts.collide
	part.CanQuery = if opts.query == nil then false else opts.query
	part.CanTouch = false
	part.Transparency = opts.transparency or 0
	if opts.shape ~= nil then
		part.Shape = opts.shape
	end
	part.Parent = opts.parent
	return part
end

local function applyShown(model: Model, shown: boolean)
	model:SetAttribute("Hidden", not shown)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			if desc.Name == "KeepOut" then
				desc.CanCollide = shown
				desc.CanQuery = false
			elseif desc.Name == "Root" then
				desc.Transparency = 1
				desc.CanQuery = false
				desc.CanCollide = false
			else
				local base = desc:GetAttribute("ShownTransparency")
				local shownTransparency = if typeof(base) == "number" then base else 0
				desc.Transparency = if shown then shownTransparency else 1
				desc.CanQuery = shown
				desc.CanCollide = false
			end
		end
		if desc:IsA("Decal") or desc:IsA("Texture") then
			(desc :: Decal).Transparency = if shown then 0 else 1
		end
	end
end

function CarBuilder.setCrowd(folder: Folder, shown: boolean)
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Crowd") == true then
			applyShown(child, shown)
		end
	end
end

local function rememberTransparency(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and desc.Name ~= "KeepOut" and desc.Name ~= "Root" then
			desc:SetAttribute("ShownTransparency", desc.Transparency)
		end
	end
end

local function tagPassenger(model: Model, def: Passengers.PassengerDef)
	model.Name = def.id
	model:SetAttribute("PassengerId", def.id)
	model:SetAttribute("Label", def.label)
	model:SetAttribute("Standing", def.standing)
	model:SetAttribute("Anomaly", def.anomaly)
	model:SetAttribute("Crowd", def.crowd)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc:SetAttribute("PassengerId", def.id)
		end
	end
end

local function addBox(model: Model, name: string, boxSize: Vector3, localPos: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = boxSize
	part.CFrame = CFrame.new(localPos)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Parent = model
	return part
end

local function studs(metresLength: number): number
	return Constants.meters(metresLength)
end

-- Part figure facing local +Z, feet on the pivot. Seated laps sit near the bench.
local function buildFallback(def: Passengers.PassengerDef): Model
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Transparency = 1
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	local s = Constants.STUDS_PER_METER
	if def.standing then
		for _, dx in { -0.09, 0.09 } do
			addBox(model, "Leg", Vector3.new(0.14 * s, 0.8 * s, 0.16 * s), Vector3.new(dx * s, 0.44 * s, 0), def.pants)
			addBox(model, "Shoe", Vector3.new(0.14 * s, 0.08 * s, 0.26 * s), Vector3.new(dx * s, 0.04 * s, 0.04 * s), Constants.COLOR.ink)
		end
		addBox(model, "Torso", Vector3.new(0.42 * s, 0.55 * s, 0.24 * s), Vector3.new(0, 1.12 * s, 0), def.shirt)
		addBox(model, "Arm", Vector3.new(0.12 * s, 0.5 * s, 0.12 * s), Vector3.new(-0.28 * s, 1.1 * s, 0), def.shirt)
		addBox(model, "Arm", Vector3.new(0.12 * s, 0.5 * s, 0.12 * s), Vector3.new(0.28 * s, 1.1 * s, 0), def.shirt)
		addBox(model, "Head", Vector3.new(0.26 * s, 0.28 * s, 0.26 * s), Vector3.new(0, 1.55 * s, 0), def.skin)
		addBox(model, "Hair", Vector3.new(0.28 * s, 0.12 * s, 0.28 * s), Vector3.new(0, 1.7 * s, 0), def.hair)
		if not def.anomaly then
			addBox(model, "Eye", Vector3.new(0.045 * s, 0.045 * s, 0.03 * s), Vector3.new(-0.06 * s, 1.57 * s, 0.14 * s), Constants.COLOR.ink)
			addBox(model, "Eye", Vector3.new(0.045 * s, 0.045 * s, 0.03 * s), Vector3.new(0.06 * s, 1.57 * s, 0.14 * s), Constants.COLOR.ink)
		end
	else
		addBox(model, "Shin", Vector3.new(0.13 * s, 0.42 * s, 0.14 * s), Vector3.new(-0.1 * s, 0.24 * s, 0.36 * s), def.pants)
		addBox(model, "Shin", Vector3.new(0.13 * s, 0.42 * s, 0.14 * s), Vector3.new(0.1 * s, 0.24 * s, 0.36 * s), def.pants)
		addBox(model, "Shoe", Vector3.new(0.13 * s, 0.08 * s, 0.22 * s), Vector3.new(-0.1 * s, 0.04 * s, 0.42 * s), Constants.COLOR.ink)
		addBox(model, "Shoe", Vector3.new(0.13 * s, 0.08 * s, 0.22 * s), Vector3.new(0.1 * s, 0.04 * s, 0.42 * s), Constants.COLOR.ink)
		addBox(model, "Lap", Vector3.new(0.38 * s, 0.16 * s, 0.4 * s), Vector3.new(0, 0.5 * s, 0.12 * s), def.pants)
		addBox(model, "Torso", Vector3.new(0.4 * s, 0.48 * s, 0.24 * s), Vector3.new(0, 0.92 * s, 0), def.shirt)
		addBox(model, "Head", Vector3.new(0.26 * s, 0.28 * s, 0.26 * s), Vector3.new(0, 1.32 * s, 0), def.skin)
		addBox(model, "Hair", Vector3.new(0.28 * s, 0.1 * s, 0.28 * s), Vector3.new(0, 1.46 * s, -0.02 * s), def.hair)
		if not def.anomaly then
			addBox(model, "Eye", Vector3.new(0.045 * s, 0.045 * s, 0.03 * s), Vector3.new(-0.06 * s, 1.34 * s, 0.14 * s), Constants.COLOR.ink)
			addBox(model, "Eye", Vector3.new(0.045 * s, 0.045 * s, 0.03 * s), Vector3.new(0.06 * s, 1.34 * s, 0.14 * s), Constants.COLOR.ink)
		end
	end

	model:SetAttribute("ModelSource", "fallback")
	return model
end

local function stripImported(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BaseScript") or desc:IsA("Humanoid") or desc:IsA("Animator") or desc:IsA("AnimationController") then
			desc:Destroy()
		end
	end
end

local function wrapClone(source: Instance): Model?
	local clone = source:Clone()
	if clone:IsA("Model") then
		stripImported(clone)
		return clone
	end
	if clone:IsA("BasePart") then
		local model = Instance.new("Model")
		model.Name = source.Name
		clone.Parent = model
		return model
	end
	if clone:IsA("Folder") then
		local model = Instance.new("Model")
		model.Name = source.Name
		for _, child in clone:GetChildren() do
			child.Parent = model
		end
		clone:Destroy()
		stripImported(model)
		if #model:GetChildren() == 0 then
			model:Destroy()
			return nil
		end
		return model
	end
	clone:Destroy()
	return nil
end

local function hasParts(model: Model): boolean
	return model:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function scaleToHeight(model: Model, targetMetres: number): boolean
	local ok, boxSize = pcall(function(): Vector3
		local _, size = model:GetBoundingBox()
		return size
	end)
	if not ok or typeof(boxSize) ~= "Vector3" or boxSize.Y < 0.05 then
		return false
	end
	local scale = studs(targetMetres) / boxSize.Y
	if math.abs(scale - 1) < 0.02 then
		return true
	end
	local scaled = pcall(function()
		model:ScaleTo(scale)
	end)
	return scaled
end

-- glTF models face +Z. PivotTo turns local +Z onto `face` and puts the feet
-- on the floor point. A YawOffset attribute (degrees) on the imported model
-- adds to the web-game yaw when the FBX comes in backwards.
local function placeModel(model: Model, feetWorld: Vector3, ry: number)
	local pivot = model:GetPivot()
	local boxCf, boxSize = model:GetBoundingBox()
	local feetNow = Vector3.new(boxCf.Position.X, boxCf.Position.Y - boxSize.Y / 2, boxCf.Position.Z)
	local feetLocal = pivot:PointToObjectSpace(feetNow)
	local face = Vector3.new(math.sin(ry), 0, math.cos(ry))
	local rot = CFrame.lookAt(Vector3.zero, -face)
	local pos = feetWorld - rot:VectorToWorldSpace(feetLocal)
	model:PivotTo(CFrame.new(pos) * rot.Rotation)
end

local function addKeepOut(model: Model, feet: Vector3, passengerId: string)
	local radius = KeepOut.cylinderRadiusStuds()
	local height = studs(1.7)
	local cylinder = Instance.new("Part")
	cylinder.Name = "KeepOut"
	cylinder.Shape = Enum.PartType.Cylinder
	cylinder.Size = Vector3.new(height, radius * 2, radius * 2)
	cylinder.CFrame = CFrame.new(feet + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	cylinder.Anchored = true
	cylinder.Material = Enum.Material.SmoothPlastic
	cylinder.Transparency = 1
	cylinder.CanCollide = true
	cylinder.CanQuery = false
	cylinder.CanTouch = false
	cylinder.Parent = model
	cylinder:SetAttribute("PassengerId", passengerId)
end

local function prepareParts(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = desc.Name ~= "Root"
			desc.Massless = true
		end
	end
end

local attachProps: (Model, Passengers.PassengerDef) -> ()

local function buildPassenger(def: Passengers.PassengerDef, folder: Folder): string
	local template: Instance? = nil
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder ~= nil then
		for _, name in Passengers.modelNames(def) do
			local found = modelsFolder:FindFirstChild(name)
			if found ~= nil then
				template = found
				break
			end
		end
	end

	local model: Model? = nil
	local source = "fallback"
	if template ~= nil then
		model = wrapClone(template)
		if model ~= nil and hasParts(model) then
			model.Parent = folder
			prepareParts(model)
			local targetHeight = if def.standing then 1.7 else 1.3
			if scaleToHeight(model, targetHeight) then
				source = "imported"
			else
				model:Destroy()
				model = nil
			end
		elseif model ~= nil then
			model:Destroy()
			model = nil
		end
	end

	local built: Model
	if model ~= nil then
		built = model
	else
		built = buildFallback(def)
		built.Parent = folder
		source = "fallback"
	end

	local yaw = def.ry
	if source == "imported" then
		local extra = built:GetAttribute("YawOffset")
		if typeof(extra) == "number" then
			yaw += math.rad(extra)
		end
	end

	local feet = metres(def.x, 0, def.z)
	placeModel(built, feet, yaw)
	prepareParts(built)
	tagPassenger(built, def)
	built:SetAttribute("ModelSource", source)
	rememberTransparency(built)

	if def.standing then
		addKeepOut(built, feet, def.id)
	end
	if def.crowd then
		applyShown(built, false)
	end
	attachProps(built, def)

	local reported = def.modelName or def.id
	return if source == "imported" then reported else reported .. " (parts)"
end

local function findModel(name: string): Instance?
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder == nil then
		return nil
	end
	return modelsFolder:FindFirstChild(name)
end

local PROP_ALIASES: { [string]: { string } } = {
	prop_phone = { "prop_phone", "Prop_Phone" },
	prop_phone_texter = { "prop_phone_texter", "Prop_PhoneTexter" },
	prop_tote_bag = { "prop_tote_bag", "Prop_ToteBag" },
	prop_backpack = { "prop_backpack", "Prop_Backpack" },
	prop_newspaper_folded = { "prop_newspaper_folded", "Prop_Newspaper" },
	prop_newspaper_open = { "prop_newspaper_open", "Prop_NewspaperOpen" },
}

attachProps = function(host: Model, def: Passengers.PassengerDef)
	local props = def.props
	if props == nil then
		return
	end
	local cf = host:GetPivot()
	for index, propName in props do
		local template: Instance? = nil
		local aliases = PROP_ALIASES[propName]
		if aliases == nil then
			template = findModel(propName)
		else
			for _, alias in aliases do
				template = findModel(alias)
				if template ~= nil then
					break
				end
			end
		end
		if template == nil then
			continue
		end
		local clone = template:Clone()
		local propModel: Model
		if clone:IsA("Model") then
			propModel = clone
		elseif clone:IsA("BasePart") then
			propModel = Instance.new("Model")
			clone.Parent = propModel
		else
			clone:Destroy()
			continue
		end
		propModel.Name = propName
		propModel.Parent = host
		prepareParts(propModel)
		local _, size = propModel:GetBoundingBox()
		local target = if string.find(propName, "phone", 1, true)
			then Constants.meters(0.14)
			elseif string.find(propName, "tote", 1, true) then Constants.meters(0.47)
			elseif string.find(propName, "backpack", 1, true) then Constants.meters(0.36)
			elseif string.find(propName, "open", 1, true) then Constants.meters(0.2)
			else Constants.meters(0.26)
		if size.Y > 0.001 then
			pcall(function()
				propModel:ScaleTo(target / size.Y)
			end)
		end
		local side = (index - 1) * 0.18
		local localOffset = if string.find(propName, "backpack", 1, true)
			then Vector3.new(side, 0.95, -0.22)
			elseif string.find(propName, "tote", 1, true) then Vector3.new(0.22, 0.45, 0.05)
			elseif string.find(propName, "newspaper", 1, true) then Vector3.new(0.12, 0.9, 0.18)
			else Vector3.new(0.08, 0.85, 0.2)
		local world = cf.Position + cf:VectorToWorldSpace(localOffset * Constants.STUDS_PER_METER)
		propModel:PivotTo(CFrame.new(world) * cf.Rotation)
	end
end

local function buildDoorLeaf(parent: Instance, xMetres: number, zMetres: number, side: number, doors: { DoorLeaf })
	local doorModel = Instance.new("Model")
	doorModel.Name = "DoorLeaf"
	doorModel.Parent = parent
	local x0 = Constants.meters(xMetres)
	local y = Constants.meters(1)
	local z = Constants.meters(zMetres)
	local leaf = makePart({
		name = "Leaf",
		parent = doorModel,
		size = sizeM(0.66, 2, 0.05),
		cframe = CFrame.new(x0, y, z),
		color = Constants.COLOR.door,
		collide = false,
	})
	makePart({
		name = "Window",
		parent = doorModel,
		size = sizeM(0.3, 0.62, 0.03),
		cframe = CFrame.new(x0, y + Constants.meters(0.36), z),
		color = Constants.COLOR.dark,
		transparency = 0.45,
		collide = false,
	})
	doorModel.PrimaryPart = leaf
	table.insert(doors, {
		model = doorModel,
		x0 = x0,
		y = y,
		z = z,
		side = side,
	})
end

local function doorSide(key: string): number
	-- Leaves open away from the gap. W48 and E42 carry the inner edge on +X.
	if string.find(key, "W48", 1, true) or string.find(key, "E42", 1, true) then
		return -1
	end
	return 1
end

local function adoptModeledCar(car: Model): ({ DoorLeaf }?, { Lamp }?)
	local template = findModel("Car_B") or findModel("car_B_interior")
	if template == nil then
		return nil, nil
	end
	local clone = template:Clone()
	local model: Model
	if clone:IsA("Model") then
		model = clone
	elseif clone:IsA("BasePart") then
		model = Instance.new("Model")
		clone.Parent = model
	else
		model = Instance.new("Model")
		if clone:IsA("Folder") then
			for _, child in clone:GetChildren() do
				child.Parent = model
			end
			clone:Destroy()
		else
			clone:Destroy()
			return nil, nil
		end
	end
	model.Name = "Car_B"
	model.Parent = car
	if not hasParts(model) then
		model:Destroy()
		return nil, nil
	end
	local ok, boxSize = pcall(function(): Vector3
		local _, size = model:GetBoundingBox()
		return size
	end)
	if not ok or typeof(boxSize) ~= "Vector3" then
		model:Destroy()
		return nil, nil
	end
	local longest = math.max(boxSize.X, boxSize.Z)
	local target = Constants.meters(18.09)
	if longest > 0.05 then
		local scaled = pcall(function()
			model:ScaleTo(target / longest)
		end)
		if not scaled then
			model:Destroy()
			return nil, nil
		end
	end
	local boxCf, sized = model:GetBoundingBox()
	local bottom = boxCf.Position.Y - sized.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, Constants.meters(-0.06) - bottom, 0))

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.Massless = true
			if string.match(desc.Name, "^LightStrip_%d+") then
				desc.Material = Enum.Material.Neon
				desc.Color = Constants.COLOR.lightOn
			end
		end
	end

	local groups: { [string]: { BasePart } } = {}
	local order: { string } = {}
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			local key = string.match(desc.Name, "^(DoorLeaf_[^_]+_%d+)")
			if key ~= nil then
				if groups[key] == nil then
					groups[key] = {}
					table.insert(order, key)
				end
				table.insert(groups[key], desc)
			end
		end
	end
	local doors: { DoorLeaf } = {}
	for _, key in order do
		local group = Instance.new("Model")
		group.Name = key
		group.Parent = model
		local parts = groups[key]
		for _, part in parts do
			part.Parent = group
		end
		local pivot = group:GetPivot()
		table.insert(doors, {
			model = group,
			x0 = pivot.Position.X,
			y = pivot.Position.Y,
			z = pivot.Position.Z,
			side = doorSide(key),
		})
	end

	local lamps: { Lamp } = {}
	local lightIndex = 0
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and string.match(desc.Name, "^LightStrip_%d+") then
			local point: PointLight? = nil
			if lightIndex % 3 == 0 then
				local glow = Instance.new("PointLight")
				glow.Name = "Glow"
				glow.Color = Constants.COLOR.lamp
				glow.Brightness = Constants.LAMP_BRIGHTNESS
				glow.Range = Constants.meters(Constants.LAMP_RANGE_M)
				glow.Shadows = true
				glow.Parent = desc
				point = glow
			end
			local lamp: Lamp = { part = desc, light = point }
			table.insert(lamps, lamp)
			lightIndex += 1
		end
	end
	if #doors == 0 or #lamps == 0 then
		model:Destroy()
		return nil, nil
	end
	return doors, lamps
end

local function hidePartCarVisuals(car: Model)
	local keepCollider = {
		Floor = true,
		SeatLip = true,
		DoorSeal = true,
		ShellWall = true,
		Bulkhead = true,
		GangwayDoor = true,
		Lintel = true,
		Ceiling = true,
	}
	for _, folderName in { "Shell", "Seats", "Doors", "Poles", "Lights" } do
		local folder = car:FindFirstChild(folderName)
		if folder ~= nil then
			for _, desc in folder:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.Transparency = 1
					if not keepCollider[desc.Name] then
						desc.CanCollide = false
					end
					local glow = desc:FindFirstChild("Glow")
					if glow ~= nil and glow:IsA("PointLight") then
						glow.Enabled = false
					end
				end
			end
		end
	end
end

function CarBuilder.build(): BuiltCar
	local car = Instance.new("Model")
	car.Name = "SubwayCar"

	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = car
	local seats = Instance.new("Folder")
	seats.Name = "Seats"
	seats.Parent = car
	local doorFolder = Instance.new("Folder")
	doorFolder.Name = "Doors"
	doorFolder.Parent = car
	local poleFolder = Instance.new("Folder")
	poleFolder.Name = "Poles"
	poleFolder.Parent = car
	local lightFolder = Instance.new("Folder")
	lightFolder.Name = "Lights"
	lightFolder.Parent = car
	local passengers = Instance.new("Folder")
	passengers.Name = "Passengers"
	passengers.Parent = car

	makePart({
		name = "Floor",
		parent = shell,
		size = sizeM(18, 0.4, 3.06),
		cframe = CFrame.new(metres(0, -0.2, 0)),
		color = Constants.COLOR.floor,
		material = Enum.Material.Concrete,
	})
	-- Closes the window band so a walk can't leave the car. Invisible.
	for _, side in { -1, 1 } do
		makePart({
			name = "ShellWall",
			parent = shell,
			size = sizeM(18.2, 2.5, 0.08),
			cframe = CFrame.new(metres(0, 1.25, side * 1.58)),
			transparency = 1,
		})
	end
	makePart({
		name = "Ceiling",
		parent = shell,
		size = sizeM(18, 0.08, 3.06),
		cframe = CFrame.new(metres(0, 2.46, 0)),
		color = Constants.COLOR.ceiling,
		material = Enum.Material.Concrete,
	})

	for _, side in { -1, 1 } do
		local z = side * 1.53
		makePart({
			name = "Kickboard",
			parent = shell,
			size = sizeM(18, 0.9, 0.08),
			cframe = CFrame.new(metres(0, 0.45, z)),
			color = Constants.COLOR.lowWall,
			material = Enum.Material.Concrete,
		})
		makePart({
			name = "UpperWall",
			parent = shell,
			size = sizeM(18, 0.7, 0.08),
			cframe = CFrame.new(metres(0, 2.05, z)),
			color = Constants.COLOR.wall,
			material = Enum.Material.Concrete,
		})
		for i = 0, 9 do
			local x = -8.55 + i * 1.9
			makePart({
				name = "Mullion",
				parent = shell,
				size = sizeM(0.08, 0.85, 0.08),
				cframe = CFrame.new(metres(x, 1.325, z)),
				color = Constants.COLOR.wall,
				material = Enum.Material.Concrete,
				collide = false,
			})
		end
		if side < 0 then
			makePart({
				name = "Ad_Across_0_GREENPOINTSAVINGS",
				parent = shell,
				size = sizeM(1.3, 0.41, 0.04),
				cframe = CFrame.new(metres(-6.2, 2.02, z + 0.06)),
				color = Color3.fromRGB(20, 60, 43),
				collide = false,
			})
		end
		makePart({
			name = "Glass",
			parent = shell,
			size = sizeM(18, 0.85, 0.02),
			cframe = CFrame.new(metres(0, 1.325, z - side * 0.03)),
			color = Constants.COLOR.glass,
			transparency = 0.86,
			collide = false,
		})

		local spans = { { -8.85, -5.25 }, { -3.75, 3.75 }, { 5.25, 8.85 } }
		for index, span in spans do
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
			-- Invisible full-height lip so the player stays in the aisle.
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
			cframe = CFrame.new(metres(0, 2.02, side * 0.98)),
			color = Constants.COLOR.steel,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			collide = false,
		})
		for _, x in { -5.3, -3.7, 3.7, 5.3 } do
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

	local doors: { DoorLeaf } = {}
	for _, x in { -4.5, 4.5 } do
		for _, side in { -1, 1 } do
			local x0 = x + side * 0.335
			buildDoorLeaf(doorFolder, x0, -1.485, side, doors)
		end
		makePart({
			name = "DoorHeader",
			parent = doorFolder,
			size = sizeM(1.4, 0.08, 0.1),
			cframe = CFrame.new(metres(x, 2.04, -1.5)),
			color = Constants.COLOR.lowWall,
			collide = false,
		})
		makePart({
			name = "NearDoor",
			parent = doorFolder,
			size = sizeM(1.34, 2, 0.06),
			cframe = CFrame.new(metres(x, 1, 1.485)),
			color = Constants.COLOR.door,
			collide = false,
		})
		for _, dx in { -0.3, 0.3 } do
			makePart({
				name = "NearDoorWindow",
				parent = doorFolder,
				size = sizeM(0.34, 0.62, 0.03),
				cframe = CFrame.new(metres(x + dx, 1.36, 1.5)),
				color = Constants.COLOR.dark,
				transparency = 0.45,
				collide = false,
			})
		end
		for _, side in { -1, 1 } do
			makePart({
				name = "DoorSeal",
				parent = shell,
				size = sizeM(1.55, 2.5, 0.1),
				cframe = CFrame.new(metres(x, 1.25, side * 1.66)),
				transparency = 1,
			})
		end
	end

	for _, x in { -9, 9 } do
		makePart({
			name = "Bulkhead",
			parent = shell,
			size = sizeM(0.1, 2.46, 1.05),
			cframe = CFrame.new(metres(x, 1.23, -0.98)),
			color = Constants.COLOR.wall,
			material = Enum.Material.Concrete,
		})
		makePart({
			name = "Bulkhead",
			parent = shell,
			size = sizeM(0.1, 2.46, 1.05),
			cframe = CFrame.new(metres(x, 1.23, 0.98)),
			color = Constants.COLOR.wall,
			material = Enum.Material.Concrete,
		})
		makePart({
			name = "Lintel",
			parent = shell,
			size = sizeM(0.1, 0.42, 1),
			cframe = CFrame.new(metres(x, 2.25, 0)),
			color = Constants.COLOR.wall,
			material = Enum.Material.Concrete,
		})
		makePart({
			name = "GangwayDoor",
			parent = shell,
			size = sizeM(0.12, 2.15, 0.96),
			cframe = CFrame.new(metres(x, 1.08, 0)),
			color = Constants.COLOR.door,
		})
	end

	local lamps: { Lamp } = {}
	local stripIndex = 0
	for _, z in { -0.62, 0.62 } do
		for i = 0, 5 do
			local x = -7.25 + i * 2.9
			local strip = makePart({
				name = string.format("LightStrip_%02d", stripIndex),
				parent = lightFolder,
				size = sizeM(2.7, 0.04, 0.18),
				cframe = CFrame.new(metres(x, 2.38, z)),
				color = Constants.COLOR.lightOn,
				material = Enum.Material.Neon,
				collide = false,
			})
			local stripLamp: Lamp = { part = strip, light = nil }
			table.insert(lamps, stripLamp)
			stripIndex += 1
		end
	end
	for _, x in { -6, -2, 2, 6 } do
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
		local anchorLamp: Lamp = { part = anchor, light = point }
		table.insert(lamps, anchorLamp)
	end

	local board = Instance.new("SpawnLocation")
	board.Name = "Board"
	board.Size = Vector3.new(3, 0.4, 3)
	board.CFrame = CFrame.new(metres(0, 0.25, 0.4))
	board.Anchored = true
	board.CanCollide = false
	board.Transparency = 1
	board.Duration = 0
	board.Neutral = true
	board.Parent = car

	car.Parent = workspace

	local imported: { string } = {}
	local fallback: { string } = {}
	for _, def in Passengers.LIST do
		local note = buildPassenger(def, passengers)
		if string.find(note, "parts", 1, true) then
			table.insert(fallback, note)
		else
			table.insert(imported, note)
		end
	end
	local meshDoors, meshLamps = adoptModeledCar(car)
	if meshDoors ~= nil and meshLamps ~= nil then
		doors = meshDoors
		lamps = meshLamps
		hidePartCarVisuals(car)
		print("[Last Local] Using modeled Car_B. Part shell stays as invisible collision.")
	end

	print(string.format("[Last Local] Imported meshes: %s", if #imported > 0 then table.concat(imported, ", ") else "none"))
	print(string.format("[Last Local] Part figures: %s", if #fallback > 0 then table.concat(fallback, ", ") else "none"))
	local riding = 0
	for _, child in passengers:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Hidden") ~= true then
			riding += 1
			local at = child:GetPivot().Position
			print(string.format("[Last Local] passenger %s at %.1f, %.1f, %.1f", child.Name, at.X, at.Y, at.Z))
		end
	end
	-- mom, dad, the three strangers, and the far-seat extra. Crowd stays hidden.
	if riding < 6 then
		warn(string.format("[Last Local] Only %d passengers are in the car; the fallback figures did not all spawn.", riding))
	end

	return {
		model = car,
		doors = doors,
		lamps = lamps,
		passengers = passengers,
		board = board,
	}
end

-- Two plates on the wall. Hidden until a tell is active. The player flags
-- one the same way as a passenger: look at it and hold Flag. They are not
-- crowd, so the crowd toggle leaves them alone.
function CarBuilder.addTells(folder: Folder, announceId: string, announceLabel: string, boardId: string, boardLabel: string)
	local function plate(id: string, label: string, kind: string, x: number)
		local model = Instance.new("Model")
		model.Name = id
		model:SetAttribute("PassengerId", id)
		model:SetAttribute("Label", label)
		model:SetAttribute("Anomaly", false)
		model:SetAttribute("Hidden", true)
		model:SetAttribute("Tell", kind)
		model:SetAttribute("Crowd", false)
		local part = Instance.new("Part")
		part.Name = "Sign"
		part.Anchored = true
		part.Size = sizeM(0.72, 0.28, 0.04)
		part.CFrame = CFrame.new(metres(x, 1.55, -1.36))
		part.Color = Constants.COLOR.dark
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part:SetAttribute("PassengerId", id)
		part.Parent = model
		model.PrimaryPart = part
		model:PivotTo(part.CFrame)
		model.Parent = folder
	end
	plate(announceId, announceLabel, "wrong_announcement", 0.2)
	plate(boardId, boardLabel, "wrong_countdown", 1.15)
end

return CarBuilder
