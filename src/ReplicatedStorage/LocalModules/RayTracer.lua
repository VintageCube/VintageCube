local world = require(game.ReplicatedStorage.LocalModules.world)
local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)
local blocks = require(game.ReplicatedStorage.LocalModules.Blocks)
local bgen = require(game.ReplicatedStorage.LocalModules.BlockGen)
local env = require(game.ReplicatedStorage.LocalModules.EnvRender)
local Settings = require(game.ReplicatedStorage.LocalModules.Settings)

local IVec3 = {}
function IVec3.new(x, y, z)
	return Vector3int16.new(x, y, z)
	--return Vector3int16.new(math.floor(x+0.5), math.floor(y+0.5), math.floor(z+0.5))
end


local RayTracer = {}

function RayTracer:Div(a, b)
	if math.abs(b) < 0.000001 then
		return math.huge
	end
	return a / b
end

function intbound(s, ds)
	if (ds < 0) then
		return intbound(-s, -ds)
	else
		s = mod(s, 1)
		return RayTracer.Div(nil, (1 - s),ds)
	end
end

function mod(value, modulus)
	return (value % modulus + modulus) % modulus
end

function RayTracer:SetVectors(origin, dir)
	
	origin = origin + Vector3.new(0.5, 0.5, 0.5)
	
	self.Origin = origin
	self.Dir = dir
	
	
	
	
	local t = 0
	local floor = math.floor
	local ix = floor(origin.X ) 
	local iy = floor(origin.Y ) 
	local iz = floor(origin.Z )
	
	local stepx = (dir.X > 0) and 1 or -1
	local stepy = (dir.Y > 0) and 1 or -1
	local stepz = (dir.Z > 0) and 1 or -1
	
	local txDelta = math.abs(1 / dir.X)
	local tyDelta = math.abs(1 / dir.Y)
	local tzDelta = math.abs(1 / dir.Z)
	
	local xdist = (stepx > 0) and (ix + 1 - origin.X) or (origin.X - ix)
	local ydist = (stepy > 0) and (iy + 1 - origin.Y) or (origin.Y - iy)
	local zdist = (stepz > 0) and (iz + 1 - origin.Z) or (origin.Z - iz)
	
	local txMax = txDelta * xdist
	local tyMax = tyDelta * ydist
	local tzMax = tzDelta * zdist
	
	local steppedIndex = -1
	
	
	self.X = ix
	self.Y = iy
	self.Z = iz
	
	self.step = Vector3.new(stepx, stepy, stepz)
	self.tMax = {X = txMax, Y = tyMax, Z = tzMax}
	self.tDelta = Vector3.new(txDelta, tyDelta, tzDelta)
end

function RayTracer:Step()
	if (self.tMax.X < self.tMax.Y) and (self.tMax.X < self.tMax.Z) then
		self.X = self.X + self.step.X
		
		self.Face = (self.step.X > 0) and Enum.NormalId.Left or Enum.NormalId.Right
		
		self.tMax.X = self.tMax.X + self.tDelta.X
	elseif self.tMax.Y < self.tMax.Z then
		self.Y = self.Y + self.step.Y
		
		self.Face = (self.step.Y > 0) and Enum.NormalId.Bottom or Enum.NormalId.Top
		
		self.tMax.Y = self.tMax.Y + self.tDelta.Y
	else
		self.Z = self.Z + self.step.Z
		
		self.Face = (self.step.Z > 0) and Enum.NormalId.Front or Enum.NormalId.Back
		
		self.tMax.Z = self.tMax.Z + self.tDelta.Z
	end
end

function RayTracer.new()
	local tracer = {
		X = 0,
		Y = 0,
		Z = 0,
		
		Origin = Vector3.new(),
		Dir = Vector3.new(),
		
		Min = Vector3.new(), --[[ block data ]]--
		Max = Vector3.new(),
		Block = 0,
		
		step = Vector3.new(),
		
		tMax = Vector3.new(),
		tDelta = Vector3.new(),
		
		Face = 0
	}
	setmetatable(tracer, {__index = RayTracer})
	
	return tracer
end


local PICKING_BORDER = blk.BLOCK_BEDROCK

function Picking_GetInside(x, y, z)
	if world.exists(x, 1, z) then
		if y >= world.size.Y then return blk.BLOCK_AIR end
		if y >= 0 then return world.get(x, y, z) end
	end
	
	local sides = env.SidesBlock ~= blk.BLOCK_AIR
	local height = env.SidesHeight; if height < 1 then height = 1 end
	return (sides and y < height) and PICKING_BORDER or blk.BLOCK_AIR
end

function Picking_GetOutside(x, y, z, origin)
	if not world.exists(x, 1, z) then return blk.BLOCK_AIR end
	local sides = env.SidesBlock ~= blk.BLOCK_AIR
	
	if y >= world.size.Y then return blk.BLOCK_AIR end
	if (sides and y == -1 and origin.Y > 0) then return PICKING_BORDER end
	if (sides and y == 0 and origin.Y < 0) then return PICKING_BORDER end
	local height = env.SidesHeight; if height < 1 then height = 1 end
	
	if (sides and x == 0				and y >= 0 and y < height and origin.X < 0) then			 return PICKING_BORDER end
	if (sides and z == 0				and y >= 0 and y < height and origin.Z < 0) then			 return PICKING_BORDER end
	if (sides and x == world.size.X 	and y >= 0 and y < height and origin.X >= world.size.X) then return PICKING_BORDER end
	if (sides and z == world.size.Z		and y >= 0 and y < height and origin.Z >= world.size.Z) then return PICKING_BORDER end
	if y >= 0 then return world.get(x, y, z) end
	return blk.BLOCK_AIR
end



function Picking_RayTrace(origin, dir, reach, pos, intersect)
	local tracer = RayTracer.new()
	tracer:SetVectors(origin, dir)
	
	local pOrigin = IVec3.new(origin.X, origin.Y, origin.Z)
	
	local reachSq = reach * reach
	
	local v, minBB, maxBB
	
	local dxMin, dxMax, dx
	local dyMin, dyMax, dy
	local dzMin, dzMax, dz
	
	local x, y, z
	
	local insideMap = world.exists(pOrigin.X, pOrigin.Y, pOrigin.Z)
	
	for i=1, 25000 do
		
		x = (tracer.X)
		y = (tracer.Y)
		z = (tracer.Z)
		v = Vector3.new(x, y, z)
		
		
		
		tracer.Block = insideMap and Picking_GetInside(x, y, z) or Picking_GetOutside(x, y, z, pOrigin)
		local bb = bgen.ToBB(tracer.Block, v)
		minBB = bb.Start
		maxBB = bb.End
		-- ???
		
		dxMin = math.abs(origin.X - minBB.X); dxMax = math.abs(origin.X - maxBB.X);
		dyMin = math.abs(origin.Y - minBB.Y); dyMax = math.abs(origin.Y - maxBB.Y);
		dzMin = math.abs(origin.Z - minBB.Z); dzMax = math.abs(origin.Z - maxBB.Z);
		dx = math.min(dxMin, dxMax); dy = math.min(dyMin, dyMax); dz = math.min(dzMin, dzMax)
		if ((dx * dx + dy * dy + dz * dz) > reachSq) then return false end
		
		tracer.Min = minBB; tracer.Max = maxBB
		if intersect(tracer, pos) then
			return true
		end
		tracer:Step()
	end
	
	error("Something went wrong, did over 25,000 iterations in Picking_RayTrace()")
	return false
end

function Intersection_RayIntersectsBox(origin, dir, min, max)
	local tmin, tmax, tymin, tymax, tzmin, tzmax
	
	origin = origin - Vector3.new(0.5, 0.5, 0.5)
	
	local invDirX = 1.0 / dir.X
	if invDirX >= 0 then
		tmin = (min.X - origin.X) * invDirX
		tmax = (max.X - origin.X) * invDirX
	else
		tmin = (max.X - origin.X) * invDirX
		tmax = (min.X - origin.X) * invDirX
	end
	
	local invDirY = 1.0 / dir.Y
	if invDirY >= 0 then
		tymin = (min.Y - origin.Y) * invDirY
		tymax = (max.Y - origin.Y) * invDirY
	else
		tymin = (max.Y - origin.Y) * invDirY
		tymax = (min.Y - origin.Y) * invDirY
	end
	
	if (tmin > tymax or tymin > tmax) then return false end
	if (tymin > tmin) then tmin = tymin end
	if (tymax < tmax) then tmax = tymax end
	
	local invDirZ = 1.0 / dir.Z
	if invDirZ >= 0 then
		tzmin = (min.Z - origin.Z) * invDirZ
		tzmax = (max.Z - origin.Z) * invDirZ
	else
		tzmin = (max.Z - origin.Z) * invDirZ
		tzmax = (min.Z - origin.Z) * invDirZ
	end
	
	if (tmin > tzmax or tzmin > tmax) then return false end
	if (tzmin > tmin) then tmin = tzmin end
	if (tzmax < tmax) then tmax = tzmax end
	
	return tmin >= 0.0, tmin, tmax
end

function NewPickedPos()
	local PickedPos = {
		Min = Vector3.new(),
		Max = Vector3.new(),
		Intersect = Vector3.new(),
		BlockPos = Vector3int16.new(),
		TranslatedPos = Vector3int16.new(),
		Valid = false,
		Closest = Enum.NormalId,
		Block = 0
	}
	
	return PickedPos
end

local pickedPos_dist
function PickedPos_TestAxis(pos, dAxis, fAxis)
	dAxis = math.abs(dAxis)
	if (dAxis >= pickedPos_dist) then return end
	
	pickedPos_dist = dAxis
	pos.Closest = fAxis
end


local additives = {
	[Enum.NormalId.Left] 	= Vector3int16.new(-1, 0, 0),
	[Enum.NormalId.Right] 	= Vector3int16.new( 1, 0, 0),
	[Enum.NormalId.Bottom] 	= Vector3int16.new( 0,-1, 0),
	[Enum.NormalId.Top] 	= Vector3int16.new( 0, 1, 0),
	[Enum.NormalId.Front] 	= Vector3int16.new( 0, 0,-1),
	[Enum.NormalId.Back] 	= Vector3int16.new( 0, 0, 1)
}

function PickedPos_SetAsValid(pos, tracer, intersect)
	pos.BlockPos = Vector3int16.new(tracer.X, tracer.Y, tracer.Z)
	pos.TranslatedPos = pos.BlockPos
	
	pos.Valid = true
	pos.Block = tracer.Block
	pos.Intersect = intersect
	pos.Min = tracer.Min; pos.Max = tracer.Max
	
	pickedPos_dist = math.huge
	
	
	pos.Closest = tracer.Face
	if tracer.Face ~= 0 then
		pos.TranslatedPos = pos.TranslatedPos + additives[pos.Closest]
	end
end


function PickedPos_SetAsInvalid(pos)
	pos.BlockPos = Vector3int16.new(-1, -1, -1)
	pos.TranslatedPos = pos.BlockPos
	
	pos.Valid = false
	pos.Block = blk.BLOCK_AIR
	pos.Closest = 0
end

local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5
local Gas = 6

function Picking_CanPick(block)
	if blocks[block].Solidity == Gas then return false end
	if blocks[block].Solidity == Plant then return true end
	return blocks[block].Solidity ~= Liquid
end

function Picking_ClipBlock(tracer, pos)
	
	if not Picking_CanPick(tracer.Block) then return false end
	
	local is, t0, t1 = Intersection_RayIntersectsBox(tracer.Origin, tracer.Dir, tracer.Min, tracer.Max)
	
	if not is then return false end
	
	local scaledDir = tracer.Dir * t0
	local intersect = tracer.Origin + scaledDir
	
	local lenSq = scaledDir.X * scaledDir.X + scaledDir.Y * scaledDir.Y + scaledDir.Z * scaledDir.Z
	local reach = Settings.get("ReachDistance")
	
	if(lenSq <= reach * reach) then
		PickedPos_SetAsValid(pos, tracer, intersect)
	else
		PickedPos_SetAsInvalid(pos)
	end
	return true
end

function Picking_CalculatePickedBlock(origin, dir, reach, pos)
	if not Picking_RayTrace(origin, dir, reach, pos, Picking_ClipBlock) then
		PickedPos_SetAsInvalid(pos)
	end
end

return {
	RayTracer = RayTracer,
	Picking_CalculatePickedBlock = Picking_CalculatePickedBlock,
	NewPickedPos = NewPickedPos
}
