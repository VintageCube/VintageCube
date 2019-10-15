-- fake windows xp mouse to replace the roblox cursor

local Mouse = {}

function Mouse.on_gameproc_changed(to)
	Mouse.hb.Visible = not to
	Mouse.cursor.Visible = to
end


function Mouse.init(lockfunc, unlockfunc, gen)
	Mouse.UI = gen.ScreenGui("MouseUI", 50000)
		
	Mouse.cursor = Instance.new("ImageLabel")
	Mouse.cursor.Image = "http://www.roblox.com/asset/?id=3732801348" --3dgarro
	Mouse.cursor.Size = UDim2.new(0, 11, 0, 19)
	Mouse.cursor.BackgroundTransparency = 1
	Mouse.cursor.Parent = Mouse.UI
	
	Mouse.cursor.Visible = false
	
	Mouse.hb = Instance.new("Frame")
	Mouse.hb1 = Instance.new("Frame")
	Mouse.hb2 = Instance.new("Frame")
	
	Mouse.hb.Size = UDim2.new(0, 20, 0, 20)
	Mouse.hb.BackgroundTransparency = 1
	
	Mouse.hb1.Size = UDim2.new(0, 20, 0, 2)
	Mouse.hb2.Size = UDim2.new(0, 2, 0, 20)
	
	for _, item in pairs({Mouse.hb1, Mouse.hb2}) do
		item.BorderSizePixel = 0
		item.BackgroundColor3 = Color3.new(1,1,1)
		item.Position = UDim2.new(0.5, 0, 0.5, 0)
		item.AnchorPoint = Vector2.new(0.5, 0.5)
		item.Parent = Mouse.hb
	end
	Mouse.hb.Position = UDim2.new(0.5, 0, 0.5, 0)
	Mouse.hb.AnchorPoint = Vector2.new(0.5, 0.5)

	Mouse.hb.Parent = Mouse.UI
	Mouse.hb.Visible = true
	
	Mouse.UI.Parent = game.Players.LocalPlayer.PlayerGui
	
	game:GetService("UserInputService").MouseIconEnabled = false
	
	game:GetService("UserInputService").InputChanged:Connect(function(input, gameproc)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			Mouse.cursor.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y+36)
		end
	end)
end

return Mouse

--http://www.roblox.com/asset/?id=3732801348