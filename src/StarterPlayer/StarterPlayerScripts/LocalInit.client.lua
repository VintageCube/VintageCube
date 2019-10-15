--[[
	This LocalScript loads everything on the client
]]

repeat wait() until game.ReplicatedStorage:FindFirstChild("Loaded")

require(game.ReplicatedStorage.LocalModules.GeneralUI).init()


local C = require(game.ReplicatedStorage.LocalModules.Characterize)

C.init()

require(game.ReplicatedStorage.LocalModules.InputHandler)
require(game.ReplicatedStorage.LocalModules.EnvRender)
require(game.ReplicatedStorage.LocalModules.NetworkPlayer)
require(game.ReplicatedStorage.LocalModules.world)


local selector = require(game.ReplicatedStorage.LocalModules.BlockSelect)

selector.GenerateInventory(function(a)  end)


game.ReplicatedStorage.LocalEvents.KeyDown.Event:Connect(function(input, gameproc)
	if (not selector.IsOpen() and gameproc) then return end
	if input == Enum.KeyCode.B then
		(selector.IsOpen() and selector.Close or selector.Open)();
	end
end)
