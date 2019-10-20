local r = {}

local BlockGen = require(game.ReplicatedStorage.LocalModules.BlockGen)
local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)
local Blocks = require(game.ReplicatedStorage.LocalModules.Blocks)
local AABB = require(game.ReplicatedStorage.LocalModules.AABB)


local reserves = {}

local this_renderer

function r:pack(x, y, z)
	local result = x + y*self.size.X + z*self.size.X*self.size.Y
	if result < 0 or result > (self.size.X*self.size.Y*self.size.Z)-1 then
		error("Out of bounds")
	end
	return result
end

function r:packpillar(x, z)
	return self:pack(x, 0, z)
end

function r:boundscheck(x, y, z)
	return (x < self.size.X) and (x >= 0) and (y < self.size.Y) and (y >= 0) and (z < self.size.Z) and (z >= 0)
end


local time_since_last_wait = tick()
local n = 0
function antifreezewait(origin)
	n = n + 1
	if(n > 100) then
		n = 0
		if tick() - time_since_last_wait >= 1/16 then
			if origin then
			--debug.profileend()
			end
			game:GetService("RunService").RenderStepped:wait()
			if origin then
			--debug.profilebegin(origin .. "_cont")
			end
			time_since_last_wait = tick()
			return true
		end
	end
end

local vinuse = false

function r:renderblock(x, y, z, pack, new_parent, bypass_visibles)
	--debug.profilebegin("renderblock")
	if self.destructed then return end
	local block = self.world:get(pack)
	
	if block ~= blk.BLOCK_AIR then
		
		local 	visibles = {}
		
		local visible = false
		
		if bypass_visibles then
			visibles = bypass_visibles
		else
			if ( self.vises_cache[pack] == nil ) then
				local coords = {
					{x+1, y, z},
					{x-1, y, z},
					{x, y+1, z},
					{x, y-1, z},
					{x, y, z+1},
					{x, y, z-1}
				}
						
				for k, v in pairs(coords) do
					if self:boundscheck(unpack(v)) then
						visibles[k] = BlockGen.isBlockTransparent(block, self.world:get(self:pack(unpack(v))))
					else
						visibles[k] = (v[2] > math.floor(self.size.Y/2)-3) and not (((block == blk.FLOWING_WATER) or (block == blk.STATIONARY_WATER)) and (v[2] < math.floor(self.size.Y/2)))
					end
				end
			else
				local visibles_pack = self.vises_cache[pack]
				
				if visibles_pack == 0 then 
					--debug.profileend()
					vinuse = false
					return
				end
				
				for i=1, 6 do
					visibles[i] = bit32.band(visibles_pack, bit32.lshift(1, i)) ~= 0
				end
				
			end
		end
		
		for k, v in pairs(visibles) do
			if v then
				visible = true
				break
			end
		end
		
		
		
		if visible then
			local waited = antifreezewait("renderblock")
			

			if not self.vises_cache[pack] then
				local prevs_pack = 0
				
				for i=1, 6 do
					if visibles[i] then
						prevs_pack = bit32.bor(prevs_pack, bit32.lshift(1, i))
					end
				end
				self.vises_cache[pack] = prevs_pack
			end

			local generated_block
			
			if BlockGen.CanRecycle(block) and (#reserves >= 1) then
				local thatpar = reserves[1]
				generated_block = BlockGen.RecycleBlock(block, visibles, false, Vector3.new(x, y, z), thatpar)
				table.remove(reserves, 1)
			else
				generated_block = BlockGen.CreateBlock(block, visibles, false, Vector3.new(x, y, z))
				generated_block.Parent = new_parent or self.wrld
			end
			
			

			self.parts[pack] = {generated_block, self.vises_cache[pack]}
			
			
			
			--debug.profileend()
			vinuse = false
			
			return true, waited
		else
			vinuse = false
			self.vises_cache[pack] = 0
		end
	end
	
	--debug.profileend()
end

function r:freeblock(par, blk)
	BlockGen.FreeBlock(par)
	if BlockGen.CanRecycle(blk) and par:IsA("Part") then
		par.CFrame = CFrame.new(-50000, -50000, -50000)
		table.insert(reserves, par)
	else
		
		par:Destroy()
		
	end
end


-- not used
function r:renderpillar(x, z)
	if self.destructed then return end
	if x >= self.size.X then return false end
	if z >= self.size.Z then return false end
	if x < 0 then return false end
	if z < 0 then return false end	
	if self.rendered[self:packpillar(x, z)] then return false end
	

	
	
	for y=0, self.size.Y-1 do
		
		self:renderblock(x, y, z, self:pack(x, y, z))
	end
	self.rendered[self:packpillar(x, z)] = true
	return true
end


function aabbdist(cx, cy, cz, dist)
	dist = dist + 4
	return AABB.New(
		Vector3.new(
				math.floor(cx-dist),
				math.floor(cy-dist),
				math.floor(cz-dist)
			) ,
		Vector3.new(
				math.ceil(cx+dist),
				math.ceil(cy+dist),
				math.ceil(cz+dist)
			)
	)
end

function r:render_around(nx, ny, nz, dist)
	--debug.profilebegin("render_around")
	local ox = self.OX
	local oy = self.OY
	local oz = self.OZ
	
	local odist = self.odist
	
	local old_around = aabbdist(ox, oy, oz, odist)
	old_around:Clamp(Vector3.new(0, 0, 0), self.size - Vector3.new(1,1,1))
	
	self.curr_around = aabbdist(nx, ny, nz, dist)
	self.curr_around:Clamp(Vector3.new(0, 0, 0), self.size - Vector3.new(1,1,1))
	
	local new_around = self.curr_around

	local parent_to = Instance.new("Folder")
	
	local function handle(x, y, z)
		if self.destructed then return false end
		local packed = self:pack(x, y, z)
		if not self.parts[packed] then
			if self:boundscheck(x, y, z) then
				local was_rendered, did_wait = self:renderblock(x, y, z, packed, parent_to)
				if did_wait then
					--debug.profilebegin("render_around_cont")
				end
			end
		end
		return true
	end
	
	new_around:WeirdIntUnintersectingFuncCall(old_around, handle, true)
	
	if self.destructed then return end
	if #parent_to:GetChildren() > 0 then
		parent_to.Parent = self.wrld
	else
		parent_to:Destroy()
	end
	
	--debug.profileend()
--	for x = self.curr_around.Start.X, self.curr_around.End.X do
--		for y = self.curr_around.Start.Y, self.curr_around.End.Y do
--			for z = self.curr_around.Start.Z, self.curr_around.End.Z do
--				if (self:boundscheck(x, y, z)) then
--					--if ((Vector3.new(x, y, z) - Vector3.new(nx, ny, nz)).Magnitude < dist) then
--						local packed = self:pack(x, y, z)
--						if not self.parts[packed] then
--							local was_rendered = self:renderblock(x, y, z)
--						end
--					--end
--				end
--			end
--		end
--	end
end

function r:derender_around(nx, ny, nz)
	--debug.profilebegin("derender_around")
	
	local ox = self.OX
	local oy = self.OY
	local oz = self.OZ
	
	local odist = self.odist
	
	local old_around = aabbdist(ox, oy, oz, odist)
	old_around:Clamp(Vector3.new(0, 0, 0), self.size - Vector3.new(1,1,1))
	local new_around = self.curr_around
	
	local function handle(x, y, z)
		if self.destructed then return false end
		
		local packed = self:pack(x, y, z)
		local blk = self.world:get(packed)
		if self.parts[packed] then
			antifreezewait("derender")
			self:freeblock(self.parts[packed][1], blk)
			self.parts[packed] = nil
		end
		
		return true
	end
	
	old_around:WeirdIntUnintersectingFuncCall(new_around, handle)
	
	--debug.profileend()
--	for _, old_pack in pairs(self.old_rendered_around) do
--		if not self.curr_rendered_around_dict[old_pack] then
--			local this_part = self.parts[old_pack]
--			if this_part then
--				this_part[1]:Destroy()
--				n = n + 1
--				
--			end
--			h = h + 1
--			self.parts[old_pack] = nil
--		end
--	end
	
end

function r:render_spawn(statusText, statusProg)
	statusText("&bWelcome &ato &egame! &c-hax -fly -noclip &a+ophax")
	wait(0.1)
	spawn(function() self:render_bg() end)
end

local idle_render = 4

function r:render_bg()
		self.OX = 0
		self.OY = 0
		self.OZ = 0
		self.odist = 0
	while not self.destructed do
		local rendered = 0
		local center = workspace.CurrentCamera.CFrame.p
		local centerx = math.floor(center.X)
		local centery = math.floor(center.Y)
		local centerz = math.floor(center.Z)
		
		self:render_around(centerx, centery, centerz, self.max_render_distance)
		self:derender_around(centerx, centery, centerz)
		self.OX = centerx
		self.OY = centery
		self.OZ = centerz	
		self.odist = self.max_render_distance
		wait(1/20)
		
	end
end

function r:render_entire_world(statusText, statusProg)
	return self:render_spawn(statusText, statusProg)
end

function r:destroy()
	self.destructed = true
	for k, v in pairs(self.parts) do
		local par = v[1]
		local blk = self.world:get(k)
		self:freeblock(par, blk)
	end
	for k, v in pairs(reserves) do
		v:Destroy()
		if k % 100 == 0 then
			antifreezewait(false)
		end
	end
	self.wrld:Destroy()
	reserves = {}
end

function r:update_nearby(x, y, z, fromx, fromy, fromz, visidx, fromblk)
	local packed = self:pack(x, y, z)
	local old_p = self.parts[packed]
	
	self.vises_cache[packed] = nil
	
	local this_blk = self.world:get(packed)
	
	if this_blk == 0 then return end --air
	
	local visibles = {}
	local visible = false
	
	if not old_p then
		visibles = {false, false, false, false, false}
	else
		-- visibles will be the same
		local visibles_pack = old_p[2]
		
		for i=1, 6 do
			visibles[i] = bit32.band(visibles_pack, bit32.lshift(1, i)) ~= 0
		end
	end

	if not self.curr_around:Intersects(BlockGen.ToBB(this_blk, Vector3.new(x, y, z))) then
		return
	end	
	
	local new_vis = BlockGen.isBlockTransparent(this_blk, fromblk)
	local old_vis = visibles[visidx]
	
	visibles[visidx] = new_vis
	
	if old_vis ~= new_vis then
		-- something changed
		for k, v in pairs(visibles) do
			if v then
				visible = true; break
			end
		end
		if visible then
			-- update
			if old_p then
				-- update 1 face
				BlockGen.UpdateBlock(this_blk, old_p[1], visidx, new_vis)
			else
				-- generate entire block
				local wg = self:renderblock(x, y, z, packed, self.wrld, visibles)
			end
		else
			-- destroy
			if old_p then
				self:freeblock(old_p[1], this_blk)
			end
			self.parts[packed] = nil
		end
	end	
	
	if self.parts[packed] then
		local prevs_pack = 0
		for i=1, 6 do
			if visibles[i] then
				prevs_pack = prevs_pack + bit32.lshift(1, i)
			end
		end
		
		self.parts[packed] = {self.parts[packed][1], prevs_pack}
		self.vises_cache[packed] = prevs_pack
	end
	
end

	local SolidBlock = 1
	local Liquid = 2
	local Transparent = 3
	local TransparentInside = 4
	local Plant = 5
	local Gas = 6

function r:update(x, y, z, packed, old, now, build)
	if not self:boundscheck(x, y, z) then
		return
	end
	
	
	local old_p = self.parts[packed]
	if old_p and old_p[1] then
		local par = old_p[1]
		self:freeblock(par, old)
	end
	self.parts[packed] = nil
	self.vises_cache[packed] = nil
	
	if (not self.curr_around or not self.curr_around:Intersects(BlockGen.ToBB(now, Vector3.new(x, y, z))))  then
		
		-- update nearby
		local coords = {
			{x+1, y, z},
			{x-1, y, z},
			{x, y+1, z},
			{x, y-1, z},
			{x, y, z+1},
			{x, y, z-1}
		}
		local swap = {
			2, --x+1 , comes from x-1, idx 2
			1, --x-1, comes from x+1, idx 1
			4, --y+1, comes from y-1, idx 4
			3, --y-1, comes from y+1, idx 3
			6, --z+1, comes from z-1, idx 6
			5  --z-1, comes from z+1, idx 5
		}
		for k, v in pairs(coords) do
			if self:boundscheck(v[1], v[2], v[3]) then
				self:update_nearby(v[1], v[2], v[3], x, y, z, swap[k], now)
			end
		end
		return
	end
	
	
	
	if now ~= 0 then -- air check
		
--		local visible = false
--		local visibles = {}
		
		self:renderblock(x, y, z, packed, self.wrld)
		
--		if old_p and (Blocks[old].Solidity == Blocks[now].Solidity) and (Blocks[old].Solidity ~= Liquid) and (Blocks[old].Solidity ~= TransparentInside) then -- doesnt work with water
--			-- visibles will be the same
--			local visibles_pack = old_p[2]
--			
--			for i=1, 6 do
--				visibles[i] = bit32.band(visibles_pack, bit32.lshift(1, i)) ~= 0
--			end
--			visible = true
--		else
--			-- have to calc
--			local coords = {
--				{x+1, y, z},
--				{x-1, y, z},
--				{x, y+1, z},
--				{x, y-1, z},
--				{x, y, z+1},
--				{x, y, z-1}
--			}
--			
--			
--			for k, v in pairs(coords) do
--				if self:boundscheck(unpack(v)) then
--					visibles[k] = BlockGen.isBlockTransparent(now, self.world:get(self:pack(unpack(v))))
--				else
--					visibles[k] = v[2] > math.floor(self.size.Y/2)-3
--				end
--			end
--							
--			for k, v in pairs(visibles) do
--				if v then
--					visible = true
--					break
--				end
--			end
--		end
--		
--		if visible then
--			local generated_block = BlockGen.CreateBlock(now, visibles, false, Vector3.new(x, y, z))
--			
--			if(generated_block:IsA("Part")) then
--				generated_block.Parent = workspace
--			elseif(generated_block:IsA("Model")) then
--				--if generated_block.Name == "planes" then
--					generated_block.Parent = workspace
--				--end
--			end
--			
--			local prevs_pack = 0
--			
--			for i=1, 6 do
--				if visibles[i] then
--					prevs_pack = prevs_pack + bit32.lshift(1, i)
--				end
--			end
--			
--			self.parts[self:pack(x, y, z)] = {generated_block, prevs_pack}
--		end
		
	end
	-- update nearby
	local coords = {
		{x+1, y, z},
		{x-1, y, z},
		{x, y+1, z},
		{x, y-1, z},
		{x, y, z+1},
		{x, y, z-1}
	}
	local swap = {
		2, --x+1 , comes from x-1, idx 2
		1, --x-1, comes from x+1, idx 1
		4, --y+1, comes from y-1, idx 4
		3, --y-1, comes from y+1, idx 3
		6, --z+1, comes from z-1, idx 6
		5  --z-1, comes from z+1, idx 5
	}
	for k, v in pairs(coords) do
		if self:boundscheck(v[1], v[2], v[3]) then
			self:update_nearby(v[1], v[2], v[3], x, y, z, swap[k], now)
		end
	end
	

	
	--eyecandy
	if build and now == 0 and old ~= 0 then
		local particle = require(game.ReplicatedStorage.LocalModules.Particle)
		local bd = Blocks[old]
		if bd.Solidity == SolidBlock or bd.Solidity == Transparent or bd.Solidity == TransparentInside then
			for xp=-2, 1 do
				for yp=-2, 1 do
					for zp=-2, 1 do
						local p = particle.new(xp + 0.5, yp + 0.5, zp + 0.5, old, Vector3.new(x,y,z))
					end
				end
			end
		elseif bd.Solidity == Plant then
			for xp=-0, 1 do
				for yp=-0, 1 do
					for zp=-0, 1 do
						local p = particle.new(xp - 0.5, yp - 0.5, zp - 0.5, old, Vector3.new(x,y,z), true)
					end
				end
			end
		end
	end
end



local max_render_distance = 2048

function r:set_render_distance(to)
	to = math.floor(to)
	if to % 2 ~= 0 then
		to = to + 1
	end
	max_render_distance = to
	self.max_render_distance = to
	
	local EnvRenderer = require(game.ReplicatedStorage.LocalModules.EnvRender)
	EnvRenderer.SetMaxFogDistance(to)
end

function r.new(PBArray, dimensions)
	local renderer = {}
	setmetatable(renderer, {__index = r})
	renderer.world = PBArray
	renderer.size = dimensions
	renderer.parts = {}
	renderer.vises_cache = {}
	renderer.rendered = {}
	renderer.destructed = false
	
	
	renderer.wrld = Instance.new("Folder", workspace)
	
	renderer.wrld.Name = "Renderer"
	
	if this_renderer then
		this_renderer:Destroy()
	end
	
	
	this_renderer = renderer.wrld
	
	r:set_render_distance(max_render_distance)
	
	return renderer
end


return r