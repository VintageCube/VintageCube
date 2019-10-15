local RayTracer = require(game.ReplicatedStorage.LocalModules.RayTracer)
local Char = require(game.ReplicatedStorage.LocalModules.Characterize)

local Raycast = {}

Raycast.Items = {}

Raycast.Table = {}

local HaveToReset = false

function Raycast.ResetTable()
	
end

function Raycast.Register(hitbox)
	
end

function Raycast.Deregister(desc)
	
end

--local NormalToID = {
--	[Vector3.new(0, 1, 0)] = Enum.NormalId.Top,
--	[Vector3.new(0, -1, 0)] = Enum.NormalId.Bottom,
--	[Vector3.new(1, 0, 0)] = Enum.NormalId.Right,
--	[Vector3.new(-1, 0, 0)] = Enum.NormalId.Left,
--	[Vector3.new(0, 0, 1)] = Enum.NormalId.Back,
--	[Vector3.new(0, 0, -1)] = Enum.NormalId.Front
--}

function Vec3_GetDirVector(yaw, pitch)
	local x = -math.cos(pitch) * -math.sin(yaw)
	local y = -math.sin(pitch)
	local z = math.cos(pitch) * math.cos(yaw)
	return Vector3.new(x, y, z)
end

function Raycast.CastMouse(reachDistance)
	local origin = Char.LocalCharacter.Base.eyePos
	local dir = Vec3_GetDirVector(math.rad(Char.CameraRotation[1].Y + 180), math.rad(-Char.CameraRotation[1].X))
	local pickedPos = RayTracer.NewPickedPos()
	RayTracer.Picking_CalculatePickedBlock(origin, dir, reachDistance, pickedPos)
	
	return pickedPos

end

return Raycast