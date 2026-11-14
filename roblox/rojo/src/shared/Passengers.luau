--!strict
-- Fixed seats and standing spots from subwayCarBuilder.buildPassengers.
-- modelName is the instance name under ReplicatedStorage.Models, which is the
-- manifest file name without ".glb". A missing model falls back to parts.

local Passengers = {}

export type PassengerDef = {
	id: string,
	label: string,
	modelName: string?,
	x: number,
	z: number,
	ry: number,
	standing: boolean,
	anomaly: boolean,
	crowd: boolean,
	-- Optional prop model names under ReplicatedStorage.Models.
	props: { string }?,
	skin: Color3,
	shirt: Color3,
	pants: Color3,
	hair: Color3,
}

local LIST: { PassengerDef } = {
	{
		id = "mom",
		label = "Mom",
		modelName = "mom",
		x = -0.95,
		z = -1.3,
		ry = 0,
		standing = false,
		anomaly = false,
		crowd = false,
		skin = Color3.fromRGB(198, 142, 108),
		shirt = Color3.fromRGB(122, 74, 94),
		pants = Color3.fromRGB(44, 49, 64),
		hair = Color3.fromRGB(42, 28, 22),
		props = { "prop_phone" },
	},
	{
		id = "dad",
		label = "Dad",
		modelName = "dad",
		x = -0.3,
		z = -1.3,
		ry = 0,
		standing = false,
		anomaly = false,
		crowd = false,
		skin = Color3.fromRGB(185, 128, 98),
		shirt = Color3.fromRGB(62, 90, 110),
		pants = Color3.fromRGB(58, 58, 54),
		hair = Color3.fromRGB(28, 26, 24),
		props = { "prop_phone" },
	},
	{
		id = "s1",
		label = "the man across the aisle",
		modelName = "passenger_mta",
		x = 2.35,
		z = -1.3,
		ry = 0,
		standing = false,
		anomaly = false,
		crowd = false,
		skin = Color3.fromRGB(138, 90, 60),
		shirt = Color3.fromRGB(91, 107, 58),
		pants = Color3.fromRGB(34, 34, 34),
		hair = Color3.fromRGB(17, 17, 17),
	},
	{
		id = "s2",
		label = "the woman on your bench",
		modelName = "passenger_coat",
		x = -2.6,
		z = 1.3,
		ry = math.pi,
		standing = false,
		anomaly = false,
		crowd = false,
		skin = Color3.fromRGB(224, 184, 154),
		shirt = Color3.fromRGB(154, 154, 144),
		pants = Color3.fromRGB(64, 64, 74),
		hair = Color3.fromRGB(155, 150, 141),
		props = { "prop_tote_bag" },
	},
	{
		id = "s3",
		label = "the standing passenger",
		modelName = "passenger_puffer",
		x = 5.0,
		z = 0.55,
		ry = -math.pi / 2,
		standing = true,
		anomaly = false,
		crowd = false,
		skin = Color3.fromRGB(164, 112, 80),
		shirt = Color3.fromRGB(45, 45, 51),
		pants = Color3.fromRGB(81, 81, 74),
		hair = Color3.fromRGB(25, 21, 18),
	},
	-- The far-seat stranger. Web id "seat6", manifest file anomaly_extra.glb.
	-- Hidden at boarding; Ride shows them mid-stretch on the "extra" tell, then
	-- clears on arrival. anomaly_faceless / anomaly_stretched are tiny meshes
	-- (about 12 cm), not bodies, so this seat does not use them.
	{
		id = "seat6",
		label = "the seat at the far end",
		modelName = "anomaly_extra",
		x = 6.4,
		z = -1.3,
		ry = 0,
		standing = false,
		anomaly = true,
		crowd = false,
		skin = Color3.fromRGB(217, 194, 168),
		shirt = Color3.fromRGB(28, 28, 28),
		pants = Color3.fromRGB(28, 28, 28),
		hair = Color3.fromRGB(12, 12, 12),
	},
	{
		id = "c1",
		label = "a passenger in the aisle",
		modelName = "passenger_hoodie_standing",
		x = 3.0,
		z = 0.5,
		ry = -math.pi / 2,
		standing = true,
		anomaly = false,
		crowd = true,
		skin = Color3.fromRGB(155, 106, 74),
		shirt = Color3.fromRGB(107, 47, 47),
		pants = Color3.fromRGB(42, 42, 42),
		hair = Color3.fromRGB(17, 17, 17),
		props = { "prop_backpack" },
	},
	{
		id = "c2",
		label = "a passenger at the end",
		modelName = "passenger_texter_seated",
		x = -6.6,
		z = -1.3,
		ry = 0,
		standing = false,
		anomaly = false,
		crowd = true,
		skin = Color3.fromRGB(226, 196, 168),
		shirt = Color3.fromRGB(61, 95, 138),
		pants = Color3.fromRGB(46, 46, 58),
		hair = Color3.fromRGB(106, 74, 42),
		props = { "prop_phone_texter", "prop_backpack" },
	},
	{
		id = "c3",
		label = "a passenger behind you",
		modelName = "passenger_overcoat",
		x = 6.0,
		z = 1.3,
		ry = math.pi,
		standing = false,
		anomaly = false,
		crowd = true,
		skin = Color3.fromRGB(122, 78, 52),
		shirt = Color3.fromRGB(199, 166, 74),
		pants = Color3.fromRGB(42, 42, 42),
		hair = Color3.fromRGB(14, 14, 14),
	},
	{
		id = "c4",
		label = "a passenger by the door",
		modelName = "passenger_office_standing",
		x = -3.2,
		z = -0.25,
		ry = math.pi / 2,
		standing = true,
		anomaly = false,
		crowd = true,
		skin = Color3.fromRGB(201, 154, 122),
		shirt = Color3.fromRGB(77, 77, 77),
		pants = Color3.fromRGB(60, 51, 38),
		hair = Color3.fromRGB(42, 26, 16),
		props = { "prop_newspaper_folded" },
	},
	{
		id = "c5",
		label = "a passenger across",
		modelName = nil,
		x = 3.15,
		z = -1.3,
		ry = 0,
		standing = false,
		anomaly = false,
		crowd = true,
		skin = Color3.fromRGB(176, 122, 88),
		shirt = Color3.fromRGB(122, 122, 58),
		pants = Color3.fromRGB(38, 38, 38),
		hair = Color3.fromRGB(26, 26, 26),
	},
}

Passengers.LIST = LIST

-- Names to try under ReplicatedStorage.Models. Seated riders prefer the
-- seated NPC export from Bill's blend; standing riders prefer the standing one.
-- The older manifest file name still works.
function Passengers.modelNames(def: PassengerDef): { string }
	local names: { string } = {}
	local function add(name: string?)
		if name == nil or name == "" then
			return
		end
		for _, existing in names do
			if existing == name then
				return
			end
		end
		table.insert(names, name)
	end
	local archetype = if def.id == "mom"
		then "mom"
		elseif def.id == "dad" then "dad"
		elseif def.id == "s1" then "mta"
		elseif def.id == "s2" then "coat"
		elseif def.id == "s3" then "puffer"
		elseif def.id == "c1" then "hoodie"
		elseif def.id == "c2" then "texter"
		elseif def.id == "c3" then "overcoat"
		elseif def.id == "c4" then "office"
		else nil
	if archetype ~= nil and not def.standing then
		add("NPC_" .. archetype .. "_seated")
	end
	add(def.modelName)
	if archetype ~= nil then
		add("NPC_" .. archetype)
		if def.standing then
			add("NPC_" .. archetype .. "_seated")
		end
	end
	return names
end

return Passengers
