--[[
	Defines an AABB class
]]

local AABB = {
	Position = Vector3.new(),
	Size = Vector3.new()
}


function AABB:HasPoint(point)
	if point.X < self.Position.X then
		return false
	end
	if point.Y < self.Position.Y then
		return false
	end
	if point.Z < self.Position.Z then
		return false
	end
	if point.X > (self.Position.X + self.Size.X) then
		return false
	end
	if point.Y > (self.Position.Y + self.Size.Y) then
		return false
	end
	if point.Z > (self.Position.Z + self.Size.Z) then
		return false
	end
	
	return true
end


function AABB:Intersects(with)
	return
			self.End.X >= with.Start.X and self.Start.X <= with.End.X and
			self.End.Y >= with.Start.Y and self.Start.Y <= with.End.Y and
			self.End.Z >= with.Start.Z and self.Start.Z <= with.End.Z
end


function take1axis(a, b, axis) -- needed for changing only 1 axis of a vector (ROBLOX Lua does not support directly changing 1 Vector3 axis (v3.X = 1 will error))
	return (a * (Vector3.new(1,1,1) - axis)) + (b * axis)
end

function AABB:SetMin(min, axis)
	if not axis then
		axis = Vector3.new(1,1,1)
	end
	self.Start = take1axis(self.Start, min, axis)
	self.Position = take1axis(self.Start, min, axis)
	self.Size = self.End - take1axis(self.Start, min, axis)
end

function AABB:SetMax(max, axis)
	if not axis then
		axis = Vector3.new(1,1,1)
	end
	self.End = take1axis(self.End, max, axis)
	self.Size = take1axis(self.End, max, axis) - self.Start
end

function AABB:Clamp(min, max)
	self:SetMin(Vector3.new(math.clamp(self.Start.X, min.X, max.X), math.clamp(self.Start.Y, min.Y, max.Y), math.clamp(self.Start.Z, min.Z, max.Z)))
	self:SetMax(Vector3.new(math.clamp(self.End.X, min.X, max.X), math.clamp(self.End.Y, min.Y, max.Y), math.clamp(self.End.Z, min.Z, max.Z)))
end

function AABB:WeirdIntUnintersectingFuncCall(other, func, threaded)
	-- needed for the rendering system
	
	-- this will call the supplied function in the 2nd argument for every unintersecting integer coordinate between self (an AABB) and other (the supplied AABB)
	-- the rendering system creates an AABB of the current area around the camera and uses the stored previous area around the camera to call this function and generate needed parts, while destroying parts that are out of view
	-- the threaded argument allows doing this in a threaded way, but it will still yield until each of the threads are finished
	
	local done = 0
	
	local function MinY()
		if self.Start.Y < other.Start.Y then
			for x = self.Start.X, self.End.X do
				for z = self.Start.Z, self.End.Z do
					for y = self.Start.Y, other.Start.Y do
						if not func(x, y, z) then done = done + 1 return end					
					end
				end
			end
		end
		done = done + 1
	end
	
	local function MaxY()
		if self.End.Y > other.End.Y then
			for x = self.Start.X, self.End.X do
				for z = self.Start.Z, self.End.Z do
					for y = other.End.Y, self.End.Y do
						if not func(x, y, z) then done = done + 1 return end
					end
				end
			end
		end
		done = done + 1
	end
	
	
	local function MinX()
		if self.Start.X < other.Start.X then
			for y = self.Start.Y, self.End.Y do
				for z = self.Start.Z, self.End.Z do
					for x = self.Start.X, other.Start.X do
						if not func(x, y, z) then done = done + 1 return end
					end
				end
			end
		end
		done = done + 1
	end
	
	local function MaxX()
		if self.End.X > other.End.X then
			for y = self.Start.Y, self.End.Y do
				for z = self.Start.Z, self.End.Z do
					for x = other.End.X, self.End.X do
						if not func(x, y, z) then done = done + 1 return end
					end
				end
			end
		end
		done = done + 1
	end
	
	
	local function MinZ()
		if self.Start.Z < other.Start.Z then
			for y = self.Start.Y, self.End.Y do
				for x = self.Start.X, self.End.X do
					for z = self.Start.Z, other.Start.Z do
						if not func(x, y, z) then done = done + 1 return end
					end
				end
			end
		end
		done = done + 1
	end
	
	local function MaxZ()
		if self.End.Z > other.End.Z then
			for y = self.Start.Y, self.End.Y do
				for x = self.Start.X, self.End.X do
					for z = other.End.Z, self.End.Z do
						if not func(x, y, z) then done = done + 1 return end
					end
				end
			end
		end
		done = done + 1
	end
	
	if threaded then
		spawn(MinX)
		spawn(MaxX)
		spawn(MinY)
		spawn(MaxY)
		spawn(MinZ)
		spawn(MaxZ)
		while done < 6 do
			game:GetService("RunService").RenderStepped:wait()
		end
	else
		MinX()
		MaxX()
		MinY()
		MaxY()
		MinZ()
		MaxZ()
	end
end

function AABB.New(Start, End)
	local aabb = {}
	setmetatable(aabb, {__index = AABB})
	aabb.Start = Start or Vector3.new()
	aabb.Position = Start or Vector3.new()
	aabb.End = End or Vector3.new()
	aabb.Size = aabb.End-aabb.Start
	return aabb
end

return AABB