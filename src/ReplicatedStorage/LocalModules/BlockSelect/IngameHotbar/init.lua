--[[
	Hotbar on the bottom of the screen
]]

local terrain = require(game.ReplicatedStorage.LocalModules.terrain)
local generator = require(game.ReplicatedStorage.LocalModules.BlockGen)
local renderer = require(script.HeldBlockRenderer)
local build = require(game.ReplicatedStorage.LocalModules.Build)

local blk = require(game.ReplicatedStorage.LocalModules.BlocksID)

local IsometricCamera = Instance.new("Camera")
IsometricCamera.CFrame = CFrame.new(24*2.5, 19.6*2.5, 24*2.5) * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(math.rad(-30), 0, 0)
IsometricCamera.FieldOfView = 1


function search(tbl, For)
	for k, v in pairs(tbl) do
		if v == For then
			return k
		end
	end
end




local hotbar = {}

-- scale+offset positions for selector
local position = {
	{0/9, -2},
	{1/9, -2},
	{2/9, -2},
	{3/9, -3},
	{4/9, -3},
	{5/9, -4},
	{6/9, -4},
	{7/9, -5},
	{8/9, -5}
}

-- default items
hotbar.items = {
	blk.BLOCK_STONE,
	blk.BLOCK_COBBLE,
	blk.BLOCK_BRICK,
	blk.BLOCK_DIRT,
	blk.BLOCK_WOOD,
	blk.BLOCK_LOG,
	blk.BLOCK_LEAVES,
	blk.BLOCK_GLASS,
	blk.BLOCK_SLAB
}

hotbar.keybinds = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine
}

hotbar.vpframes = {}

-- calculates offset for each item in hotbar
function hotbar.calculate_offset(at)
	local initialOffset = 2 --scale
	local frameSize = 40
	local offset = UDim2.new(0, initialOffset + frameSize*(at-1) + frameSize/2, 0, initialOffset + frameSize/2)
	return offset
end

function hotbar.generate_vpframe(blockid)
	local vpframe = Instance.new("ViewportFrame")
	vpframe.BackgroundTransparency = 1
	vpframe.CurrentCamera = IsometricCamera
	local blk = generator.CreateBlock(blockid, nil, 1, Vector3.new(0,0,0))
	blk.Parent = vpframe
	vpframe.Size = UDim2.new(0, 36, 0, 36)
	vpframe.AnchorPoint = Vector2.new(0.5, 0.5)
	
	return vpframe
end


-- initialize hotbar
function hotbar.generate_hotbar()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Hotbar"
	
	local hotimg = Instance.new("ImageLabel")
	hotimg.Size = UDim2.new(0, 364, 0, 44)
	hotimg.Position = UDim2.new(0.5, 0, 1, 0)
	hotimg.AnchorPoint = Vector2.new(0.5, 1)
	hotimg.BackgroundTransparency = 1
	hotimg.Image = terrain.hotbar2x
	hotimg.Parent = gui
	
	
	for i=1, 9 do
		hotbar.vpframes[i] = hotbar.generate_vpframe(hotbar.items[i])
		hotbar.vpframes[i].Position = hotbar.calculate_offset(i)
		hotbar.vpframes[i].Parent = hotimg
	end
	
	local selector = Instance.new("ImageLabel")
	selector.Size = UDim2.new(0, 48, 0, 48)
	selector.AnchorPoint = Vector2.new(0, 0.5)
	selector.Position = UDim2.new(0, -2, 0.5, 0)
	selector.BackgroundTransparency = 1
	selector.Image = terrain.select2x
	selector.Parent = hotimg
	
	gui.Parent = game.Players.LocalPlayer.PlayerGui
	hotbar.hotimg = hotimg
	hotbar.gui = gui
	hotbar.selector = selector
	
	-- bind events
	game.ReplicatedStorage.LocalEvents.KeyDown.Event:Connect(function(input, gameproc)
		if gameproc then return end
		local to = search(hotbar.keybinds, input)
		if to then
			hotbar.current = to
			hotbar.move_selector()
		elseif input == Enum.KeyCode.KeypadPlus then
			hotbar.current = (hotbar.current % 9) + 1
			hotbar.move_selector()
		elseif input == Enum.KeyCode.KeypadMinus then
			hotbar.current = ((hotbar.current - 2) % 9) + 1
			hotbar.move_selector()
		end
	end)
end



hotbar.current = 1



function hotbar.move_selector()

	local pos = position[hotbar.current]
	if hotbar.selector.Position == UDim2.new(pos[1], pos[2], 0.5, 0) then return end
	hotbar.selector.Position = UDim2.new(pos[1], pos[2], 0.5, 0)
	
	renderer.set(hotbar.items[hotbar.current])
	build.HoldBlock(hotbar.items[hotbar.current])
end

function hotbar.replace_item(at, with)
	hotbar.items[at] = with
	local old_frame = hotbar.vpframes[at]
	if old_frame then
		old_frame:Destroy()
	else
		warn("No old frame??? " .. tostring(at))
	end
	local vpframe = hotbar.generate_vpframe(with)
	vpframe.Position = hotbar.calculate_offset(at)
	vpframe.Parent = hotbar.hotimg
	hotbar.vpframes[at] = vpframe
end

function hotbar.selected(num)
	local at = search(hotbar.items, num)
	if not at then
		at = hotbar.current
		hotbar.replace_item(at, num)
	elseif at ~= hotbar.current then
		local other_blk = hotbar.items[at]
		local this_blk = hotbar.items[hotbar.current]
		hotbar.replace_item(at, this_blk)
		hotbar.replace_item(hotbar.current, other_blk)
		--hotbar.current = at
		--hotbar.move_selector()
	end
	renderer.set(num)
	build.HoldBlock(num)
end


hotbar.generate_hotbar()

return hotbar