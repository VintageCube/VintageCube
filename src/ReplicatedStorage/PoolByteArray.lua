--[[
	A simple byte array class. Inspired by GDScript.
	Could be memory-optimized by using strings instead of a table of numbers, which is what I did before, however it was extremely slow once the string size was too large.
	It may be possible to use a table of chunks of strings to achieve something similar.
]]


local PoolByteArray = {
	bsize = 0,
	data = {}
}

local n = 0
local lastwait = 0
function tcheck()
	n = n + 1
	if (n % 1000) == 0 then
		if(tick() - lastwait > 1) then
			wait()
			lastwait = tick()
		end
	end
end


function PoolByteArray:toStr()
	return string.char(unpack(self.data))
end

function PoolByteArray:resize(idx, bgfill)
	self.bsize = idx
	local toAdd = self.bsize - #self.data
	for i=1, toAdd do
		table.insert(self.data, 0)
		tcheck()
	end
end

function PoolByteArray:get(idx)
	idx = idx + 1
	if (idx > self.bsize) then
		error("Attempt to call PoolByteArray:get(idx) with idx larger than PoolByteArray size " .. tostring(idx))
	end
	if (idx < 0) then
		error("idx <= 0")
	end
	return self.data[idx] or 0
end

function PoolByteArray:set(idx, to)
	idx = idx + 1
	if (idx > self.bsize) then
		error("Attempt to call PoolByteArray:set(idx, to) with idx larger than PoolByteArray size " .. tostring(idx))
	end
	if (idx < 0) then
		error("idx <= 0")
	end
	
	self.data[idx] = to
	
	
	return true
end


function PoolByteArray.new(from, s)
	local bytes = {}
	setmetatable(bytes, {__index = PoolByteArray})
	bytes.bsize = 0
	bytes.data = {}
	if from then
		if typeof(from) == typeof({}) then
			for k, v in pairs(from) do
				tcheck()
				table.insert(bytes.data, v)
			end
			bytes.bsize = #bytes.data
		elseif typeof(from) == typeof("a") then
			for i=1, #from do
				tcheck()
				table.insert(bytes.data, string.sub(from, i, i))
			end
			bytes.bsize = #bytes.data
		end
	end
	if s then
		bytes.bsize = s
	end
	return bytes
end

return PoolByteArray