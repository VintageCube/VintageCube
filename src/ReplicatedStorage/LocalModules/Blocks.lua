--[[
	Block definitions
]]


local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5
local Gas = 6

local NoPhysics = -1
local Falling = 1
local Flowing = 2


local terrain = require(game.ReplicatedStorage.LocalModules.terrain)

local Yes = {

	[-1] = {
		Name = "OOB",
		Texture = "",
		Solidity = SolidBlock
	},

	[0] = {
		Name = "Air",
		Texture = "",
		Solidity = Gas
	},

	[1] = {
		Name = "Stone",
		Texture = terrain.tile001,
	},


	[2] = {
		Name = "Grass Block",
		Texture = terrain.tile002,
		Top = terrain.tile000,
		Sides = terrain.tile003
	},
	
	[3] = {
		Name = "Dirt",
		Texture = terrain.tile002
	},
	
	[4] = {
		Name = "Cobblestone",
		Texture = terrain.tile016
	},

	[5] = {
		Name = "Planks",
		Texture = terrain.tile004,
	},

	[6] = {
		Name = "Sapling",
		Texture = terrain.tile015,
		Solidity = Plant,
		HitSize = Vector3.new(0.5, 0.6, 0.5)
	},

	[7] = {
		Name = "Bedrock",
		Texture = terrain.tile017,
	},
	
	[8] = {
		Name = "Flowing Water",
		Texture = terrain.tile014,
		Solidity = Liquid,
		Physics = Flowing,
		AnimatedWater = true
	},
	
	[9] = {
		Name = "Stationary Water",
		Texture = terrain.tile014,
		Solidity = Liquid,
		AnimatedWater = true
	},
	
	[10] = {
		Name = "Flowing Lava",
		Texture = terrain.tile030,
		Solidity = Liquid,
		Physics = Flowing,
		FullBright = true,
		AnimatedLava = true
	},
	
	[11] = {
		Name = "Stationary Lava",
		Texture = terrain.tile030,
		Solidity = Liquid,
		FullBright = true,
		AnimatedLava = true
	},
	
	[12] = {
		Name = "Sand",
		Texture = terrain.tile018,
	},
	
	
	[13] = {
		Name = "Gravel",
		Texture = terrain.tile019,
		Physics = Falling
	},

	[14] = {
		Name = "Gold ore",
		Texture = terrain.tile032
	},
	

	
	[15] = {
		Name = "Iron ore",
		Texture = terrain.tile033
	},
	
	[16] = {
		Name = "Coal ore",
		Texture = terrain.tile034
	},
	
	[17] = {
		Name = "Wood",
		Texture = terrain.tile020,
		TopBottom = terrain.tile021,
	},
	
	[18] = {
		Name = "Leaves",
		Texture = terrain.tile022,
		Solidity = Transparent--SolidBlock
	},
	

	[19] = {
		Name = "Sponge",
		Texture = terrain.tile048
	},
	
	[20] = {
		Name = "Glass",
		Texture = terrain.tile049,
		Solidity = TransparentInside
	},
	
	-- WOOL BEGIN	
	[21] = {
		Name = "Red",
		Texture = terrain.tile064
	},
	[22] = {
		Name = "Orange",
		Texture = terrain.tile065
	},
	[23] = {
		Name = "Yellow",
		Texture = terrain.tile066
	},
	[24] = {
		Name = "Lime",
		Texture = terrain.tile067
	},
	[25] = {
		Name = "Green",
		Texture = terrain.tile068
	},
	[26] = {
		Name = "Teal",
		Texture = terrain.tile069
	},
	[27] = {
		Name = "Aqua",
		Texture = terrain.tile070
	},
	[28] = {
		Name = "Cyan",
		Texture = terrain.tile071
	},
	[29] = {
		Name = "Blue",
		Texture = terrain.tile072
	},
	[30] = {
		Name = "Indigo",
		Texture = terrain.tile073
	},
	[31] = {
		Name = "Violet",
		Texture = terrain.tile074
	},
	[32] = {
		Name = "Magenta",
		Texture = terrain.tile075
	},
	[33] = {
		Name = "Pink",
		Texture = terrain.tile076
	},
	[34] = {
		Name = "Black",
		Texture = terrain.tile077
	},
	[35] = {
		Name = "Gray",
		Texture = terrain.tile078
	},
	[36] = {
		Name = "White",
		Texture = terrain.tile079
	},
	
	-- WOOL END
	
	[37] = {
		Name = "Dandelion",
		Texture = terrain.tile013,
		Solidity = Plant,
		HitSize = Vector3.new(0.3, 0.4, 0.3)
	},
	
	[38] = {
		Name = "Rose",
		Texture = terrain.tile012,
		Solidity = Plant,
		HitSize = Vector3.new(0.3, 0.5, 0.3)
	},
	
	[39] = {
		Name = "Brown mushroom",
		Texture = terrain.tile029,
		Solidity = Plant,
		HitSize = Vector3.new(0.24, 0.36, 0.24)
	},
	
	[40] = {
		Name = "Red mushroom",
		Texture = terrain.tile028,
		Solidity = Plant,
		HitSize = Vector3.new(0.24, 0.3, 0.24)
	},

	[41] = {
		Name = "Gold",
		Texture = terrain.tile040,
		Top = terrain.tile024,
		Bottom = terrain.tile056
	},
	
	[42] = {
		Name = "Iron",
		Texture = terrain.tile039,
		Top = terrain.tile023,
		Bottom = terrain.tile055
	},
	
	[43] = {
		Name = "Double Slab",
		Texture = terrain.tile005,
		TopBottom = terrain.tile006
	},
	
	[44] = {
		Name = "Slab",
		Texture = terrain.tile005,
		BlockHeight = 0.5,
		TopBottom = terrain.tile006
	},	
	
	[45] = {
		Name = "Bricks",
		Texture = terrain.tile007
	},
	
	[46] = {
		Name = "TNT",
		Texture = terrain.tile008,
		Top = terrain.tile009,
		Bottom = terrain.tile010
	},

	[47] = {
		Name = "Bookshelf",
		Texture = terrain.tile035,
		TopBottom = terrain.tile004
	},
	
	[48] = {
		Name = "Mossy rocks",
		Texture = terrain.tile036
	},
	
	[49] = {
		Name = "Obsidian",
		Texture = terrain.tile037
	}
	
	
}

for k, v in pairs(Yes) do
	if not v.Physics then
		v.Physics = NoPhysics
	end
	
	if not v.Solidity then
		v.Solidity = SolidBlock
	end
end


return Yes
