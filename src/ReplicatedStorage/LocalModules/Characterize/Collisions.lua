-- collisions moved to a separate module because the main script was already enough of a mess

local AABB, LocalCharacter, world, Blocks

local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)

local Entity = require(game.ReplicatedStorage.LocalModules.Entity)

function IVec3_Floor(v3)
	return Vector3.new(math.floor(v3.X), math.floor(v3.Y), math.floor(v3.Z))
end

function IVec3_Ceil(v3)
	return Vector3.new(math.ceil(v3.X), math.ceil(v3.Y), math.ceil(v3.Z))
end

local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5

function IsSolid(block)
	return block ~= 0 and ((Blocks[block].Solidity == SolidBlock) or (Blocks[block].Solidity == Transparent) or (Blocks[block].Solidity == TransparentInside))
end


function Searcher_CalcTime(vel, entityBB, blockBB)
	local dx = vel.X > 0 and (blockBB.Start.X - entityBB.End.X) or (entityBB.Start.X - blockBB.End.X)
	local dy = vel.Y > 0 and (blockBB.Start.Y - entityBB.End.Y) or (entityBB.Start.Y - blockBB.End.Y)
	local dz = vel.Z > 0 and (blockBB.Start.Z - entityBB.End.Z) or (entityBB.Start.Z - blockBB.End.Z)
	
	local tx = vel.X == 0 and math.huge or math.abs(dx / vel.X)
	local ty = vel.Y == 0 and math.huge or math.abs(dy / vel.Y)
	local tz = vel.Z == 0 and math.huge or math.abs(dz / vel.Z)
	
	if ((entityBB.End.X >= blockBB.Start.X) and (entityBB.Start.X <= blockBB.End.X)) then tx = 0 end
	if ((entityBB.End.Y >= blockBB.Start.Y) and (entityBB.Start.Y <= blockBB.End.Y)) then ty = 0 end
	if ((entityBB.End.Z >= blockBB.Start.Z) and (entityBB.Start.Z <= blockBB.End.Z)) then tz = 0 end
	return tx, ty, tz
end


local blockToBB = require(game.ReplicatedStorage.LocalModules.BlockGen).ToBB

function GetEntityBB()
--	local pos = Vector3.new(LocalCharacter.Base.xPos, LocalCharacter.Base.yPos, LocalCharacter.Base.zPos)
--	local size = Vector3.new(0.5,1.85,0.5)
--	local min = pos - (size * Vector3.new(1,0,1))/2
--	local max = pos + (size * Vector3.new(1,2,1))/2
--	
--	local entityBB = AABB.New(min, max)

	local entityBB = LocalCharacter.LocalEntity.api.get_aabb(Vector3.new(LocalCharacter.Base.xPos, LocalCharacter.Base.yPos, LocalCharacter.Base.zPos))
	
	return entityBB
end

local SearcherStates = {}

local COLLISIONS_ADJ = 0.001

function Searcher_FindReachableBlocks(entityBB, entityExtentBB)
	debug.profilebegin("findreachable")
	local vel = Vector3.new(LocalCharacter.Base.xVel, LocalCharacter.Base.yVel, LocalCharacter.Base.zVel)
	

	local min = entityBB.Start
	local max = entityBB.End
	
	min = Vector3.new(
		min.X + (vel.X < 0 and vel.X or 0) - COLLISIONS_ADJ,
		min.Y + (vel.Y < 0 and vel.Y or 0) - COLLISIONS_ADJ,
		min.Z + (vel.Z < 0 and vel.Z or 0) - COLLISIONS_ADJ
	)
	
	max = Vector3.new(
		max.X + (vel.X > 0 and vel.X or 0) + COLLISIONS_ADJ,
		max.Y + (vel.Y > 0 and vel.Y or 0) + COLLISIONS_ADJ,
		max.Z + (vel.Z > 0 and vel.Z or 0) + COLLISIONS_ADJ
	)
	
	entityExtentBB:SetMin(min)
	entityExtentBB:SetMax(max)
	
	
	
	local imin = IVec3_Floor(min)
	local imax = IVec3_Ceil(max)
	
	local elements = (imax.X - imin.X + 1) * (imax.Y - imin.Y + 1) * (imax.Z - imin.Z + 1)
	
	SearcherStates = {}
	local curState = 1
	
	for y = imin.Y, imax.Y do
		for z = imin.Z, imax.Z do
			for x = imin.X, imax.X do
				local block = -1
				if world.exists(x, y, z) then
					block = world.get(x, y, z)
				elseif world.exists(x, 1, z) and y > 0 then
					block = 0
				end
				if((IsSolid(block))) then
					local blockBB = blockToBB(block, Vector3.new(x, y, z))
					if(entityExtentBB:Intersects(blockBB)) then
						local tx, ty, tz = Searcher_CalcTime(vel, entityBB, blockBB)
						if not(tx > 1 or ty > 1 or tz > 1) then
							
--							cs.X = bit32.bor(bit32.lshift(x, 3), bit32.band(block, 0x007))
--							cs.Y = bit32.bor(bit32.lshift(y, 4), bit32.rshift(bit32.band(block, 0x078), 3))
--							cs.Z = bit32.bor(bit32.lshift(z, 3), bit32.rshift(bit32.band(block, 0x380), 3))
							
							SearcherStates[curState] = {
								X = x,
								Y = y,
								Z = z,
								Block = block,
								tSquared = tx * tx + ty * ty + tz * tz
							}
							
							curState = curState + 1
							
						end
					end
				end
			end
		end
	end
	
	
	debug.profilebegin("sort")
	local count = curState-1
	if(count) then
		table.sort(SearcherStates, function(a, b)
			return a.tSquared < b.tSquared
		end)
	end
	debug.profileend()
	debug.profileend()
	
	return count
end

function Collisions_CanSlideThrough(adjFinalBB)
	
	local bbMin = IVec3_Floor(adjFinalBB.Start)
	local bbMax = IVec3_Ceil(adjFinalBB.End)
	
	for y = (bbMin.Y), bbMax.Y  do
		for z = (bbMin.Z), bbMax.Z do
			for x = (bbMin.X), bbMax.X do
				local block = -1
				if world.exists(x, y, z) then
					block = world.get(x, y, z)
				end
				local blockBB = blockToBB(block, Vector3.new(x, y, z))
				if not (not blockBB:Intersects(adjFinalBB)) then
					if IsSolid(block) then return false end
				end
			end
		end
	end
	return true
end
	

function Collisions_ClipX(entityBB, extentBB)
	LocalCharacter.Base.xVel = 0
	local min = Vector3.new(
		LocalCharacter.Base.xPos - entityBB.Size.X/2,
		entityBB.Start.Y,
		entityBB.Start.Z
	)
	local max = Vector3.new(
		LocalCharacter.Base.xPos + entityBB.Size.X/2,
		entityBB.End.Y,
		entityBB.End.Z
	)
	entityBB:SetMin(min, Vector3.new(1, 0, 0))
	extentBB:SetMin(min, Vector3.new(1, 0, 0))
	
	entityBB:SetMax(max, Vector3.new(1, 0, 0))
	extentBB:SetMax(max, Vector3.new(1, 0, 0))
end

function Collisions_ClipY(entityBB, extentBB)
	LocalCharacter.Base.yVel = 0
	local min = Vector3.new(
		entityBB.Start.X,
		LocalCharacter.Base.yPos,
		entityBB.Start.Z
	)
	local max = Vector3.new(
		entityBB.End.X,
		LocalCharacter.Base.yPos + entityBB.Size.Y,
		entityBB.End.Z
	)
	entityBB:SetMin(min, Vector3.new(0, 1, 0))
	extentBB:SetMin(min, Vector3.new(0, 1, 0))
	
	entityBB:SetMax(max, Vector3.new(0, 1, 0))
	extentBB:SetMax(max, Vector3.new(0, 1, 0))
end

function Collisions_ClipZ(entityBB, extentBB)
	LocalCharacter.Base.zVel = 0
	local min = Vector3.new(
		entityBB.Start.X,
		entityBB.Start.Y,
		LocalCharacter.Base.zPos - entityBB.Size.Z/2

	)
	local max = Vector3.new(
		entityBB.Start.X,
		entityBB.Start.Y,
		LocalCharacter.Base.zPos + entityBB.Size.Z/2
	)
	entityBB:SetMin(min, Vector3.new(0, 0, 1))
	extentBB:SetMin(min, Vector3.new(0, 0, 1))
	
	entityBB:SetMax(max, Vector3.new(0, 0, 1))
	extentBB:SetMax(max, Vector3.new(0, 0, 1))
end



function Collisions_DidSlide(blockBB, finalBB, entityBB, extentBB)
	
	debug.profilebegin("didslide")
	local yDist = blockBB.End.Y - entityBB.Start.Y
	
	local size = entityBB.Size
	
	if( (yDist > 0) and (yDist <= (LocalCharacter.Physics.StepSize + 0.1)) ) then
		
		--if blockBB.CANNOT then return false end
		
		local blockBB_MinX = math.max(blockBB.Start.X, blockBB.End.X - size.X / 2)
		local blockBB_MaxX = math.min(blockBB.End.X, blockBB.Start.X + size.X / 2)
		local blockBB_MinZ = math.max(blockBB.Start.Z, blockBB.End.Z - size.Z / 2)
		local blockBB_MaxZ = math.min(blockBB.End.Z, blockBB.Start.Z + size.Z / 2)
		
		local min = Vector3.new(
			math.min(finalBB.Start.X, blockBB_MinX + COLLISIONS_ADJ),
			blockBB.End.Y + COLLISIONS_ADJ,
			math.min(finalBB.Start.Z, blockBB_MinZ + COLLISIONS_ADJ)
		)
		
		local max = Vector3.new(
			math.max(finalBB.End.X, blockBB_MaxX - COLLISIONS_ADJ),
			min.Y + size.Y,
			math.max(finalBB.End.Z, blockBB_MaxZ - COLLISIONS_ADJ)
		)
		
		local adjBB = AABB.New(min, max)
		
		if not Collisions_CanSlideThrough(adjBB) then debug.profileend() return false end
		
		LocalCharacter.Base.yPos = adjBB.Start.Y
		LocalCharacter.Physics.OnGround = true
		Collisions_ClipY(entityBB, extentBB)
		debug.profileend()
		return true
	end
	debug.profileend()
	return false
end

function Collisions_ClipXMin(blockBB, entityBB, extentBB, wasOn, finalBB)
	if not extentBB:Intersects(blockBB) then return end
	local size = entityBB.Size
	if (not wasOn) or (not Collisions_DidSlide(blockBB, finalBB, entityBB, extentBB)) then
		LocalCharacter.Base.xPos = blockBB.Start.X - size.X / 2 - COLLISIONS_ADJ
		Collisions_ClipX(entityBB, extentBB)
		LocalCharacter.Physics.HitXMin = true
	end
end

function Collisions_ClipXMax(blockBB, entityBB, extentBB, wasOn, finalBB)
	if not extentBB:Intersects(blockBB) then return end
	local size = entityBB.Size
	if (not wasOn) or (not Collisions_DidSlide(blockBB, finalBB, entityBB, extentBB)) then
		LocalCharacter.Base.xPos = blockBB.End.X + size.X / 2 + COLLISIONS_ADJ
		Collisions_ClipX(entityBB, extentBB)
		LocalCharacter.Physics.HitXMax = true
	end
end

function Collisions_ClipYMin(blockBB, entityBB, extentBB, wasOn, finalBB)
	if not extentBB:Intersects(blockBB) then return end
	LocalCharacter.Base.yPos = blockBB.Start.Y - entityBB.Size.Y - COLLISIONS_ADJ
	Collisions_ClipY(entityBB, extentBB)
	LocalCharacter.Physics.HitYMin = true
end

function Collisions_ClipYMax(blockBB, entityBB, extentBB, wasOn, finalBB)
	if not extentBB:Intersects(blockBB) then return end
	LocalCharacter.Base.yPos = blockBB.End.Y + COLLISIONS_ADJ
	LocalCharacter.Physics.OnGround = true
	Collisions_ClipY(entityBB, extentBB)
	LocalCharacter.Physics.HitYMax = true
end

function Collisions_ClipZMin(blockBB, entityBB, extentBB, wasOn, finalBB)
	if not extentBB:Intersects(blockBB) then return end
	local size = entityBB.Size
	if (not wasOn) or (not Collisions_DidSlide(blockBB, finalBB, entityBB, extentBB)) then
		LocalCharacter.Base.zPos = blockBB.Start.Z - size.Z / 2 - COLLISIONS_ADJ
		Collisions_ClipZ(entityBB, extentBB)
		LocalCharacter.Physics.HitZMin = true
	end
end

function Collisions_ClipZMax(blockBB, entityBB, extentBB, wasOn, finalBB)
	if not extentBB:Intersects(blockBB) then return end
	local size = entityBB.Size
	if (not wasOn) or (not Collisions_DidSlide(blockBB, finalBB, entityBB, extentBB)) then
		LocalCharacter.Base.zPos = blockBB.End.Z + size.Z / 2 + COLLISIONS_ADJ
		Collisions_ClipZ(entityBB, extentBB)
		LocalCharacter.Physics.HitZMax = true
	end
end




function Collisions_CollideWithReachableBlocks(count, entityBB, extentBB)
	
	debug.profilebegin("collidewithreachable")
	
	local p = LocalCharacter.Physics
	local wasOn = p.OnGround
	p.OnGround = false
	p.HitXMin = false;	p.HitYMin = false;	p.HitZMin = false;
	p.HitXMax = false;	p.HitYMax = false;	p.HitZMax = false;
	
	
	for i=1, count do
		-- Unpack the block and coordinate data
		local state = SearcherStates[i]
		
		
		
--		local bPos = Vector3.new(
--			bit32.rshift(state.X, 3),
--			bit32.rshift(state.Y, 4),
--			bit32.rshift(state.Z, 3)
--		)
--		
--		local block = bit32.bor(
--			bit32.band(state.X, 0x7),
--			bit32.lshift(bit32.band(state.Y, 0xF), 3),
--			bit32.lshift(bit32.band(state.Z, 0x7), 7)
--		)
		
		local bPos = Vector3.new(
			state.X,
			state.Y,
			state.Z
		)
		
		local block = state.Block
		
		local blockBB = blockToBB(block, bPos)

		local vel = Vector3.new(LocalCharacter.Base.xVel, LocalCharacter.Base.yVel, LocalCharacter.Base.zVel)
		
		
		-- Recheck time to collide with block (as colliding with blocks modifies this)
		local tx, ty, tz = Searcher_CalcTime(vel, entityBB, blockBB)
		-- tx > 1.0 ty > 1.0 tz > 1.0 check
		if tx > 1.0 or ty > 1.0 or tz > 1.0 then
		end
		
		-- Calculate the location of the entity when it collides with this block
		local v = Vector3.new(vel.X * tx, vel.Y * ty, vel.Z * tz)
		
		--Inlined AABB_Offset
		local finalBB = AABB.New(entityBB.Start + v, entityBB.End + v)
		
		

		
		if (not p.HitYMin) then
			-- if we have hit the bottom of a block, we need to change the axis we test first
			if(finalBB.Start.Y + COLLISIONS_ADJ >= blockBB.End.Y) then
				Collisions_ClipYMax(blockBB, entityBB, extentBB)
			elseif (finalBB.End.Y - COLLISIONS_ADJ <= blockBB.Start.Y) then
				Collisions_ClipYMin(blockBB, entityBB, extentBB)
			elseif (finalBB.Start.X + COLLISIONS_ADJ >= blockBB.End.X) then
				Collisions_ClipXMax(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif (finalBB.End.X - COLLISIONS_ADJ <= blockBB.Start.X) then
				Collisions_ClipXMin(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif (finalBB.Start.Z + COLLISIONS_ADJ >= blockBB.End.Z) then
				Collisions_ClipZMax(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif (finalBB.End.Z - COLLISIONS_ADJ <= blockBB.Start.Z) then
				Collisions_ClipZMin(blockBB, entityBB, extentBB, wasOn, finalBB)
			end			
		else
			-- if flying or falling, test the horizontal axes first
			if (finalBB.Start.X + COLLISIONS_ADJ >= blockBB.End.X) then
				Collisions_ClipXMax(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif (finalBB.End.X - COLLISIONS_ADJ <= blockBB.Start.X) then
				Collisions_ClipXMin(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif (finalBB.Start.Z + COLLISIONS_ADJ >= blockBB.End.Z) then
				Collisions_ClipZMax(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif (finalBB.End.Z - COLLISIONS_ADJ <= blockBB.Start.Z) then
				Collisions_ClipZMin(blockBB, entityBB, extentBB, wasOn, finalBB)
			elseif(finalBB.Start.Y + COLLISIONS_ADJ >= blockBB.End.Y) then
				Collisions_ClipYMax(blockBB, entityBB, extentBB)
			elseif (finalBB.End.Y - COLLISIONS_ADJ <= blockBB.Start.Y) then
				Collisions_ClipYMin(blockBB, entityBB, extentBB)
			end
		end
		
		
	end
	
	debug.profileend()
end

function Collisions_MoveAndWallSlide()
	-- maybe move this?
	PhysicsComp_DoEntityPush()

	if LocalCharacter.Base.xVel == 0 and LocalCharacter.Base.yVel == 0 and LocalCharacter.Base.zVel == 0 then return end
	local entitybb = GetEntityBB()
	local extentbb = AABB.New()
	local count = Searcher_FindReachableBlocks(entitybb, extentbb)
	Collisions_CollideWithReachableBlocks(count, entitybb, extentbb)
	

end

function Entity_TouchesAny(bounds, func)
	debug.profilebegin("touchesany")
	local bbMin = IVec3_Floor(bounds.Start)
	local bbMax = IVec3_Ceil(bounds.End)
	
	bbMin = Vector3.new(
		math.max(bbMin.X, 0),
		math.max(bbMin.Y, 0),
		math.max(bbMin.Z, 0)
	)
		
	bbMax = Vector3.new(
		math.min(bbMax.X, world.size.X),
		math.min(bbMax.Y, world.size.Y),
		math.min(bbMax.Z, world.size.Z)
	)
	
	for y=bbMin.Y, bbMax.Y-1 do
		for z=bbMin.Z, bbMax.Z-1 do
			for x=bbMin.X, bbMax.X-1 do
				local block = world.get(x, y, z)
				local blockbb = blockToBB(block, Vector3.new(x,y,z))
				if blockbb:Intersects(bounds) then
					if func(block) then
						debug.profileend()
						return true
					end
				end
			end
		end
	end
	debug.profileend()
	return false
end

function Entity_IsWater(block)
	return (block == blk.FLOWING_WATER) or (block == blk.STATIONARY_WATER)
end
function Entity_TouchesAnyWater()
	local bounds = GetEntityBB()
	bounds:SetMin(bounds.Start + Vector3.new(0.25/16, 0/16, 0.25/16))
	bounds:SetMax(bounds.End + Vector3.new(0.25/16, 0/16, 0.25/16))
	return Entity_TouchesAny(bounds, Entity_IsWater)
end

function Entity_IsLava(block)
	return (block == blk.FLOWING_LAVA) or (block == blk.STATIONARY_LAVA)
end
function Entity_TouchesAnyLava()
	local bounds = GetEntityBB()
	bounds:SetMin(bounds.Start + Vector3.new(0.25/16, 0/16, 0.25/16))
	bounds:SetMax(bounds.End + Vector3.new(0.25/16, 0/16, 0.25/16))
	return Entity_TouchesAny(bounds, Entity_IsLava)
end

function PhysicsComp_TouchesLiquid(block)
	return Entity_IsLava(block) or Entity_IsWater(block)
end


function PhysicsComp_DoEntityPush()
	local entity = LocalCharacter.Base
	local entity_aabb = GetEntityBB()
	for other, exists in pairs(Entity.getallentities()) do
		if exists and other.api.pushes() and other.id > 0 then
			local other_aabb = other.api.get_aabb(other.position)
			
			local yIntersects = 
						entity.yPos <= (other.position.Y + other_aabb.Size.Y) and
						other.position.y <= (entity.yPos + entity_aabb.Size.Y)
			
			if yIntersects then
				local dir = Vector3.new(other.position.X - entity.xPos, 0, other.position.Z - entity.zPos)
				local dist = dir.X * dir.X + dir.Z * dir.Z
				
				if (dist < 0.002) or (dist > 1.0) then else
					dir = dir.Unit
					local pushStrength = (1 - dist) / 32
					dir = dir * pushStrength
					entity.xVel = entity.xVel - dir.X
					entity.zVel = entity.zVel - dir.Z
				end
			end
		end
	end
end




return function(AABB1, LocalCharacter1, world1, Blocks1)
	AABB, LocalCharacter, world, Blocks = AABB1, LocalCharacter1, world1, Blocks1
	
	return {
		Collisions_MoveAndWallSlide, IVec3_Ceil, IVec3_Floor, SolidBlock, blockToBB, GetEntityBB, Entity_TouchesAnyLava, Entity_TouchesAnyWater, Entity_TouchesAny, PhysicsComp_TouchesLiquid, IsSolid
	}
end