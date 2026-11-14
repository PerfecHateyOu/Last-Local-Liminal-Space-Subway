--!strict
-- Parts-built False Stop Trial room (trialBuilder.ts shaped for Rojo).
-- Three openings with lying signs and lights that flick on the chime.

local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local TrialSpace = {}

export type Opening = {
	index: number,
	lamp: BasePart,
	light: PointLight,
	signLabel: TextLabel,
	interior: BasePart,
	leaves: { { part: BasePart, x0: number, side: number } },
	flickUntil: number,
	openAmt: number,
	target: number,
}

export type Built = {
	model: Model,
	spawn: CFrame,
	openings: { Opening },
	tileParts: { BasePart },
}

local ORIGIN = CFrame.new(0, 480, 0)
local S = Constants.STUDS_PER_METER

local function part(
	name: string,
	parent: Instance,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	collide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = if collide == nil then true else collide
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

function TrialSpace.build(): Built
	local model = Instance.new("Model")
	model.Name = "TrialSpace"
	model.Parent = workspace

	local tile = Color3.fromRGB(210, 205, 190)
	local floorC = Color3.fromRGB(106, 104, 96)
	local ceilC = Color3.fromRGB(58, 60, 56)
	local yellow = Color3.fromRGB(227, 195, 65)
	local dark = Color3.fromRGB(5, 5, 5)

	part("Floor", model, Vector3.new(12 * S, 0.3, 14 * S), ORIGIN * CFrame.new(0, -0.15, -3 * S), floorC)
	part("Ceil", model, Vector3.new(12 * S, 0.3, 14 * S), ORIGIN * CFrame.new(0, 3.6 * S, -3 * S), ceilC)
	part("LeftWall", model, Vector3.new(0.3, 3.7 * S, 14 * S), ORIGIN * CFrame.new(-6 * S, 1.8 * S, -3 * S), tile)
	part("RightWall", model, Vector3.new(0.3, 3.7 * S, 14 * S), ORIGIN * CFrame.new(6 * S, 1.8 * S, -3 * S), tile)
	part("BackWall", model, Vector3.new(12 * S, 3.7 * S, 0.3), ORIGIN * CFrame.new(0, 1.8 * S, 4 * S), tile)

	for _, span in { { -6, -3.8 }, { -2.2, -0.8 }, { 0.8, 2.2 }, { 3.8, 6 } } do
		local a, b = span[1], span[2]
		part(
			"Divider",
			model,
			Vector3.new((b - a) * S, 3.7 * S, 0.6),
			ORIGIN * CFrame.new(((a + b) / 2) * S, 1.8 * S, -7 * S),
			tile
		)
	end
	part("Safety", model, Vector3.new(12 * S, 0.2, 0.6 * S), ORIGIN * CFrame.new(0, 0.1, -6.3 * S), yellow)

	local openings: { Opening } = {}
	local tileParts: { BasePart } = {}

	for i, x in { -3, 0, 3 } do
		local index = i - 1
		part("Arch_" .. index, model, Vector3.new(1.6 * S, 1.3 * S, 0.6), ORIGIN * CFrame.new(x * S, 3.0 * S, -7 * S), tile)
		part("Void_" .. index, model, Vector3.new(1.6 * S, 2.4 * S, 0.8 * S), ORIGIN * CFrame.new(x * S, 1.2 * S, -7.5 * S), dark, false)

		local lamp = part(
			"Lamp_" .. index,
			model,
			Vector3.new(1.2 * S, 0.12, 0.12),
			ORIGIN * CFrame.new(x * S, 3.32 * S, -6.85 * S),
			Color3.fromRGB(255, 242, 214),
			false
		)
		lamp.Material = Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Brightness = 1.2
		light.Range = 5.5 * S
		light.Color = Color3.fromRGB(255, 240, 208)
		light.Parent = lamp

		local signBack = part(
			"SignBack_" .. index,
			model,
			Vector3.new(2.3 * S, 0.58 * S, 0.08),
			ORIGIN * CFrame.new(x * S, 2.92 * S, -6.8 * S),
			Color3.fromRGB(17, 19, 17),
			false
		)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.Parent = signBack
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Text = ""
		label.Parent = gui

		local interior = part(
			"Interior_" .. index,
			model,
			Vector3.new(1.6 * S, 2.4 * S, 0.6 * S),
			ORIGIN * CFrame.new(x * S, 1.2 * S, -7.6 * S),
			Color3.fromRGB(216, 160, 96),
			false
		)
		interior.Transparency = 1

		local leaves = {}
		for _, side in { -1, 1 } do
			local leaf = part(
				"Leaf_" .. index .. "_" .. side,
				model,
				Vector3.new(0.8 * S, 2.4 * S, 0.08),
				ORIGIN * CFrame.new((x + side * 0.4) * S, 1.2 * S, -6.95 * S),
				Color3.fromRGB(154, 160, 156),
				false
			)
			leaf.Transparency = 1
			table.insert(leaves, { part = leaf, x0 = (x + side * 0.4) * S, side = side })
		end

		table.insert(openings, {
			index = index,
			lamp = lamp,
			light = light,
			signLabel = label,
			interior = interior,
			leaves = leaves,
			flickUntil = -1,
			openAmt = 0,
			target = 0,
		})
	end

	local spawn = ORIGIN * CFrame.new(0, 1.2 * S, 1.5 * S) * CFrame.Angles(0, math.pi, 0)
	model:SetAttribute("Active", false)
	TrialSpace.setVisible(model, false)

	return {
		model = model,
		spawn = spawn,
		openings = openings,
		tileParts = tileParts,
	}
end

function TrialSpace.setVisible(model: Model, visible: boolean)
	model:SetAttribute("Active", visible)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			local isDoorish = desc.Name:find("Interior_", 1, true) ~= nil or desc.Name:find("Leaf_", 1, true) ~= nil
			local isDecor = desc.Name:find("Lamp_", 1, true) ~= nil
				or desc.Name:find("SignBack_", 1, true) ~= nil
				or desc.Name:find("Void_", 1, true) ~= nil
			if visible then
				if not isDoorish then
					desc.Transparency = 0
				end
				desc.CanCollide = not isDecor and not isDoorish
			else
				desc.Transparency = 1
				desc.CanCollide = false
			end
		elseif desc:IsA("PointLight") or desc:IsA("SurfaceGui") then
			desc.Enabled = visible
		end
	end
end

function TrialSpace.applyRound(built: Built, signs: { string }, boardDoors: boolean)
	for _, opening in built.openings do
		local text = signs[opening.index + 1] or ""
		opening.signLabel.Text = text
		opening.openAmt = 0
		opening.target = 0
		opening.flickUntil = -1
		local showDoor = boardDoors and opening.index ~= 1
		opening.interior.Transparency = if showDoor then 0 else 1
		for _, leaf in opening.leaves do
			leaf.part.Transparency = if showDoor then 0 else 1
			leaf.part.CFrame = ORIGIN * CFrame.new(leaf.x0, 1.2 * S, -6.95 * S)
		end
		opening.lamp.Color = Color3.fromRGB(255, 242, 214)
		opening.light.Brightness = 1.2
		opening.light.Enabled = true
	end
end

function TrialSpace.flick(opening: Opening, untilClock: number)
	opening.flickUntil = untilClock
end

function TrialSpace.setDoorTarget(opening: Opening, target: number)
	opening.target = target
end

function TrialSpace.step(built: Built, dt: number, now: number)
	for _, opening in built.openings do
		local off = now < opening.flickUntil
		opening.lamp.Color = if off then Color3.fromRGB(17, 17, 17) else Color3.fromRGB(255, 242, 214)
		opening.light.Brightness = if off then 0 else 1.2
		opening.openAmt += (opening.target - opening.openAmt) * (1 - math.exp(-9 * dt))
		for _, leaf in opening.leaves do
			if leaf.part.Transparency < 1 then
				leaf.part.CFrame = ORIGIN
					* CFrame.new(leaf.x0 + leaf.side * 0.75 * S * opening.openAmt, 1.2 * S, -6.95 * S)
			end
		end
	end
end

function TrialSpace.teleportPlayers(cf: CFrame)
	local Players = game:GetService("Players")
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root ~= nil and root:IsA("BasePart") then
			root.CFrame = cf
		end
	end
end

return TrialSpace
