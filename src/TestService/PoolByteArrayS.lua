
local PoolByteArray = {
	bsize = 0,
	str = ""
}


function PoolByteArray:resize(idx, bgfill)
	self.bsize = idx
	if (#self.str < idx) then
--		while (#self.str < idx) do
--			self.str = self.str .. string.char(bgfill or 0)
--		end
		self.str = self.str .. string.rep(string.char(bgfill or 0), idx-(#self.str))
	elseif (#self.str > idx) then
		local newStr = ""
		local n = 0
		while (#newStr < idx) do
			n = n + 1
			newStr = newStr .. string.sub(self.str, n, n)
		end
		self.str = newStr
	end
end


function PoolByteArray:get(idx)
	idx = idx + 1
	if (idx > self.bsize) then
		error("Attempt to call PoolByteArray:get(idx) with idx larger than PoolByteArray size " .. tostring(idx) .. " when size " .. tostring(self.bsize))
	end
	if (idx < 0) then
		error("idx = " .. tostring(idx-1))
	end
	return string.byte(string.sub(self.str, idx, idx))
end

function PoolByteArray:set(idx, to)
	idx = idx + 1
	if (idx > self.bsize) then
		error("Attempt to call PoolByteArray:set(idx, to) with idx larger than PoolByteArray size " .. tostring(idx) .. " when size " .. tostring(self.bsize))
	end
	if (idx < 0) then
		error("idx = " .. tostring(idx-1))
	end
	
	self.str = string.sub(self.str, 0, idx-1) .. string.char(to) .. string.sub(self.str, idx+1, #self.str)
	
	return true
end


function PoolByteArray.new(from)
	local bytes = {}
	setmetatable(bytes, {__index = PoolByteArray})
	bytes.bsize = 0
	bytes.str = ""
	if from then
		if(typeof(from) == typeof("hi")) then
			bytes.str = from
			bytes.bsize = #from
		elseif(typeof(from) == typeof({})) then
			for k, v in pairs(from) do
				if typeof(v) == typeof(1) then
					bytes.str = bytes.str .. string.char(v)
				elseif typeof(v) == typeof("a") then
					bytes.str = bytes.str .. v
				end
			end
			bytes.bsize = #from
		end
	end
	return bytes
end

return PoolByteArray