--[[[
	Building/breaking/picking
]]

local world = require(game.ReplicatedStorage.LocalModules.world)
local selector = require(game.ReplicatedStorage.LocalModules.RaycastSelect)


local Build = {}

local CurrBlock = 1

local pickedPos

function Build.HoldBlock(blk)
	CurrBlock = blk
end


-- probably would be better to use Vector3int16
function IVec3_Round(v)
	return Vector3.new(math.floor(v.X+0.5), math.floor(v.Y+0.5), math.floor(v.Z+0.5))
end

-- breaks block
function Build.Break()
	assert(pickedPos ~= nil)
	game.ReplicatedStorage.LocalEvents.HBAnim:Fire(0)
	local newPos = pickedPos.BlockPos
	if pickedPos.Valid then
		world.build(newPos.X, newPos.Y, newPos.Z, 0)
	end
end

-- picks block
function Build.Pick()
	assert(pickedPos ~= nil)
	local newBlk = pickedPos.Block
	if pickedPos.Valid then
		local IGH = require(game.ReplicatedStorage.LocalModules.BlockSelect.IngameHotbar)
		IGH.selected(newBlk)
	end
end

-- places block
function Build.Build()
	assert(pickedPos ~= nil)
	local newPos = pickedPos.TranslatedPos
	if pickedPos.Valid then
		world.build(newPos.X, newPos.Y, newPos.Z, CurrBlock)
	end
end

local LeftMouse = false
local RightMouse = false

local LastClick = 0

game.ReplicatedStorage.LocalEvents.KeyDown.Event:Connect(function(input, gameproc)
	if gameproc then return end
	
	
	-- World1/2/3 inputs are not used by ROBLOX, so we use it for the mouse since there's no KeyCode for mouse clicks
	if input == Enum.KeyCode.World1 then
		LeftMouse = true
		LastClick = tick()
		Build.Break()
	elseif input == Enum.KeyCode.World2 then
		RightMouse = true
		LastClick = tick()
		Build.Build()
	elseif input == Enum.KeyCode.World3 then
		Build.Pick()
	end
end)

game.ReplicatedStorage.LocalEvents.KeyUp.Event:Connect(function(input, gameproc)
	
	if input == Enum.KeyCode.World1 then
		LeftMouse = false
	end
	
	if input == Enum.KeyCode.World2 then
		RightMouse = false
	end
	

end)

local gui = require(game.ReplicatedStorage.LocalModules.GeneralUI)

spawn(function()
	local sboxbb = Instance.new("Part")
	sboxbb.Transparency = 1
	sboxbb.Anchored = true
	sboxbb.CanCollide= false
	sboxbb.Size = Vector3.new(1,1,1)
	
	sboxbb.Parent = workspace
	
	local sbox = Instance.new("SelectionBox")
	sbox.LineThickness = 0.0033
	sbox.Color3 = Color3.fromRGB(0, 0, 0)
	sbox.SurfaceTransparency = 1
	sbox.Transparency = 0.6
	sbox.Adornee = sboxbb
	sbox.Parent = workspace
	
	-- main loop (30hz)
	while wait() do
		if not gui.islocked() then
			pickedPos = selector.CastMouse(5)
			
			if pickedPos.Valid then
				local newPos = (pickedPos.Min + pickedPos.Max)/2
				local newSize = (pickedPos.Max - pickedPos.Min)
				
				sboxbb.Size = newSize
				sboxbb.CFrame = CFrame.new(newPos)
				
			else
				-- move it out of view somewhere
				sboxbb.CFrame = CFrame.new(-999, -5000, -99999)
			end
			
			if ((tick() - LastClick) > 1/4) then
				LastClick = tick()
				if LeftMouse then
					Build.Break()
				elseif RightMouse then
					Build.Build()
				end
			end
		end
	end
end)

return Build
