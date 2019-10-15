local PlyList = {}



function PlyList.on_uis(key, processed)
	if processed then return end
	
	if key == Enum.KeyCode.Tab then
		PlyList.UI.Enabled = true
	end
end

function PlyList.on_uiu(key, processed)	
	if key == Enum.KeyCode.Tab then
		PlyList.UI.Enabled = false
	end
end

function PlyList.add_ply(id, name)
	spawn(function()
		while not PlyList.Holder do wait() end
		PlyList.remove_ply(id)
		
		local label = PlyList.Gen.CreateTextLabel(name)
		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(label.Size.X.Offset, label.Size.Y.Offset)
		sc.Parent = label
		label.Parent = PlyList.Holder
		PlyList.Labels[id] = label
	end)
end

function PlyList.remove_ply(id)
	if PlyList.Labels[id] then
		PlyList.Labels[id]:Destroy()
	end
end

function PlyList.init(lockfunc, unlockfunc, generators)
	PlyList.UI = generators.ScreenGui("PlyList", 12)
	PlyList.UI.Enabled = false
	
	
	PlyList.xSize = 480
	PlyList.ySize = 300
	
	PlyList.Black = generators.CenterHolderFrame(PlyList.xSize, PlyList.ySize)
	PlyList.Black.BackgroundColor3 = Color3.new(0,0,0)
	PlyList.Black.BackgroundTransparency = 0.5
	
	PlyList.Black.Parent = PlyList.UI
	
	PlyList.Holder = generators.CenterHolderFrame(PlyList.xSize-48, PlyList.ySize - 72)
	PlyList.Holder.AnchorPoint = Vector2.new(0.5, 1)
	PlyList.Holder.Position = UDim2.new(0.5, 0, 1, -24)
	
	PlyList.Layout = Instance.new("UIGridLayout")
	PlyList.Layout.CellSize = UDim2.new(0, 4, 0, 4)
	PlyList.Layout.CellPadding = UDim2.new(0, 4, 0, 4)
	PlyList.Layout.Parent = PlyList.Holder
	
	PlyList.Holder.Parent = PlyList.Black
	
	PlyList.Labels = {}
	
	PlyList.Gen = generators
	
end

return PlyList
