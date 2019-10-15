local Blocks = require(game.ReplicatedStorage.LocalModules.Blocks)
local world = require(game.ReplicatedStorage.LocalModules.world)

local blockgen = require(game.ReplicatedStorage.LocalModules.BlockGen)

local Particle = {}

local all_particles = {}


local COLLISIONS_ADJ = 0.1

local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5
local Gas = 6

function Particle:tick(dt)
	
	
	
	self.Velocity = self.Velocity * Vector3.new(0.98, 0.98, 0.98)
	self.Velocity = self.Velocity + Vector3.new(0, -0.01, 0) * 60 * dt/1.6
	
	-- collisions
	
	local thisRPos = Vector3.new(world.f(self.Position.X, self.Position.Y, self.Position.Z)) + self.Velocity
	
	if world.exists(thisRPos.X, thisRPos.Y, thisRPos.Z) then
		local thatBlk = world.get(thisRPos.X, thisRPos.Y, thisRPos.Z)
		if thatBlk ~= 0 then
			local thatBlkData = Blocks[thatBlk]
			if (thatBlkData.Solidity ~= Liquid) and (thatBlkData.Solidity ~= Plant) and (thatBlkData ~= Gas) then
				local blockBB = blockgen.ToBB(thatBlk, thisRPos)
				if blockBB:HasPoint(self.Position) then
					self:Destroy()
					return
				end
			end
		end
	end
	local thisRPos = Vector3.new(world.f(self.Position.X, self.Position.Y, self.Position.Z))
	
	local adds = {
		Vector3.new(COLLISIONS_ADJ + (self.Velocity.X > 0 and self.Velocity.X or 0), 0, 0),
		Vector3.new(-COLLISIONS_ADJ + (self.Velocity.X < 0 and self.Velocity.X or 0), 0, 0),
		Vector3.new(0, COLLISIONS_ADJ + (self.Velocity.Y > 0 and self.Velocity.Y or 0), 0),
		Vector3.new(0, -COLLISIONS_ADJ + (self.Velocity.Y < 0 and self.Velocity.Y or 0), 0),
		Vector3.new(0, 0, COLLISIONS_ADJ + (self.Velocity.Z > 0 and self.Velocity.Z or 0)),
		Vector3.new(0, 0, -COLLISIONS_ADJ + (self.Velocity.Z < 0 and self.Velocity.Z or 0))
	}
	

	
	local hitxmin = false
	local hitxmax = false
	local hitymin = false
	local hitymax = false
	local hitzmin = false
	local hitzmax = false	
	
	for k, v in pairs(adds) do
		if v.X == 0 and v.Y == 0 and v.Z == 0 then 
			
		else
			local newPos = self.Position + v
			local thatRPos = Vector3.new(world.f(newPos.X, newPos.Y, newPos.Z))

			if world.exists(thatRPos.X, thatRPos.Y, thatRPos.Z) then
				local thatBlk = world.get(thatRPos.X, thatRPos.Y, thatRPos.Z)
				if thatBlk ~= 0 then
					local thatBlkData = Blocks[thatBlk]
					if (thatBlkData.Solidity ~= Liquid) and (thatBlkData.Solidity ~= Plant) and (thatBlkData ~= Gas) then
						local blockBB = blockgen.ToBB(thatBlk, thatRPos)
						if blockBB:HasPoint(newPos) then
							if v.X < 0 then
								hitxmin = true
							elseif v.X > 0 then
								hitxmax = true
							elseif v.Y < 0 then
								hitymin = true
							elseif v.Y > 0 then
								hitymax = true
							elseif v.Z < 0 then
								hitzmin = true
							elseif v.Z > 0 then
								hitzmax = true
							end
						end
					end
				end
			elseif (not world.exists(thatRPos.X, 1, thatRPos.Z)) or thatRPos.Y < 0 then
				if v.X < 0 then
					hitxmin = true
				elseif v.X > 0 then
					hitxmax = true
				elseif v.Y < 0 then
					hitymin = true
				elseif v.Y > 0 then
					hitymax = true
				elseif v.Z < 0 then
					hitzmin = true
				elseif v.Z > 0 then
					hitzmax = true
				end
			end
		end
	end
	
	if hitxmin and self.Velocity.X < 0 then
		self.Velocity = self.Velocity * Vector3.new(0,1,1)
	end
	if hitxmax and self.Velocity.X > 0 then
		self.Velocity = self.Velocity * Vector3.new(0,1,1)
	end
	if hitymin and self.Velocity.Y < 0 then
		self.Velocity = self.Velocity * Vector3.new(1,0,1)/2
	end
	if hitymax and self.Velocity.Y > 0 then
		self.Velocity = self.Velocity * Vector3.new(1,0,1)
	end
	if hitzmin and self.Velocity.Z < 0 then
		self.Velocity = self.Velocity * Vector3.new(1,1,0)
	end
	if hitzmax and self.Velocity.Z > 0 then
		self.Velocity = self.Velocity * Vector3.new(1,1,0)
	end
	
	
	-- end
	
	self.Position = self.Position + self.Velocity
	
	self.Part.CFrame = CFrame.new(self.Position)
	
	
	if (self.Start) < tick() - self.Lifetime then
		self:Destroy()
	end
	
end

function Particle:init()
	if #all_particles > 600 then
		all_particles[1]:Destroy()
		table.remove(all_particles, 1)
	end
--	spawn(function()
--		while self.Active do
--			self:tick()
--			game:GetService("RunService").RenderStepped:wait()
--		end
--	end)
end

function Particle:Destroy()
	self.Active = false
	if self.Part then
		self.Part:Destroy()
	end
end

local texSize = 16

function Particle.new(x, y, z, blk, blkv3, plant)
	local p = {}
	setmetatable(p, {__index = Particle})
	p.Velocity = Vector3.new(
		x/4 + (math.random() * 0.4 - 0.2),
		y/2 + (math.random() * 0.4 - 0.2),
		z/4 + (math.random() * 0.4 - 0.2)
	) / 10
	p.Lifetime = 0.3 + (math.random() * 1.2)
	p.Start = tick()
	p.Active = true
	p.OriginBlock = blk
	p.Position = blkv3 + Vector3.new(x, y, z)/5
	
	p.Part = Instance.new("Part")
	p.Part.Transparency = 1
	p.Part.Size = Vector3.new(0,0,0)
	p.Part.CanCollide = false
	p.Part.Anchored = true
	p.Part.CFrame = CFrame.new(p.Position)
	p.Part.Parent = workspace
	
	p.UI = Instance.new("BillboardGui")
	p.Img = Instance.new("ImageLabel")
	p.Img.ImageColor3 = Color3.new(0.7, 0.7, 0.7)
	p.UI.Adornee = p.Part
	local size = ((math.random(4) + 8) * 0.015625) / 1.2 --why is size wrong
	p.UI.Size = UDim2.new(size, 0, size, 0)
	p.UI.ClipsDescendants = true
	p.UI.LightInfluence = 1
	p.Img.Size = UDim2.new(texSize/4,0,texSize/4,0)
	local px = -math.random(16-4)/4
	local py = -math.random(16-4)/4
	if plant then
		p.Img.Position = UDim2.new(-math.clamp(-px, 16/2/4-0.5, 16/2/4+0.5), 0, -math.clamp(-py, 16/2/4-0.5, 16/2/4+0.5), 0)
	else
		p.Img.Position = UDim2.new(px, 0, py, 0)
	end
	p.Img.BorderSizePixel = 0
	p.Img.BackgroundTransparency = 1
	p.Img.Image = Blocks[blk].Texture
	p.Img.Parent = p.UI
	p.UI.Parent = p.Part
	p.UI.Adornee = p.Part
	
	table.insert(all_particles, p)
	
	p:init()
	return p
end

game:GetService("RunService"):BindToRenderStep("ParticleTick", Enum.RenderPriority.Last.Value-1, function(dt)
	for k, v in pairs(all_particles) do
		if v.Active then
			v:tick(dt)
		end
	end
end)

return Particle