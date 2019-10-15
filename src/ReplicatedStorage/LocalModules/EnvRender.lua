--[[
	Renders the local environment (sky, clouds, world border, fog, etc)
]]

local world = require(game.ReplicatedStorage.LocalModules.world)
local Blocks = require(game.ReplicatedStorage.LocalModules.Blocks)
local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)


-- get block that is inside eye
function get_eye_blk()
	local v3 = workspace.CurrentCamera.CFrame.p
	if not world.exists(v3.X, v3.Y, v3.Z) then
		return v3.Y > math.floor(world.size.Y/2)-3 and blk.BLOCK_AIR or blk.BLOCK_STONE
	end
	return world.get(v3.X, v3.Y, v3.Z)
end


local maxdist = 600

local DefaultFogCol = Color3.fromRGB(225, 240, 255)

function get_fog_density(eyeblk)
	if eyeblk == blk.FLOWING_WATER or eyeblk == blk.STATIONARY_WATER then
		return 0.1*3*2
	end
	if eyeblk == blk.FLOWING_LAVA or eyeblk == blk.STATIONARY_LAVA then
		return 1.8/1.5
	end
	
	return 0.005
end

-- get color for color shader
function get_c_shader(eyeblk)
	local colWater = Color3.fromRGB(114, 188, 197)
	local colLava = Color3.fromRGB(255, 169, 82)
	
	if eyeblk == blk.FLOWING_WATER or eyeblk == blk.STATIONARY_WATER then
		return colWater
	end
	if eyeblk == blk.FLOWING_LAVA or eyeblk == blk.STATIONARY_LAVA then
		return colLava
	end
	
	return Color3.new(1,1,1)
end

function get_fog_clr(eyeblk)
	local colWater = Color3.fromRGB(5, 5, 51)
	local colLava = Color3.fromRGB(153, 25, 0)
	
	if eyeblk == blk.FLOWING_WATER or eyeblk == blk.STATIONARY_WATER then
		return colWater
	end
	if eyeblk == blk.FLOWING_LAVA or eyeblk == blk.STATIONARY_LAVA then
		return colLava
	end
	
	return DefaultFogCol
end

local ballP,ceilingPrimary 


local shader

function update_all()
	local eyeblk = get_eye_blk()
	game.Lighting.FogColor = get_fog_clr(eyeblk)
	
	shader.TintColor = get_c_shader(eyeblk)
	
	local fd = 1/get_fog_density(eyeblk) * 3
	game.Lighting.FogStart = math.clamp(fd, 0, maxdist)/3
	game.Lighting.FogEnd = math.clamp(fd, 0, maxdist)
	local e = workspace.CurrentCamera.CFrame.p
	ballP.CFrame = CFrame.new(e.X, e.Y, e.Z, -1, 0, 0, 0, -1, 0, 0, 0, -1)
	ceilingPrimary.CFrame = CFrame.new(e.X, math.max(e.Y+8, world.size.Y+4), e.Z)
	
	
end



local trash = {}

function init()
	
	-- oh god
	
		for k, v in pairs(trash) do
			v:Destroy()
		end
		
		
		local BorderSize = 256
		
		local WorldBorder = Instance.new("Model")
		
		local wbVisPart = Instance.new("Part",WorldBorder)
		local wbInvisWall = Instance.new("Part",WorldBorder)
		
		local wbWater = Instance.new("Part",WorldBorder)
		
		wbVisPart.Anchored = true
		wbVisPart.Material = "Fabric"
		wbWater.Anchored = true
		wbWater.Material = "Fabric"
		
		wbInvisWall.Anchored = true
		
		wbVisPart.Size = Vector3.new(1, 1, 1)
		wbWater.Size = Vector3.new(1, 1, 1)
		wbVisPart.CFrame = CFrame.new(0, 0, 0)
		wbWater.CFrame = CFrame.new(0, 0, 0)
		wbInvisWall.Size = Vector3.new(1, 512, 1)
		
		wbWater.Name = "wbWater"
		
		wbWater.Transparency = 1
		wbVisPart.Transparency = 0
		
							local faces = {
								Enum.NormalId.Right,
								Enum.NormalId.Left,
								Enum.NormalId.Top,
								Enum.NormalId.Bottom,
								Enum.NormalId.Back,
								Enum.NormalId.Front
							}
		for _, currFace in pairs(faces) do
			local tx = Instance.new("Texture")
			tx.Face = currFace
			--tx.Texture = "rbxassetid://965624256"
			tx.Texture = Blocks[blk.BLOCK_BEDROCK].Texture
			--tx.Texture = "rbxassetid://3106176269"
			tx.StudsPerTileU = 1
			tx.StudsPerTileV = 1
			tx.Parent = wbVisPart
		end
		
		for _, currFace in pairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
			local tx2 = Instance.new("Texture")
			tx2.Face = currFace
			--tx2.Texture = "rbxassetid://546857098"
			tx2.Texture = Blocks[blk.FLOWING_WATER].Texture
			tx2.StudsPerTileU = 1
			tx2.StudsPerTileV = 1
			tx2.Parent = wbWater
		end
		
		wbInvisWall.Transparency = 1
		
		WorldBorder.PrimaryPart = wbVisPart
		
		local function md(n)
			if n < 0 then return -n	end
			return n
		end
		
		local length = 2048
		local height = world.size.Y/2
		local ypos = world.size.Y/4 + 1/2 - 2
		
		local CentralX = (world.size.X)/2 + 1/2
		local CentralZ = (world.size.Z)/2 + 1/2
		
		local WidthX = world.size.X
		local WidthZ = world.size.Z	
			
		local HHHx = world.size.X+1/2
		local HHHz = world.size.Z+1/2
		
		-- wtf
		local function GenBor(v)
			local wb = WorldBorder:Clone()
			
			for _, E in pairs(wb:GetChildren()) do
				E.Size = E.Size * ( Vector3.new(0, height, 0)
							+ Vector3.new(WidthX, 0, 0):lerp(Vector3.new(length, 0, 0), md(v.X))
							+ Vector3.new(0, 0, WidthZ):lerp(Vector3.new(0, 0, length), md(v.Z)) )
			end
			
			local tgtPos = Vector3.new(0, ypos - 1, 0)
						
						+ Vector3.new(CentralX, 0, 0):lerp(( Vector3.new(HHHx, 0, 0):lerp(Vector3.new(0.5, 0, 0), v.X/2+0.5) ), md(v.X))
						+ Vector3.new(0, 0, CentralZ):lerp(( Vector3.new(0, 0, HHHz):lerp(Vector3.new(0, 0, 0.5), v.Z/2+0.5) ), md(v.Z))
						
						+ (wb.PrimaryPart.Size/2 * -v)
						
						+ Vector3.new(-1, 0, -1)
			
			wb:SetPrimaryPartCFrame(CFrame.new(tgtPos))
			wb.wbWater.Size = wb.wbWater.Size * Vector3.new(1, 0, 1)
			wb.wbWater.CFrame = CFrame.new(tgtPos + Vector3.new(0, height/2 + 1 + 1 - 0.1, 0))
			wb.Parent = workspace
			table.insert(trash, wb)
		end
		
		
		
	
		GenBor(Vector3.new(1, 0, 0))
		GenBor(Vector3.new(-1, 0, 0))
		GenBor(Vector3.new(0, 0, 1))
		GenBor(Vector3.new(0, 0, -1))
		
		GenBor(Vector3.new(1, 0, 1))
		GenBor(Vector3.new(-1, 0, 1))
		GenBor(Vector3.new(1, 0, -1))
		GenBor(Vector3.new(-1, 0, -1))
	
		
		local bottomBorder = wbVisPart:Clone()
		bottomBorder.Size = Vector3.new(world.size.X, BorderSize, world.size.Z)
		bottomBorder.CFrame = CFrame.new(world.size.X/2 - 1/2, -BorderSize/2 - 1/2, world.size.Z/2 - 1/2)
		
		bottomBorder.Parent = workspace
		table.insert(trash, bottomBorder)		
		ballP = Instance.new("Part")
		ballP.Shape = "Ball"
		ballP.Anchored = true
		ballP.Size = Vector3.new(2048,2048,2048)
		ballP.CanCollide = false
		ballP.CastShadow = false
		ballP.Color = Color3.fromRGB(225, 240, 255)
		ballP.Parent = workspace
		ballP.CFrame = CFrame.new(world.size.x/2, 0, world.size.z/2, -1, 0, 0, 0, -1, 0, 0, 0, -1)
		
		table.insert(trash, ballP)
		
		
		
		
		ceilingPrimary = Instance.new("Part")
		ceilingPrimary.Anchored = true
		ceilingPrimary.Name = "Ceiling"
		ceilingPrimary.CFrame = CFrame.new(0, world.size.Y+4, 0)
		ceilingPrimary.CanCollide = false
		ceilingPrimary.Transparency = 1
		
		table.insert(trash, ceilingPrimary)
				
		local ceiling = Instance.new("BoxHandleAdornment")
		ceiling.Size = Vector3.new(65536, 0, 65536)
		ceiling.Color3 = Color3.fromRGB(153, 204, 255)
		ceiling.Adornee = ceilingPrimary
		ceiling.Parent = ceilingPrimary
		
		ceilingPrimary.Parent = workspace
				
		
		--local Clouds = game.ReplicatedStorage.Clouds:Clone()
		
		local cloudPrimary = Instance.new("Part")
		
		cloudPrimary.Transparency = 1
		cloudPrimary.Anchored = true
		cloudPrimary.CanCollide = false
		cloudPrimary.Massless = true
		
		table.insert(trash, cloudPrimary)
		
		local cloudSize = 25
		local cloudMax = 82
		
		for x=1, cloudMax do
			for y=1, cloudMax do
				if math.noise(x/2, y/2, 0.5) > 0 then
					local bxh = Instance.new("BoxHandleAdornment")
					bxh.Adornee = cloudPrimary
					bxh.CFrame = CFrame.new((x-cloudMax/2)*cloudSize, 0, (y-cloudMax/2)*cloudSize)
					bxh.Size = Vector3.new(cloudSize, 0, cloudSize)
					bxh.Color3 = Color3.new(1,1,1)
					bxh.Parent = cloudPrimary
				end
			end
		end
		
		cloudPrimary.Parent = workspace
		
		
		spawn(function()
			local n = -512
			while cloudPrimary and cloudPrimary.Parent do
				
					cloudPrimary.CFrame = CFrame.new(n, world.size.Y+2, 0)
					n = n + 0.1/4
					if n >= 1024 then
						n = -1024
					end
					game:GetService("RunService").RenderStepped:wait()
			end
		end)
		
		shader = Instance.new("ColorCorrectionEffect", game.Lighting)
		table.insert(trash, shader)
end

spawn(function()
	local i = 0
	game.ReplicatedStorage.LocalEvents.WorldReset.Event:Connect(function()
		init()
		i = i + 1
		local n = i
		while game:GetService("RunService").RenderStepped:Wait() do
			update_all()
			if n ~= i then break end
		end
	end)
end)

local EnvRenderer = {
	SidesBlock = blk.BLOCK_AIR,
	SidesHeight = world.size.Y/2
}

function EnvRenderer.SetMaxFogDistance(dist)
	maxdist = dist
end



return EnvRenderer