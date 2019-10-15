local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)

local module = {}
module.PBArray = nil

function pack(x, y, z)
	if not module.WorldSize then error("No WorldSize") end
	return (x + y*module.WorldSize.X + z*module.WorldSize.X*module.WorldSize.Y)
end

local ERR_BLK = blk.BLOCK_STONE
function module.GetAbsoluteBlock(x, y, z)
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	if x >= module.WorldSize.X then return ERR_BLK end
	if y >= module.WorldSize.Y then return ERR_BLK end
	if z >= module.WorldSize.Z then return ERR_BLK end
	if x < 0 then return ERR_BLK end
	if y < 0 then return ERR_BLK end
	if z < 0 then return ERR_BLK end
	return module.PBArray:get(pack(x, y, z))
end

function module.SetAbsoluteBlock(x, y, z, newBlock)
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	if x >= module.WorldSize.X then return ERR_BLK end
	if y >= module.WorldSize.Y then return ERR_BLK end
	if z >= module.WorldSize.Z then return ERR_BLK end
	if x < 0 then return ERR_BLK end
	if y < 0 then return ERR_BLK end
	if z < 0 then return ERR_BLK end
	return module.PBArray:set(pack(x, y, z), newBlock)
end

local sz = nil

function module.GetTotalSize()
	if not sz then
		 sz = {x = module.WorldSize.X, y = module.WorldSize.Y, z = module.WorldSize.Z, waterLevel = math.floor(module.WorldSize.Y/2), Volume = module.WorldSize.X*module.WorldSize.Y*module.WorldSize.Z}
	end
	return sz
end

local f = 0
local lwait = 0
function fWait(num)
	f = f + 1
	if(f > 1000) then
		f = 0
		if(tick() - lwait > 1) then
			wait()
			lwait = tick()
		end
	end
end



local HeightMap = {}

--[[#########################NOISE  GEN########################]]--

local RandNoiseX = math.random()*25000
local RandNoiseY = math.random()*25000
local RandNoiseZ = 0.5--math.random()*25000
function ImprovedNoise_Calc(x, y)
	return (math.noise((x + RandNoiseX)*1, (y + RandNoiseY)*1, (RandNoiseZ)*1))
end

function OctaveNoise_Calc(octaves, x, y)
	local amplitude, freq = 1, 1
	local sum = 0
	
	for i=0, octaves do
		sum = sum + ImprovedNoise_Calc(x * freq, y * freq) * amplitude
		amplitude = amplitude * 2.0
		freq = freq * 0.5
	end
	
	return sum
end

function CombinedNoise_Calc(octaves1, octaves2, x, y)
	local offset = OctaveNoise_Calc(octaves1, x, y)
	return OctaveNoise_Calc(octaves2, x + offset, y)
end


function Random_Next(max)
	return math.random(max)
end

function Random_Float()
	return math.random()
end

function int(num)
	return math.floor(num + 0.5)
end

--[[#########################NOTCHY GEN########################]]--

module.WaterList = {}

function module.NotchyGen_FloodFill(index, block)
	local isAir = module.GetAbsoluteBlock(index.X, index.Y, index.Z) == blk.BLOCK_AIR
	if isAir then
		module.SetAbsoluteBlock(index.X, index.Y, index.Z, block)
		if block == blk.FLOWING_WATER then
			table.insert(module.WaterList, {X=index.X, Y=index.Y, Z=index.Z})
		end
	end
end

function module.NotchyGen_FillOblateSpheroid(x, y, z, radius, block)
	local WorldMax = module.GetTotalSize()
	
	local xBeg = math.floor(math.max(x - radius, 0))
	local xEnd = math.floor(math.min(x + radius, WorldMax.x))
	local yBeg = math.floor(math.max(y - radius, 0))
	local yEnd = math.floor(math.min(y + radius, WorldMax.y))
	local zBeg = math.floor(math.max(z - radius, 0))
	local zEnd = math.floor(math.min(z + radius, WorldMax.z))
	
	local radiusSq = radius * radius
	
	local xx, yy, zz, dx, dy, dz
	
	for yy = yBeg, yEnd do dy = yy - y
		for zz = zBeg, zEnd do dz = zz - z
			for xx = xBeg, xEnd do dx = xx - x
				
				if ((dx * dx + 2 * dy * dy + dz * dz) < radiusSq) then
					if module.GetAbsoluteBlock(xx, yy, zz) == blk.BLOCK_STONE then
						module.SetAbsoluteBlock(xx, yy, zz, block)
					end
				end
			end
		end
	end
end

local minHeight

function module.NotchyGen_CreateHeightmap()
	
	HeightMap = {}
	
	local WorldMax = module.GetTotalSize()
	
	if not minHeight then
		minHeight = WorldMax.y
	end
	
	local hLow, hHigh, height
	local hIndex = 0
	local adjHeight
	local x, z
	
	for z=0, WorldMax.z-1 do
		
		HeightMap[z] = {}
		for x=0, WorldMax.x-1 do
			fWait()
			hLow = CombinedNoise_Calc(8, 8, x * 1.3, z * 1.3) / 6 - 4
			height = hLow
			
			if(OctaveNoise_Calc(6, x, z) <= 0) then
				hHigh = CombinedNoise_Calc(8, 8, x*1.3, z*1.3) / 5 + 6
				height = math.max(hLow, hHigh)
			end
			
			height = height * 0.5
			
			if (height < 0) then height = height * 0.8 end
			
			adjHeight = height + WorldMax.waterLevel
			minHeight = math.min(adjHeight, minHeight)
			HeightMap[z][x] = adjHeight
		end
		
	end
end

function module.NotchyGen_CreateStrata()
	local WorldMax = module.GetTotalSize()
	
	
	for z=0, WorldMax.z-1 do
		
		for x=0, WorldMax.x-1 do
			
			local dirtThickness = OctaveNoise_Calc(8, x, z) / 24 - 4
			local dirtHeight = HeightMap[z][x]
			local stoneHeight = dirtHeight + dirtThickness
			
			for y = 0, stoneHeight-1 do
				fWait()
				module.SetAbsoluteBlock(x, y, z, blk.BLOCK_STONE)
			end
			
			for y = stoneHeight-1, dirtHeight do
				fWait()
				module.SetAbsoluteBlock(x, y, z, blk.BLOCK_DIRT)
			end
		end
	end
end

function module.NotchyGen_CarveCaves()
	local WorldMax = module.GetTotalSize()
	
	local cavesCount = (WorldMax.Volume / 8192) * 1
	
	for i=1, cavesCount do
		local caveX = Random_Next(WorldMax.x)
		local caveY = Random_Next(WorldMax.y)
		local caveZ = Random_Next(WorldMax.z)
		
		local caveLen = int((Random_Float() * Random_Float() * 200)) * 1
		local theta = Random_Float() * 2 * math.pi; local deltaTheta = 0
		local phi = Random_Float() * 2 * math.pi; local deltaPhi = 0
		local caveRadius = Random_Float() * Random_Float()
		
		for j=1, caveLen do
			fWait()
			caveX = caveX + math.sin(theta) * math.cos(phi)
			caveZ = caveZ + math.cos(theta) * math.cos(phi)
			caveY = caveY + math.sin(phi)
			
			theta = theta + deltaTheta * 2
			deltaTheta = deltaTheta * 0.9 + Random_Float() - Random_Float()
			phi = phi * 0.5 + deltaPhi * 0.25
			deltaPhi = deltaPhi * 0.75 + Random_Float() - Random_Float()
			if (Random_Float() < 0.25) then else
				local cenX = int(caveX + (Random_Next(4) - 2) * 0.2)
				local cenY = int(caveY + (Random_Next(4) - 2) * 0.2)
				local cenZ = int(caveZ + (Random_Next(4) - 2) * 0.2)
				
				local radius = (WorldMax.y - cenY) / WorldMax.y
				radius = 1.2 + (radius * 3.5 + 1.0) * caveRadius
				radius = radius * math.sin(j * math.pi / caveLen)
				module.NotchyGen_FillOblateSpheroid(cenX, cenY, cenZ, radius, 0)
			end
		end
	end
end

function module.NotchyGen_CarveOreVeins(abundance, block)
	local WorldMax = module.GetTotalSize()
	
	local numVeins = int(WorldMax.Volume * abundance / 16384)
	
	for i=1, numVeins do
		local veinX = Random_Next(WorldMax.x)
		local veinY = Random_Next(WorldMax.y)
		local veinZ = Random_Next(WorldMax.z)
		
		local veinLen = int(Random_Float() * Random_Float() * 75 * abundance)
		local theta = Random_Float() * 2 * math.pi; local deltaTheta = 0
		local phi = Random_Float() * 2 * math.pi; local deltaPhi = 0
		
		for j=1, veinLen do
			
			fWait()
			veinX = veinX + math.sin(theta) * math.cos(phi)
			veinZ = veinZ + math.cos(theta) * math.cos(phi)
			veinY = veinY + math.sin(phi)
			
			theta = deltaTheta * 0.2
			deltaTheta = deltaTheta * 0.9 + Random_Float() - Random_Float()
			phi = phi * 0.5 + deltaPhi * 0.25
			deltaPhi = deltaPhi * 0.9 + Random_Float() - Random_Float()
			
			local radius = abundance * math.sin(j * math.pi / veinLen) + 1
			module.NotchyGen_FillOblateSpheroid(int(veinX), int(veinY), int(veinZ), radius, block)
		end
	end
end

function module.NotchyGen_FloodFillWaterBorders()
	local WorldMax = module.GetTotalSize()
	local waterLevel = int(WorldMax.y/2)
	
	local waterY = waterLevel - 1
	
	local index1 = Vector3.new(0, waterY, 0)
	local index2 = Vector3.new(0, waterY, WorldMax.z - 1)
	for x=0, WorldMax.x - 1 do
		module.NotchyGen_FloodFill(index1, blk.FLOWING_WATER)
		module.NotchyGen_FloodFill(index2, blk.FLOWING_WATER)
		
		--table.insert(module.WaterList, {X=index1.X, Y=index1.Y, Z=index1.Z})
		--table.insert(module.WaterList, {X=index2.X, Y=index2.Y, Z=index2.Z})
		
		fWait()
		index1 = index1 + Vector3.new(1, 0, 0)
		index2 = index2 + Vector3.new(1, 0, 0)
	end
	
	local index1 = Vector3.new(0, waterY, 0)
	local index2 = Vector3.new(WorldMax.x - 1, waterY, 0)
	for z=0, WorldMax.z - 1 do
		module.NotchyGen_FloodFill(index1, blk.FLOWING_WATER)
		module.NotchyGen_FloodFill(index2, blk.FLOWING_WATER)
		
		--table.insert(module.WaterList, {X=index1.X, Y=index1.Y, Z=index1.Z})
		--table.insert(module.WaterList, {X=index2.X, Y=index2.Y, Z=index2.Z})
		
		fWait()
		index1 = index1 + Vector3.new(0, 0, 1)
		index2 = index2 + Vector3.new(0, 0, 1)
	end
end

function module.NotchyGen_FloodFillWater()
	local WorldMax = module.GetTotalSize()
	local waterLevel = int(WorldMax.y/2)
	
	local numSources = WorldMax.x * WorldMax.z / 800
	for i=1, numSources do
		fWait()
		local x = Random_Next(WorldMax.x)
		local z = Random_Next(WorldMax.z)
		local y = waterLevel - math.random(1, 3)
		module.NotchyGen_FloodFill(Vector3.new(x, y, z), blk.FLOWING_WATER)
		
		--table.insert(module.WaterList, {X=x, Y=y, Z=z})
	end
end

function module.NotchyGen_FloodFillLava()
	local WorldMax = module.GetTotalSize()
	local waterLevel = int(WorldMax.y/2)
	
	local numSources = WorldMax.x * WorldMax.z / 20000
	
	for i=1, numSources do
		fWait()
		local x = Random_Next(WorldMax.x)
		local z = Random_Next(WorldMax.z)
		local y = int((waterLevel - 3) * Random_Float() * Random_Float())
		module.NotchyGen_FloodFill(Vector3.new(x, y, z), blk.FLOWING_LAVA)
	end
	
	for z=0, WorldMax.z-1 do
		for x=0, WorldMax.x-1 do
			module.SetAbsoluteBlock(x, 0, z, blk.FLOWING_LAVA)
		end
	end
end

function module.NotchyGen_CreateSurfaceLayer()
	local WorldMax = module.GetTotalSize()
	local waterLevel = int(WorldMax.y/2)
	
	for z=0, WorldMax.z-1 do
		for x=0, WorldMax.x-1 do
			fWait()
			local y = HeightMap[z][x]
			if (y < 0 or y >= WorldMax.y) then else
				local above = y >= WorldMax.y and blk.BLOCK_AIR or module.GetAbsoluteBlock(x, y+1, z)
				if((above == blk.BLOCK_WATER) and OctaveNoise_Calc(8, x, z) > 12) then
					module.SetAbsoluteBlock(x, y, z, blk.BLOCK_GRAVEL)
				elseif above == blk.BLOCK_AIR then
					local blockToSet = (y <= waterLevel and (OctaveNoise_Calc(8, x, z) > 8)) and blk.BLOCK_SAND or blk.BLOCK_GRASS
					module.SetAbsoluteBlock(x, y, z, blockToSet)
				end
			end
		end
	end
end

function module.NotchyGen_PlantFlowers()
	local WorldMax = module.GetTotalSize()
	
	local numPatches = WorldMax.x * WorldMax.z / 3000
	for i=1, numPatches do
		local block = (math.random() < 0.5) and blk.BLOCK_DANDELION or blk.BLOCK_ROSE
		local patchX = Random_Next(WorldMax.x)
		local patchZ = Random_Next(WorldMax.z)
		
		for j=1, 10 do
			local flowerX = patchX
			local flowerZ = patchZ
			for k=1, 5 do
				fWait()
				flowerX = flowerX + Random_Next(6) - Random_Next(6)
				flowerZ = flowerZ + Random_Next(6) - Random_Next(6)
				
				if flowerX > 0 and flowerZ > 0 and flowerX < WorldMax.x and flowerZ < WorldMax.z then
					local flowerY = HeightMap[flowerZ][flowerX] + 1
					if flowerY > 0 and flowerY < WorldMax.y then
						if module.GetAbsoluteBlock(flowerX, flowerY, flowerZ) == 0 and module.GetAbsoluteBlock(flowerX, flowerY-1, flowerZ) == blk.BLOCK_GRASS then
							module.SetAbsoluteBlock(flowerX, flowerY, flowerZ, block)
						end
					end
				end
			end
		end
	end
end

function module.NotchyGen_PlantMushrooms()
	local WorldMax = module.GetTotalSize()
	
	local numPatches = WorldMax.Volume / 2000
	for i=1, numPatches do
		local block = (math.random() < 0.5) and blk.BLOCK_RED_SHROOM or blk.BLOCK_BROWN_SHROOM
		local patchX = Random_Next(WorldMax.x)
		local patchY = Random_Next(WorldMax.y)
		local patchZ = Random_Next(WorldMax.z)
		
		for j=1, 20 do
			local mushX = patchX
			local mushY = patchY
			local mushZ = patchZ
			for k=1, 5 do
				fWait()
				mushX = mushX + Random_Next(6) - Random_Next(6)
				mushZ = mushZ + Random_Next(6) - Random_Next(6)
				
				if mushX <= 0 or mushZ <= 0 or mushX >= WorldMax.x or mushZ >= WorldMax.z then else
					local groundHeight = HeightMap[mushZ][mushX]
					if mushY >= (groundHeight - 1) then else
						if module.GetAbsoluteBlock(mushX, mushY, mushZ) == 0 and module.GetAbsoluteBlock(mushX, mushY-1, mushZ) == 2 then
							module.SetAbsoluteBlock(mushX, mushY, mushZ, block)
						end
					end
				end
			end
		end
	end
end


function module.TreeGen_CanGrow(x, y, z, height)
	local blockBelow = (module.GetAbsoluteBlock(x, y-1, z))
	if blockBelow ~= blk.BLOCK_GRASS then
		return false
	end
	-- check if there's room
	for yAdd=0, height-4 do
		for xA=-1, 1 do
			for zA=-1, 1 do
				local thatBlock = (module.GetAbsoluteBlock(x + xA, y + yAdd, z + zA))
				if thatBlock ~= blk.BLOCK_AIR then
					return false
				end
			end
		end
	end
	
	for yAdd=height-3, height do
		for xA=-2, 2 do
			for zA=-2, 2 do
				local thatBlock = (module.GetAbsoluteBlock(x + xA, y + yAdd, z + zA))
				if thatBlock ~= blk.BLOCK_AIR then
					return false
				end
			end
		end
	end
	
	return true --there's room!
end

function module.TreeGen_Grow(x, y, z, height)
	if module.TreeGen_CanGrow(x, y, z, height) then
		-- generate tree
		local LOGS = blk.BLOCK_LOG
		local LEAVES = blk.BLOCK_LEAVES
		for yAdd=0, height-4 do
			module.SetAbsoluteBlock(x, y + yAdd, z, LOGS)
		end
--[[
	.....	.....	%###%	%###%
	..#..	.%#%.	#####	#####
	.###.	.#O#.	##O##	##O##
	..#..	.%#%.	#####	#####
	.....	.....	%###%	%###%
--]]		

		local function randomleaves()
			return ((math.random()< 0.5) and LEAVES or blk.BLOCK_AIR)
		end
		
		local arr1 = {
			{randomleaves(), LEAVES, LEAVES, LEAVES , randomleaves()},
			{LEAVES, LEAVES, LEAVES, LEAVES, LEAVES},
			{LEAVES, LEAVES, LOGS, LEAVES, LEAVES},
			{LEAVES, LEAVES, LEAVES, LEAVES, LEAVES},
			{randomleaves(), LEAVES, LEAVES, LEAVES , randomleaves()}
		}
		
		local arr2 = {
			{randomleaves(), LEAVES, LEAVES, LEAVES , randomleaves()},
			{LEAVES, LEAVES, LEAVES, LEAVES, LEAVES},
			{LEAVES, LEAVES, LOGS, LEAVES, LEAVES},
			{LEAVES, LEAVES, LEAVES, LEAVES, LEAVES},
			{randomleaves(), LEAVES, LEAVES, LEAVES , randomleaves()}
		}
		
		local arr3 = {
			{0, 0, 0, 0, 0,},
			{0, randomleaves(), LEAVES, randomleaves(), 0},
			{0, LEAVES, LOGS, LEAVES, 0},
			{0, randomleaves(), LEAVES, randomleaves(), 0},
			{0, 0, 0, 0, 0}
		}
		
		local arr4 = {
			{0, 0, 0, 0, 0},
			{0, 0, LEAVES, 0, 0},
			{0, LEAVES, LEAVES, LEAVES, 0},
			{0, 0, LEAVES, 0, 0},
			{0, 0, 0, 0, 0}
		}
		
		local function DrawTbl(tbl, dx, dy, dz)
			local xMax = #tbl[1]
			local yMax = #tbl
			
			local xCentric = math.ceil(xMax/2)
			local yCentric = math.ceil(yMax/2)
			
			for Y=1, yMax do
				for X=1, xMax do
					module.SetAbsoluteBlock(dx + (X - xCentric), dy, dz + (Y - yCentric), tbl[Y][X])
				end
			end
		end
		
		
		DrawTbl(arr1, x, y+height-3, z)
		DrawTbl(arr2, x, y+height-2, z)
		DrawTbl(arr3, x, y+height-1, z)
		DrawTbl(arr4, x, y+height, z)		
	end
end

function module.NotchyGen_PlantTrees()
	local WorldMax = module.GetTotalSize()
	local numPatches = WorldMax.x * WorldMax.z / 4000
	for i=1, numPatches do
		local patchX = Random_Next(WorldMax.x)
		local patchZ = Random_Next(WorldMax.z)
		
		for j=1, 20 do
			local treeX = patchX
			local treeZ = patchZ
			for k=1, 20 do
				fWait()
				treeX = treeX + Random_Next(6) - Random_Next(6)
				treeZ = treeZ + Random_Next(6) - Random_Next(6)
				
				if (treeX > 0 and treeZ > 0 and treeX < WorldMax.x and treeZ < WorldMax.z) and (Random_Float() <= 0.25) then
					--pcall(function()
						local treeY = HeightMap[treeZ][treeX] + 1
						if not (treeY >= WorldMax.y) then
							local treeHeight = 4 + Random_Next(3)
							module.TreeGen_Grow(treeX, treeY, treeZ, treeHeight-1)
						end
					--end)
				end
			end
		end
	end
end




function module.WaterSim()
	local InsertWater = {}
	local DelWater = {}
	for k, v in pairs(module.WaterList) do
		local attempts = {
			{v.X+1, v.Y, v.Z},
			{v.X-1, v.Y, v.Z},
			{v.X, v.Y, v.Z+1},
			{v.X, v.Y, v.Z-1},
			{v.X, v.Y-1, v.Z}
		}
		local anything = false
		for _, b in pairs(attempts) do
			local yesBlock = module.GetAbsoluteBlock(b[1], b[2], b[3])
			if yesBlock == blk.BLOCK_AIR then
				anything = true
				module.SetAbsoluteBlock(b[1], b[2], b[3], blk.FLOWING_WATER)
				table.insert(InsertWater, {X=b[1], Y=b[2], Z=b[3]})
			end
		end
		fWait()
		if not anything then
			table.insert(DelWater, k)
		end
	end
	for k, v in pairs(DelWater) do
		fWait()
		table.remove(module.WaterList, v-(k-1))
	end
	for k, v in pairs(InsertWater) do
		fWait()
		table.insert(module.WaterList, v)
	end

end


function module.NotchyGen(PoolByteArray, Dimensions, off)
	module.Reseed()
	
	if module.WorldSize ~= Dimensions then
		sz = nil
	end
	
	module.WorldSize = Dimensions
	module.PBArray = PoolByteArray
	
	
	
	module.NotchyGen_CreateHeightmap()
	module.NotchyGen_CreateStrata()
	module.NotchyGen_CarveCaves()
	module.NotchyGen_CarveOreVeins(0.9, blk.BLOCK_COAL_ORE)
	module.NotchyGen_CarveOreVeins(0.7, blk.BLOCK_IRON_ORE)
	module.NotchyGen_CarveOreVeins(0.5, blk.BLOCK_GOLD_ORE)
	
	module.WaterList = {}
	
	module.NotchyGen_FloodFillWaterBorders()
	module.NotchyGen_FloodFillWater()
	module.NotchyGen_FloodFillLava()
	
	if true then
		while #module.WaterList ~= 0 do
			module.WaterSim()
		end
	end
	
	module.NotchyGen_CreateSurfaceLayer()
	module.NotchyGen_PlantFlowers()
	module.NotchyGen_PlantMushrooms()
	module.NotchyGen_PlantTrees()
end

function module.Reseed()
	RandNoiseX = math.random()*25000
	RandNoiseY = math.random()*25000
	RandNoiseZ = math.random()*25000
end

module.Reseed()
return module.NotchyGen