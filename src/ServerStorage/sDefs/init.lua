
local module = {
	WorldSizeX = 0;
	WorldSizeY = 0;
	WorldSizeZ = 0;
	
}

local PoolByteArray = require(game.ReplicatedStorage.PoolByteArray)
module.WorldArray = nil

local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)

function module.pack(x, y, z)
	return x + y*module.WorldSizeX + z*module.WorldSizeX*module.WorldSizeY
end

function module.GetTotalSize()
	local Size = {x = module.WorldSizeX, y = module.WorldSizeY, z=module.WorldSizeZ, waterLevel = math.floor(module.WorldSizeY/2)}
	return Size
end

local ERR_BLK = blk.BLOCK_AIR
function module.GetAbsoluteBlock(x, y, z)
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	if x >= module.WorldSizeX then return ERR_BLK end
	if y >= module.WorldSizeY then return ERR_BLK end
	if z >= module.WorldSizeZ then return ERR_BLK end
	if x < 0 then return ERR_BLK end
	if y < 0 then return ERR_BLK end
	if z < 0 then return ERR_BLK end
	return module.WorldArray:get(module.pack(x, y, z))
end

function module.SetAbsoluteBlock(x, y, z, newBlock)
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	if x >= module.WorldSizeX then return ERR_BLK end
	if y >= module.WorldSizeY then return ERR_BLK end
	if z >= module.WorldSizeZ then return ERR_BLK end
	if x < 0 then return ERR_BLK end
	if y < 0 then return ERR_BLK end
	if z < 0 then return ERR_BLK end
	return module.WorldArray:set(module.pack(x, y, z), newBlock)
end

local initiated = false

local off = 0
local generator = require(script.NotchyGen)

function module.init(x, y, z, generate, render)
	module.WorldSizeX = x
	module.WorldSizeY = y
	module.WorldSizeZ = z
	
	module.WorldArray = PoolByteArray.new()
	module.WorldArray:resize(x*y*z)
	
	if generate then
		
		generator(module.WorldArray, Vector3.new(x, y, z), off)
	end
	
	off = off + 10
	
	initiated = true
	
	game.ReplicatedStorage.Remote.ReceiveWorldData:FireAllClients(module.WorldArray.data, Vector3.new(module.WorldSizeX, module.WorldSizeY, module.WorldSizeZ))
end

game.Players.PlayerAdded:Connect(function(ply)
	--while not initiated do wait() end
	if initiated then
		game.ReplicatedStorage.Remote.ReceiveWorldData:FireClient(ply, module.WorldArray.data, Vector3.new(module.WorldSizeX, module.WorldSizeY, module.WorldSizeZ))
	end
end)



-- events

game.ReplicatedStorage.Remote.GetSpawn.OnServerInvoke = function(ply)
	while not initiated do wait() end
	return Vector3.new(module.WorldSizeX, module.WorldSizeY*2, module.WorldSizeZ)/2
end

local update_funcs = {}

game.ReplicatedStorage.Remote.ChangeBlock.OnServerEvent:Connect(function(ply, x, y, z, new)
	module.SetAbsoluteBlock(x, y, z, new)
	game.ReplicatedStorage.Remote.ChangeBlock:FireAllClients(x, y, z, new)
	
	for k, v in pairs(update_funcs) do
		v(x, y, z)
	end
end)

function module.SetAbsoluteBlockAndSend(x, y, z, new)
	module.SetAbsoluteBlock(x, y, z, new)
	game.ReplicatedStorage.Remote.ChangeBlock:FireAllClients(x, y, z, new)
end

function module.BindToUpdate(func)
	table.insert(update_funcs, func)
end

--
--game.ReplicatedStorage.Remote.GetWorld.OnServerInvoke = function(ply)
--	while not initiated do wait() end
--	return module.WorldArray.data
--end
--
--game.ReplicatedStorage.Remote.GetWorldData.OnServerInvoke = function(ply)
--	while not initiated do wait() end
--	return Vector3.new(module.WorldSizeX, module.WorldSizeY, module.WorldSizeZ)
--end

return module
