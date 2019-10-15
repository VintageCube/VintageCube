local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)
local sdef = require(game.ServerStorage.sDefs)

local Physics = {}



function Physics.GetBlockAt(x, y, z)
	return sdef.GetAbsoluteBlock(x, y, z)
end


function Physics.SetBlockAt(x, y, z, blk)
	sdef.SetAbsoluteBlockAndSend(x, y, z, blk)
end

function Physics.exists(x, y, z)
	local size = sdef.GetTotalSize()
	if x < 0 or y < 0 or z < 0 then return false end
	if x >= size.x or y >= size.y or z >= size.z then return false end
	return true
end

function Physics.FlushBlockBuffer()
	--game.ServerStorage.FlushBlockBuffer:Fire()
end

Physics.PhysicsBlocks = {
	[blk.FLOWING_LAVA] = "Lava",
	[blk.FLOWING_WATER] = "Water",
	[blk.BLOCK_SAND] = "Sand"
}


Physics.FastBlockPhysics = {
	Water = function(x, y, z)
		local Insert = {}
		if Physics.GetBlockAt(x, y, z) == blk.FLOWING_WATER then
			local attempts = {
				{x+1, y, z},
				{x-1, y, z},
			--	{x, y+1, z},
				{x, y-1, z},
				{x, y, z+1},
				{x, y, z-1}
			}
			
			for k, v in pairs(attempts) do
				if(Physics.exists(v[1], v[2], v[3])) then
					local ThatBlock = Physics.GetBlockAt(v[1], v[2], v[3])
					if ThatBlock == blk.BLOCK_AIR then
						Physics.SetBlockAt(v[1], v[2], v[3], blk.FLOWING_WATER)
						table.insert(Insert, {v[1], v[2], v[3], "Water"})
					elseif ThatBlock == blk.FLOWING_LAVA then
						Physics.SetBlockAt(v[1], v[2], v[3], blk.BLOCK_OBSIDIAN)
					end
				end
			end
		end
		
		return {Active = false, Insert = Insert, ToUpdate = {}}
	end,
	
	Sand = function(x, y, z)
		local Insert = {}
		local Update = {}
		if Physics.GetBlockAt(x, y, z) == blk.BLOCK_SAND then
			if(Physics.exists(x, y-1, z)) then
				if Physics.GetBlockAt(x, y-1, z) == blk.BLOCK_AIR then
					Physics.SetBlockAt(x, y, z, 0)
					Physics.SetBlockAt(x, y-1, z, blk.BLOCK_SAND)
					table.insert(Insert, {x, y-1, z, "Sand"})
					table.insert(Update, {x, y, z})
				end
			end
			
		end
		return {Active = false, Insert = Insert, ToUpdate = Update}
	end,
	
}

Physics.SlowBlockPhysics = {
	Lava = function(x, y, z)
		local Insert = {}
		if Physics.GetBlockAt(x, y, z) == blk.FLOWING_LAVA then
			local attempts = {
				{x+1, y, z},
				{x-1, y, z},
			--	{x, y+1, z},
				{x, y-1, z},
				{x, y, z+1},
				{x, y, z-1}
			}
			
			for k, v in pairs(attempts) do
				if(Physics.exists(v[1], v[2], v[3])) then
					local ThatBlock = Physics.GetBlockAt(v[1], v[2], v[3])
					if ThatBlock == blk.BLOCK_AIR then
						Physics.SetBlockAt(v[1], v[2], v[3], blk.FLOWING_LAVA)
						table.insert(Insert, {v[1], v[2], v[3], "Lava"})
					elseif ThatBlock == blk.FLOWING_WATER then
						Physics.SetBlockAt(v[1], v[2], v[3], blk.BLOCK_COBBLE)
					end
				end
			end
		end
		
		return {Active = false, Insert = Insert}
	end,
}

Physics.RandomBlockPhysics = {
	
}


Physics.ActiveFBlocks = {}
Physics.ActiveSBlocks = {}
Physics.ActiveRBlocks = {}
function Physics.FastTick()
	local Updates = {}
	for k, v in pairs(Physics.ActiveFBlocks) do
		if Physics.FastBlockPhysics[k] then
			local InsertToArray = {}
			local DeleteFromArray = {}
			for a, b in pairs(v) do
				local Result = Physics.FastBlockPhysics[k](b[1], b[2], b[3])
				if Result.Active == false then
					table.insert(DeleteFromArray, a)
				end
				if #Result.Insert > 0 then
					for _, s in pairs(Result.Insert) do
						table.insert(InsertToArray, s)
					end
				end
				if #Result.ToUpdate > 0 then
					for _, s in pairs(Result.ToUpdate) do
						table.insert(Updates, s)
					end
				end
			end
			
			for a, b in pairs(DeleteFromArray) do
				table.remove(v, b-(a-1))
			end
			
			for a, b in pairs(InsertToArray) do
				table.insert(Physics.ActiveFBlocks[b[4]], {b[1], b[2], b[3]})
			end
		end
	end
	Physics.FlushBlockBuffer()
	for a, b in pairs(Updates) do
		Physics.Update(b[1], b[2], b[3])
	end
end

function Physics.SlowTick()
	for k, v in pairs(Physics.ActiveSBlocks) do
		if Physics.SlowBlockPhysics[k] then
			local InsertToArray = {}
			local DeleteFromArray = {}
			for a, b in pairs(v) do
				local Result = Physics.SlowBlockPhysics[k](b[1], b[2], b[3])
				if Result.Active == false then
					table.insert(DeleteFromArray, a)
				end
				if #Result.Insert > 0 then
					for _, s in pairs(Result.Insert) do
						table.insert(InsertToArray, s)
					end
				end
			end
			
			for a, b in pairs(DeleteFromArray) do
				table.remove(v, b-(a-1))
			end
			
			for a, b in pairs(InsertToArray) do
				table.insert(Physics.ActiveSBlocks[b[4]], {b[1], b[2], b[3]})
			end
		end
	end
	Physics.FlushBlockBuffer()
end

function Physics.RandomTick()
	for k, v in pairs(Physics.ActiveRBlocks) do
		if Physics.RandomBlockPhysics[k] then
			local InsertToArray = {}
			local DeleteFromArray = {}
			for a, b in pairs(v) do
				local Result = Physics.RandomBlockPhysics[k](b[1], b[2], b[3])
				if Result.Active == false then
					table.insert(DeleteFromArray, a)
				end
				if #Result.Insert > 0 then
					for _, s in pairs(Result.Insert) do
						table.insert(InsertToArray, s)
					end
				end
			end
			
			for a, b in pairs(DeleteFromArray) do
				table.remove(v, b-(a-1))
			end
			
			for a, b in pairs(InsertToArray) do
				table.insert(Physics.ActiveRBlocks[b[4]], {b[1], b[2], b[3]})
			end
		end
	end
end

spawn(function()
	while wait(0.5) do
		Physics.FastTick()
	end
end)

spawn(function()
	while wait(1) do
		Physics.SlowTick()
	end
end)

spawn(function()
	while wait(math.random() * 10) do
		Physics.RandomTick()
	end
end)

function Physics.Update(x, y, z)
	local attempts = {
		{x, y, z},
		{x+1, y, z},
		{x-1, y, z},
		{x, y+1, z},
		{x, y-1, z},
		{x, y, z+1},
		{x, y, z-1}
	}
	
	
	for k, v in pairs(attempts) do
		if Physics.exists(v[1], v[2], v[3]) then
		local ThisBlock = Physics.GetBlockAt(v[1], v[2], v[3])
		local PhysicsName = Physics.PhysicsBlocks[ThisBlock]
		if PhysicsName then
	--			if not Physics.ActiveBlocks[PhysicsName] then
	--				Physics.ActiveBlocks[PhysicsName] = {}
	--			end
	--			table.insert(Physics.ActiveBlocks[PhysicsName], v)
				local Fast = Physics.FastBlockPhysics[PhysicsName] ~= nil
				local Slow = Physics.SlowBlockPhysics[PhysicsName] ~= nil
				local Rand = Physics.RandomBlockPhysics[PhysicsName] ~= nil
				
				if Fast then
					if not Physics.ActiveFBlocks[PhysicsName] then
						Physics.ActiveFBlocks[PhysicsName] = {}
					end
					table.insert(Physics.ActiveFBlocks[PhysicsName], v)
				end
				
				if Slow then
					if not Physics.ActiveSBlocks[PhysicsName] then
						Physics.ActiveSBlocks[PhysicsName] = {}
					end
					table.insert(Physics.ActiveSBlocks[PhysicsName], v)
				end
				
				if Rand then
					if not Physics.ActiveRBlocks[PhysicsName] then
						Physics.ActiveRBlocks[PhysicsName] = {}
					end
					table.insert(Physics.ActiveRBlocks[PhysicsName], v)
				end
			end
		end
	end
	
	local s = Physics.PhysicsBlocks[Physics.GetBlockAt(x, y, z)]
	if s and Physics.FastBlockPhysics[s] then
		Physics.FastBlockPhysics[s](x,y,z)
		Physics.FlushBlockBuffer()
	end
end

sdef.BindToUpdate(Physics.Update)

return Physics