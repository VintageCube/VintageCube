local blockselect = require(game.ReplicatedStorage.LocalModules.BlockSelect)

function IsLMBAllowed()
	return not blockselect.IsOpen()
end

function IsRMBAllowed()
	return not blockselect.IsOpen()
end

function is_gameprocessed()
	return game.ReplicatedStorage.LocalEvents.gameproc.Value == true
end


game:GetService("UserInputService").InputBegan:Connect(function(input, gameproc)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		game.ReplicatedStorage.LocalEvents.KeyDown:Fire(input.KeyCode, is_gameprocessed())
	elseif (input.UserInputType == Enum.UserInputType.MouseButton1) and IsLMBAllowed() then
		game.ReplicatedStorage.LocalEvents.KeyDown:Fire(Enum.KeyCode.World1, is_gameprocessed())
	elseif (input.UserInputType == Enum.UserInputType.MouseButton2) and IsRMBAllowed() then
		game.ReplicatedStorage.LocalEvents.KeyDown:Fire(Enum.KeyCode.World2, is_gameprocessed())
	elseif (input.UserInputType == Enum.UserInputType.MouseButton3) and IsRMBAllowed() then
		game.ReplicatedStorage.LocalEvents.KeyDown:Fire(Enum.KeyCode.World3, is_gameprocessed())
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input, gameproc)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		if input.Position.Z < 0 then
			game.ReplicatedStorage.LocalEvents.KeyDown:Fire(Enum.KeyCode.KeypadPlus, is_gameprocessed())
		else
			game.ReplicatedStorage.LocalEvents.KeyDown:Fire(Enum.KeyCode.KeypadMinus, is_gameprocessed())
		end
		
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input, gameproc)
	-- for future use with custom textboxes to filter input
	if input.UserInputType == Enum.UserInputType.Keyboard then
		game.ReplicatedStorage.LocalEvents.KeyUp:Fire(input.KeyCode, is_gameprocessed())
	elseif (input.UserInputType == Enum.UserInputType.MouseButton1) and IsLMBAllowed() then
		game.ReplicatedStorage.LocalEvents.KeyUp:Fire(Enum.KeyCode.World1, is_gameprocessed())
	elseif (input.UserInputType == Enum.UserInputType.MouseButton2) and IsRMBAllowed() then
		game.ReplicatedStorage.LocalEvents.KeyUp:Fire(Enum.KeyCode.World2, is_gameprocessed())
	end
end)


return true