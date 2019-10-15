--[[
	The block generator, used by the world renderer and inventory
]]


local Blocks = require(script.Parent.Blocks)

local terrain = require(script.Parent.terrain)

local BlockGen = {}


-- these variables could be moved to another Enum module
local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5

local NoPhysics = -1
local Falling = 1
local Flowing = 2


-- the variables that will be used for keeping track of water/lava animation
local ax = 0
local ay = 0

local bx = 0
local by = 0




-- tables for keeping track of lava/water animated textures (probably would be better to make this more flexible and not just lava/water)
local OffsetLavaAnims = {}
local OffsetWaterAnims = {}


function BlockGen.isBlockTransparent(thisBlock, tgtBlock)
	-- used by renderer to determine if a certain face is visible
	-- for example, if tgtBlock is glass and thisBlock is stone, it will return true
	-- but if thisBlock is glass and tgtBlock is glass, it will return false as glass does not appear inside glass
	-- similarly, water and water will return false
	-- however, leaves appear inside of leaves so leaves + leaves will return true
	
	local thisBlockInfo = Blocks[thisBlock]
	local thatBlockInfo = Blocks[tgtBlock]

	if not thisBlockInfo then
		error("no block info " .. tostring(thisBlock))
	end
	
	if not thatBlockInfo then
		error("no block info " .. tostring(tgtBlock))
	end

	return (tgtBlock == 0) or
		((thisBlock ~= tgtBlock) and thatBlockInfo.Solidity == TransparentInside) or
		(thatBlockInfo.Solidity == Transparent) or
		(thatBlockInfo.Solidity == Plant) or
		(thatBlockInfo.Solidity == Liquid and (thisBlock ~= tgtBlock)) or
		((thatBlockInfo.BlockHeight) and (thatBlockInfo.BlockHeight ~= 1))
end



function BlockGen.isPlant(blk)
	local thisBlockInfo = Blocks[blk]
	return thisBlockInfo.Solidity == Plant
end


function BlockGen.CreatePlant(BlockData, thisBlock, InViewportFrame, pos)
	-- generates plant
	
	local Model = Instance.new("Model")
	Model.Name = "Plant"

	local blkCenter = Instance.new("Part")
	blkCenter.Size = Vector3.new(1, 1, 1)
	blkCenter.Anchored = true
	blkCenter.Transparency = 1
	blkCenter.CanCollide = false
	blkCenter.Name = "BlkCenter"
	blkCenter.CFrame = CFrame.new(pos)
	blkCenter.Parent = Model
	Model.PrimaryPart = blkCenter
	


	local blkPlane = Instance.new("Part")
	blkPlane.Size = Vector3.new(1, 1, 0)
	blkPlane.Anchored = true
	blkPlane.Transparency = 1
	blkPlane.CanCollide = false
	blkPlane.Material = "Fabric"

	for k, v in pairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local tex = Instance.new("Decal")
		tex.Face = v
		tex.Texture = BlockData.Texture
		tex.Parent = blkPlane

	end

	blkPlane.CFrame = CFrame.new(pos.X, pos.Y+(blkPlane.Size.X - 1)/2, pos.Z) * CFrame.Angles(0, math.rad(45), 0)

--	local blkPlane2 = blkPlane:Clone()

	local blkPlane2 = Instance.new("Part")
	blkPlane2.Size = Vector3.new(1, 1, 0)
	blkPlane2.Anchored = true
	blkPlane2.Transparency = 1
	blkPlane2.CanCollide = false
	blkPlane2.Material = "Fabric"

	for k, v in pairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local tex = Instance.new("Decal")
		tex.Face = v
		tex.Texture = BlockData.Texture
		tex.Parent = blkPlane2
	end

	blkPlane2.CFrame = CFrame.new(pos.X, pos.Y+(blkPlane2.Size.X - 1)/2, pos.Z) * CFrame.Angles(0, math.rad(-45), 0)

	if BlockData.EmitLight then
		local Light = Instance.new("PointLight")
		Light.Brightness = BlockData.EmitLight.Brightness or 1
		Light.Range = (BlockData.EmitLight.Range or 1) * 1
		Light.Color = BlockData.EmitLight.Color or Color3.new(1,1,1)
		Light.Enabled = true
		Light.Parent = blkPlane
	end

	blkPlane.Parent = Model
	blkPlane2.Parent = Model
	
	return Model
end


-- gets the texture for a specific face of a block. will return argument fail if there is no texture
function getTexture(face, data, fail)
	if data.AnimatedWater then
		return terrain.WaterAnim, terrain.WaterAnimX, terrain.WaterAnimY
	end
	if data.AnimatedLava then
		return terrain.LavaAnim, terrain.WaterAnimX, terrain.WaterAnimY
	end
	if data.TopBottom and (face == Enum.NormalId.Top or face == Enum.NormalId.Bottom) then
		return data.TopBottom
	elseif data.Top and face == Enum.NormalId.Top then
		return data.Top
	elseif data.Bottom and face == Enum.NormalId.Bottom then
		return data.Bottom
	elseif data.Left and face == Enum.NormalId.Left then
		return data.Left
	elseif data.Right and face == Enum.NormalId.Right then
		return data.Right
	elseif data.Front and face == Enum.NormalId.Front then
		return data.Front
	elseif data.Back and face == Enum.NormalId.Back then
		return data.Back
	elseif data.Sides and not(face == Enum.NormalId.Top or face == Enum.NormalId.Bottom) then
		return data.Sides
	elseif data.Texture then
		return data.Texture
	else
		return fail
	end
end


-- color definitions for fake lighting
local topcol = 1
local frontcol = 1/(143/86)
local sidecol = 1/(143/115)
local btmcol = 1/(143/76)--1/(143/43)

local brightmultipliers = {
	Color3.new(sidecol, sidecol, sidecol),
	Color3.new(sidecol, sidecol, sidecol),
	Color3.new(topcol, topcol, topcol),
	Color3.new(btmcol, btmcol, btmcol),
	Color3.new(frontcol, frontcol, frontcol),
	Color3.new(frontcol, frontcol, frontcol)
}


-- the faces for texture generation
local faces = {
	Enum.NormalId.Right,
	Enum.NormalId.Left,
	Enum.NormalId.Top,
	Enum.NormalId.Bottom,
	Enum.NormalId.Back,
	Enum.NormalId.Front
}

-- creates block with height (slabs need this)
function BlockGen.CreateWHeight(BlockData, thisBlock, InViewportFrame, pos)

	local Model = Instance.new("Model")
	Model.Name = "BlkHeight"

	local blkCenter = Instance.new("Part")
	blkCenter.Size = Vector3.new(1, 1, 1)
	blkCenter.Anchored = true
	blkCenter.Transparency = 1
	blkCenter.CanCollide = false
	blkCenter.Name = "BlkCenter"
	blkCenter.Parent = Model
	blkCenter.CFrame = CFrame.new(pos)
	Model.PrimaryPart = blkCenter

	local blkCut = Instance.new("Part")
	blkCut.Size = Vector3.new(1, 1 * BlockData.BlockHeight, 1)
	blkCut.Anchored = true
	blkCut.Name = "Cut"
	blkCut.Transparency = 0
	blkCut.CanCollide = true
	blkCut.Material = "Fabric"

	blkCut.CFrame = CFrame.new(pos.X, pos.Y-(1)*(1-(BlockData.BlockHeight))/2, pos.Z)



	local faces = {
		Enum.NormalId.Right,
		Enum.NormalId.Left,
		Enum.NormalId.Top,
		Enum.NormalId.Bottom,
		Enum.NormalId.Back,
		Enum.NormalId.Front
	}
	
	local Visibles = {true, true, true, true, true, true}




	for a, b in pairs(faces) do
		if Visibles[a] then
			local d = Instance.new("Texture")
			local terr, xs, ys = getTexture(b, BlockData)
			d.StudsPerTileU = xs or 1
			d.StudsPerTileV = ys or 1
			d.Texture = terr
			if not BlockData.FullBright then
				d.Color3 = brightmultipliers[a]
			end
			d.Face = b
			d.Parent = blkCut

		end
	end

	if BlockData.EmitLight then
		local Light = Instance.new("PointLight")
		Light.Brightness = BlockData.EmitLight.Brightness or 1
		Light.Range = (BlockData.EmitLight.Range or 1) * 1
		Light.Color = BlockData.EmitLight.Color or Color3.new(1,1,1)
		Light.Enabled = true
		Light.Parent = blkCenter
	end


	blkCut.Parent = Model
	
	return Model
end


BlockGen.GetTexture = getTexture





-- for use with renderer when a block nearby is updated
function BlockGen.UpdateBlock(thisBlock, part, visidx, isvis)
	if BlockGen.isPlant(thisBlock) then return end
	
	local dThisBlock = Blocks[thisBlock]
	
	if not isvis then
		-- destroy tex
		for k, v in ipairs(part:GetChildren()) do
			if v:IsA("Decal") and v.Face == faces[visidx] then
				v:Destroy()
				OffsetLavaAnims[v] = nil
				OffsetWaterAnims[v] = nil
			end
		end
		-- done
	else
		-- create new tex
		local d = Instance.new("Texture")
		local terr, xs, ys = getTexture(faces[visidx], dThisBlock)
		d.StudsPerTileU = xs or 1
		d.StudsPerTileV = ys or 1
		d.Texture = terr
		d.Face = faces[visidx]
		if not dThisBlock.FullBright then
			d.Color3 = brightmultipliers[visidx]
		end
		d.Parent = part
		-- done
	end
end


-- creates a new block
function BlockGen.CreateBlock(thisBlock, Visibles, InViewportFrame, pos)
	Visibles = Visibles or {true, true, true, true, true, true}
	local dThisBlock = Blocks[thisBlock]

	if BlockGen.isPlant(thisBlock) then
		return BlockGen.CreatePlant(dThisBlock, thisBlock, InViewportFrame, pos)
	end

	if (dThisBlock.BlockHeight) and (dThisBlock.BlockHeight ~= 1) then
		return BlockGen.CreateWHeight(dThisBlock, thisBlock, InViewportFrame, pos)
	end
	
	local ret
	do
	
		local blk = Instance.new("Part")
		blk.Size = Vector3.new(1, 1, 1)
		blk.Anchored = true
		blk.CFrame = CFrame.new(pos)
		blk.Material = "Fabric"
		blk.Transparency = BlockGen.isBlockTransparent(0, thisBlock) and 1 or 0
		blk.Color = Color3.new(0,0,0)
	
		--blk.Name = "Block"
	
	
		
		
		if dThisBlock.Solidity == Liquid then
			blk.CFrame = blk.CFrame + Vector3.new(0, -0.1, 0)
		end
	
	
	
	
	
	
	
		for a, b in pairs(faces) do
			if Visibles[a] then
				local d = Instance.new("Texture")
				local terr, xs, ys = getTexture(b, dThisBlock)
				d.StudsPerTileU = xs or 1
				d.StudsPerTileV = ys or 1
				d.Texture = terr
				
				d.Face = b
				
				if not dThisBlock.FullBright then
					d.Color3 = brightmultipliers[a]
				end
				
				d.Parent = blk
				
				if dThisBlock.AnimatedLava then
					OffsetLavaAnims[d] = true
					local arr = {}
					arr[d] = true
					animate_arr(arr, ax, ay, terrain.LavaAnimX, terrain.LavaAnimY)
				elseif dThisBlock.AnimatedWater then
					OffsetWaterAnims[d] = true
					local arr = {}
					arr[d] = true
					animate_arr(arr, bx, by, terrain.WaterAnimX, terrain.WaterAnimY)
				end
	
			end
		end
		
		
	
		
		if dThisBlock.EmitLight then
			local Light = Instance.new("PointLight")
			Light.Brightness = dThisBlock.EmitLight.Brightness or 1
			Light.Range = (dThisBlock.EmitLight.Range or 1)
			Light.Color = dThisBlock.EmitLight.Color or Color3.new(1,1,1)
			Light.Enabled = true
			Light.Parent = blk
		end
		
		ret = blk
	end

	return ret

end


-- frees a block to allow for destroying it or reusing it later
function BlockGen.FreeBlock(part)
	for k, v in ipairs(part:GetChildren()) do
		if v:IsA("Decal") then
			OffsetLavaAnims[v] = nil
			OffsetWaterAnims[v] = nil
		end
		if v:IsA("Texture") then
			v.OffsetStudsU = 0
			v.OffsetStudsV = 0
		end
	end
end


-- for use to turn a face into an index that we can use with fake lighting table or other things
local facesReverse = {
	[Enum.NormalId.Right] = 1,
	[Enum.NormalId.Left] = 2,
	[Enum.NormalId.Top] = 3,
	[Enum.NormalId.Bottom] = 4,
	[Enum.NormalId.Back] = 5,
	[Enum.NormalId.Front] = 6
}

local ign = {} -- defined here to avoid redefining it every time a block is generated
local i = 0


-- reuses a previously generated block to avoid having to destroy and generate parts from new all over again for better performance
function BlockGen.RecycleBlock(thisBlock, Visibles, InViewportFrame, pos, part)
	part.CFrame = CFrame.new(pos)
	part.Transparency = BlockGen.isBlockTransparent(0, thisBlock) and 1 or 0
	
	local dThisBlock = Blocks[thisBlock]
	
	local has_bm = false
	
	i = i + 1
	local thisi = i
	
	for k, v in pairs(part:GetChildren()) do
		
		if v:IsA("Decal") then
			local a = facesReverse[v.Face]
			if Visibles[a] then
				local terr, xs, ys = getTexture(faces[a], dThisBlock)
				v.StudsPerTileU = xs or 1
				v.StudsPerTileV = ys or 1
				v.Texture = terr
				
				v.Color3 = dThisBlock.FullBright and Color3.new(1,1,1) or brightmultipliers[a]
				ign[a] = thisi
				
				if dThisBlock.AnimatedLava then
					OffsetLavaAnims[v] = true
					local arr = {}
					arr[v] = true
					animate_arr(arr, ax, ay, terrain.LavaAnimX, terrain.LavaAnimY)
				elseif dThisBlock.AnimatedWater then
					OffsetWaterAnims[v] = true
					local arr = {}
					arr[v] = true
					animate_arr(arr, bx, by, terrain.WaterAnimX, terrain.WaterAnimY)
				end
			else
				v:Destroy()
			end
		end
	end
	
	if dThisBlock.Solidity == Liquid then
		part.CFrame = part.CFrame + Vector3.new(0, -0.1, 0)
	else
		if has_bm then
			has_bm:Destroy()
		end
	end
	
	for a, b in pairs(faces) do
		if Visibles[a] and (ign[a] ~= thisi) then
			local d = Instance.new("Texture")
			local terr, xs, ys = getTexture(b, dThisBlock)
			d.StudsPerTileU = xs or 1
			d.StudsPerTileV = ys or 1
			d.Texture = terr
	
			d.Face = b
				
			if not dThisBlock.FullBright then
				d.Color3 = brightmultipliers[a]
			end
			if dThisBlock.AnimatedLava then
				OffsetLavaAnims[d] = true
				local arr = {}
				arr[d] = true
				animate_arr(arr, ax, ay, terrain.LavaAnimX, terrain.LavaAnimY)
			elseif dThisBlock.AnimatedWater then
				OffsetWaterAnims[d] = true
				local arr = {}
				arr[d] = true
				animate_arr(arr, bx, by, terrain.WaterAnimX, terrain.WaterAnimY)
			end
			d.Parent = part
		end
	end
	
	return part
end

-- reusing slabs or plants does not work currently. they are rare so we just ignore them
function BlockGen.CanRecycle(block)
	local dThisBlock = Blocks[block]
	if BlockGen.isPlant(block) or dThisBlock.BlockHeight then
		return false
	end
	
	return true
end


-- sets texture offsets for water/lava animation
function animate_arr(tbl, x, y, mx, my)
	for tex, active in pairs(tbl) do
		if active and tex and tex.Parent then
			tex.OffsetStudsU = x * tex.StudsPerTileU/mx
			tex.OffsetStudsV = y * tex.StudsPerTileV/my
		end
	end
end

--water/lava animation loop
spawn(function()

	while wait(1/20) do
		ax = (ax + 1) % terrain.LavaAnimX
		if ax == 0 then
			ay = (ay + 1) % terrain.LavaAnimY
		end
		if(ay + 1) % terrain.LavaAnimY == 0 and (ax > ((terrain.LavaAnimX-1) - terrain.LavaAnimSkip)) then
			ay = 0
			ax = 0
		end
		
		bx = (bx + 1) % terrain.WaterAnimX
		if bx == 0 then
			by = (by + 1) % terrain.WaterAnimY
		end
		if(by + 1) % terrain.WaterAnimY == 0 and (bx > ((terrain.WaterAnimX-1) - terrain.WaterAnimSkip)) then
			by = 0
			bx = 0
		end
		
		if terrain.AnimatedWater then
			animate_arr(OffsetWaterAnims, bx, by, terrain.WaterAnimX, terrain.WaterAnimY)
		end
		
		if terrain.AnimtedLava then
			animate_arr(OffsetLavaAnims, ax, ay, terrain.LavaAnimX, terrain.LavaAnimY)
		end
	end
end)


local AABB = require(game.ReplicatedStorage.LocalModules.AABB)

-- creates an AABB from a blockId and offset
function BlockGen.ToBB(blockId, off)
	local blkdata = Blocks[blockId]
	if blkdata.BlockHeight then
		return AABB.New(Vector3.new(-0.5,-0.5,-0.5) + off, Vector3.new(0.5,blkdata.BlockHeight-0.5,0.5) + off)
	end
	if blkdata.HitSize then
		local width = blkdata.HitSize * Vector3.new(1, 0, 1)
		local height = blkdata.HitSize * Vector3.new(0, 1, 0)
		return AABB.New(Vector3.new(0, -0.5, 0) - width/2 + off, height + Vector3.new(0, -0.5, 0) + width/2 + off)
	end
	local ee = AABB.New(Vector3.new(-0.5,-0.5,-0.5) + off, Vector3.new(0.5,0.5,0.5) + off)
	return ee
end


return BlockGen
