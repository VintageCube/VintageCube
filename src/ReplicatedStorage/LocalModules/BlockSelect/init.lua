--[[
	The block selection menu (B menu)
	very messy non-commented code sorry
]]

local BlockSel = {}

local BLOCKS = require(game.ReplicatedStorage.LocalModules.BlocksID)
local BlockGen = require(game.ReplicatedStorage.LocalModules.BlockGen)
local FontGen = require(game.ReplicatedStorage.LocalModules.FontGen)

local gui = require(game.ReplicatedStorage.LocalModules.GeneralUI)

local hotbar = require(script.IngameHotbar)


local classicInventory = game.ReplicatedStorage.Remote.GetAllowedBlocks:InvokeServer("Inventory")

BlockSel.InventoryGuiObject = nil
BlockSel.LastClosed = 0

local Opened = false

BlockSel.IsOpen = function()
	return (BlockSel.InventoryGuiObject and --[[BlockSel.InventoryGuiObject.Enabled]] Opened) or (BlockSel.LastClosed > tick() - 0.1)
end
local IsometricCamera = Instance.new("Camera")
IsometricCamera.CFrame = CFrame.new(24*2.5, 19.6*2.5, 24*2.5) * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(math.rad(-30), 0, 0)
--IsometricCamera.CFrame = CFrame.new(18.35, 24.25, 29) * CFrame.Angles(0, math.rad(32.25), 0) * CFrame.Angles(math.rad(-35.25), 0, 0)
IsometricCamera.FieldOfView = 1
IsometricCamera.Name = "ISOC"
IsometricCamera.Parent = workspace
local WarningMessage
local MS = {}
function BlockSel.GenerateInventory(ChangeBlkFunc)
	if BlockSel.InventoryGuiObject then
		warn("GenerateInventory called, but UI already exist...")
		return
	end
	
	local UIObject = Instance.new("ScreenGui")
	UIObject.Enabled = false
	Opened= false
	UIObject.ResetOnSpawn = false
	UIObject.IgnoreGuiInset = true
	
	
	local ModalBtn = Instance.new("TextButton")
	ModalBtn.Name = "ModalBtn"
	ModalBtn.BackgroundTransparency = 1
	ModalBtn.Size = UDim2.new(0, 0, 0, 0)
	ModalBtn.Text = ""
	ModalBtn.Position = UDim2.new(-99, 0, 99, 0)
	ModalBtn.Parent = UIObject
	
	UIObject.Name = "IV"
	
	local BlockInventory = Instance.new("ImageLabel")
	BlockInventory.Name = "Inventory"
	
	BlockInventory.Size = UDim2.new(0, 480, 0, 50*(math.ceil(#classicInventory/9) + 1))
	BlockInventory.AnchorPoint = Vector2.new(0.5, 0.5)
	
	BlockInventory.Position = UDim2.new(0.5, 0, 0.5, 0)
	BlockInventory.BorderSizePixel = 0
	BlockInventory.BackgroundTransparency = 1
	BlockInventory.Image = "http://www.roblox.com/asset/?id=3732292179"
	BlockInventory.BackgroundColor3 = Color3.new(0, 0, 0)
	
	local AllBlockContainer = Instance.new("Frame")
	AllBlockContainer.Size = UDim2.new(0, 412, 0, 222)
	AllBlockContainer.Position = UDim2.new(0, 23 + 1, 0, 44 + 3)
	AllBlockContainer.BackgroundTransparency = 1
	AllBlockContainer.Parent = BlockInventory
	
	local Text = FontGen.CreateTextLabel("Select block")
	Text.Position = UDim2.new(0, 180, 0, 8)
	Text.Visible = false
	Text.Parent = BlockInventory
	
	local x = 0
	local y = 0
	
	local q = 0
	for k, v in pairs(classicInventory) do
		
		local VPF = Instance.new("ViewportFrame")
		VPF.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		VPF.Size = UDim2.new(0, 42, 0, 42)
		VPF.AnchorPoint = Vector2.new(0.5, 0.5)
		VPF.Position = UDim2.new(0, (x*(35+15))+16, 0, (y*(39+11))+16)
		VPF.BorderSizePixel = 0
		
		local YesBlock = BlockGen.CreateBlock(v, nil, 1, Vector3.new(0,0,0))

		YesBlock.Parent = VPF
		
		VPF.CurrentCamera = IsometricCamera
		
		VPF.BackgroundTransparency = 1
		
		local n = q
		
		VPF.MouseEnter:Connect(function()
			VPF.BackgroundColor3 = Color3.new(1, 1, 1)
			VPF.BackgroundTransparency = 0.3
			VPF.Size = UDim2.new(0, 55, 0, 55)
			Text.Visible = true
			q = q + 1
			n = q
		end)
		
		local mouseLeave = function()
			if q == n then
				Text.Visible = false
			end
			VPF.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
			VPF.BackgroundTransparency = 1
			VPF.Size = UDim2.new(0, 42, 0, 42)
		end
		VPF.MouseLeave:Connect(mouseLeave)
		table.insert(MS, mouseLeave)
		VPF.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				hotbar.selected(v)
				mouseLeave()
				BlockSel.Close()
			end
		end)
		
		VPF.Parent = AllBlockContainer
		if x == 8 then
			x = 0
			y = y + 1
		else
			x = x + 1
		end
	end
	
	

	

	
	BlockSel.InventoryGuiObject = UIObject
	
	BlockInventory.Parent = UIObject
	UIObject.Parent = game.Players.LocalPlayer.PlayerGui
	
	gui.register_esc(BlockSel.IsOpen, BlockSel.Close)
end

function BlockSel.Close()
	BlockSel.InventoryGuiObject.ModalBtn.Modal = false
	BlockSel.InventoryGuiObject.Enabled = true
	BlockSel.InventoryGuiObject.Inventory.Position = UDim2.new(25, 0, 25, 0)
	BlockSel.LastClosed = tick()
	Opened = false
	
	for k, v in pairs(MS) do
		v()
	end
	--wait()
	gui.unlock_gameproc()
end

function BlockSel.Open()
	BlockSel.InventoryGuiObject.ModalBtn.Modal = true
	BlockSel.InventoryGuiObject.Enabled = true
	BlockSel.InventoryGuiObject.Inventory.Position = UDim2.new(0.5, 0, 0.5, 0)
	Opened= true
	gui.lock_gameproc()
end


return BlockSel