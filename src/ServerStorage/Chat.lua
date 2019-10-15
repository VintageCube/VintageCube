local Chat = {}

function filterMsg(from, to, msg)
	return game:GetService("TextService"):FilterStringAsync(msg, from.UserId):GetChatForUserAsync(to.UserId)
end


game.ReplicatedStorage.Remote.Chat.OnServerEvent:Connect(function(ply, msg)
	for k, v in pairs(game.Players:GetChildren()) do
		if v ~= ply then
			spawn(function() game.ReplicatedStorage.Remote.Chat:FireClient(v, ply.Name, filterMsg(ply, v, msg)) end)
		end
	end
end)

local sysmsgs = "&e"

game.Players.PlayerAdded:Connect(function(ply)
	game.ReplicatedStorage.Remote.Chat:FireAllClients(nil, sysmsgs .. ply.Name .. " has joined the game.")
end)

game.Players.PlayerRemoving:Connect(function(ply)
	game.ReplicatedStorage.Remote.Chat:FireAllClients(nil, sysmsgs .. ply.Name .. " has left the game.")
end)


return Chat
