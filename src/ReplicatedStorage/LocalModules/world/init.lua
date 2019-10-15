local PoolByteArray = require(game.ReplicatedStorage.PoolByteArray)

local blocks = require(game.ReplicatedStorage.LocalModules.Blocks)
local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)

local loading = Instance.new("ScreenGui")
loading.Name = "Loading"
loading.IgnoreGuiInset = true
loading.ResetOnSpawn = false

local loadingImg = Instance.new("ImageLabel")
loadingImg.Size = UDim2.new(1, 0, 1, 0)
loadingImg.Image = blocks[blk.BLOCK_DIRT].Texture
loadingImg.ScaleType = Enum.ScaleType.Tile
loadingImg.TileSize = UDim2.new(0, 64, 0, 64)
loadingImg.ImageColor3 = Color3.new(0.35, 0.35, 0.35)
loadingImg.Parent = loading

local loadingBarG = Instance.new("Frame")
loadingBarG.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
loadingBarG.AnchorPoint = Vector2.new(0.5, 0.5)
loadingBarG.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingBarG.Size = UDim2.new(0, 200, 0, 4)
loadingBarG.BorderSizePixel = 0
loadingBarG.Parent = loadingImg

local loadingBarC = Instance.new("Frame")
loadingBarC.BackgroundColor3 = Color3.fromRGB(128, 255, 128)
loadingBarC.Size = UDim2.new(0, 0, 1, 0)
loadingBarC.BorderSizePixel = 0
loadingBarC.Parent = loadingBarG


local loading_api = require(script.LoadingSet)
loading_api.SetParent(loadingImg)

local ent = require(game.ReplicatedStorage.LocalModules.Entity)
local blockgen = require(game.ReplicatedStorage.LocalModules.BlockGen)

loading.Parent = game.Players.LocalPlayer.PlayerGui
loading_api.SetText("Connecting...")
local world = {}

game.ReplicatedStorage.Remote.ChangeBlock.OnClientEvent:Connect(function(x, y, z, new)
	world.serverbuild(x, y, z, new)--world.array:set(packed, new)
end)

function world.pack(x, y, z)
	return x + y*world.size.X + z*world.size.X*world.size.Y
end

function world.f(x, y, z)
	return math.floor(x+0.5), math.floor(y+0.5), math.floor(z+0.5)
end

function world.exists(x, y, z)
	local x, y, z = world.f(x, y, z)
	if not world.size then return end
	return (x>=0) and (y>=0) and (z>=0) and (x<world.size.X) and (y<world.size.Y) and (z<world.size.Z)
end

function world.get(x, y, z)
	local x, y, z = world.f(x, y, z)
	
	return world.array:get(world.pack(x,y,z))
end
local renderer = require(script.Renderer)
local old_renderer

function init()
	
		if old_renderer then
			loading_api.SetText("Destroying previous world")
			old_renderer:destroy()
			
		end
		loading_api.SetText("INIT: Generating new renderer")
		print(world.size)
		local new_renderer = renderer.new(world.array, world.size)
		loading_api.SetText("Rendering World")
		new_renderer:render_entire_world(loading_api.SetText, loading_api.SetProgress)
		
		old_renderer = new_renderer
		
		
end

game.ReplicatedStorage.Remote.ReceiveWorldData.OnClientEvent:Connect(function(new, size)
	wait()
	loading.Enabled = true
	loading_api.SetText("Unpacking world array")
	world.array = PoolByteArray.new(new)
	world.size = size
	
	init()
	loading_api.SetText("Finishing")
	game.ReplicatedStorage.LocalEvents.WorldReset:Fire()
	loading.Enabled = false
end)


function world.canReplace(a)
	return (a == blk.BLOCK_AIR) or (a == blk.STATIONARY_LAVA) or (a == blk.STATIONARY_WATER) or (a == blk.FLOWING_WATER) or (a == blk.FLOWING_LAVA)
end

function world.canBreak(a)
	return (not world.canReplace(a)) and (a ~= blk.BLOCK_BEDROCK)
end

local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5
local Gas = 6

function world.block_ignored_on_ent_bbox_check(blk)
	return (blocks[blk].Solidity == Liquid) or (blocks[blk].Solidity == Plant)
end

function world.build(x, y, z, to)
	if x < 0 then return end
	if x >= world.size.X then return end
	if y < 0 then return end
	if y >= world.size.Y then return end
	if z < 0 then return end
	if z >= world.size.Z then return end
	if not old_renderer then return end
	local x, y, z = world.f(x, y, z)
	
	local blockbb = blockgen.ToBB(to, Vector3.new(x, y, z))
	
	
	
	local packed = world.pack(x,y,z)
	local old = world.array:get(packed)
	
	if (to ~= 0) and not world.canReplace(old) then return end
	
	if (to == 0) and not world.canBreak(old) then return end
	
	if (to ~= 0) and (not world.block_ignored_on_ent_bbox_check(to)) and ent.intersectsWithAny(blockbb) then return end
	
	world.array:set(packed, to)
	
	
	
	old_renderer:update(x, y, z, packed, old, to, true)
	
	game.ReplicatedStorage.Remote.ChangeBlock:FireServer(x, y, z, to)
	game.ReplicatedStorage.LocalEvents.HBAnim:Fire(1)
end

function world.serverbuild(x, y, z, to)
	if x < 0 then return end
	if x >= world.size.X then return end
	if y < 0 then return end
	if y >= world.size.Y then return end
	if z < 0 then return end
	if z >= world.size.Z then return end
	
	local x, y, z = world.f(x, y, z)
	local packed = world.pack(x,y,z)
	local old = world.array:get(packed)
	
	if old == to then return end
	
	world.array:set(packed, to)
	
	old_renderer:update(x, y, z, packed, old, to, true)
	
end




local Settings = require(game.ReplicatedStorage.LocalModules.Settings)

Settings.on_changed("render_dist", function(new)
	if old_renderer then
		old_renderer:set_render_distance(new)
		if old_renderer then
			loading_api.SetText("Destroying previous world")
			old_renderer:destroy()
		end
		loading_api.SetText("Generating new renderer")
		local new_renderer = renderer.new(world.array, world.size)
		loading_api.SetText("Rendering World")
		new_renderer:render_entire_world(loading_api.SetText, loading_api.SetProgress)
		
		old_renderer = new_renderer
	end
end)

return world