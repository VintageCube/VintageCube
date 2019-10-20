local Chat = {}
Chat.COMMAND_PREFIX = "/"

game.ReplicatedStorage.Remote.GetCmdPrefix.OnServerInvoke = function(ply)
	return Chat.COMMAND_PREFIX
end

function filterMsg(from, to, msg)
	return game:GetService("TextService"):FilterStringAsync(msg, from.UserId):GetChatForUserAsync(to.UserId)
end

function messageParsed(ply, msg)
	if(msg:sub(0, #Chat.COMMAND_PREFIX) == Chat.COMMAND_PREFIX) then

		local list = {}
		for word in msg:sub((#Chat.COMMAND_PREFIX) + 1):gmatch("%S+") do
			table.insert(list, word)
		end

		if(#list == 0) then return end

		local result = require(game.ServerStorage.Admin.CmdParser).Parse(ply, list)

		Chat.SysWhisper(ply, result.Message)

		return true
	end
end


game.ReplicatedStorage.Remote.Chat.OnServerEvent:Connect(function(ply, msg)
	if(messageParsed(ply, msg)) then
		return
	end

	for k, v in pairs(game.Players:GetChildren()) do
		if v ~= ply then
			spawn(function() game.ReplicatedStorage.Remote.Chat:FireClient(v, ply.Name, filterMsg(ply, v, msg)) end)
		end
	end
end)

Chat.SystemPrefix = "&e"
Chat.SysWhisperPrefix = "&e"

function Chat.SysBroadcast(msg)
	game.ReplicatedStorage.Remote.Chat:FireAllClients(nil, Chat.SystemPrefix .. msg)
end

function Chat.SysWhisper(to, msg)
	game.ReplicatedStorage.Remote.Chat:FireClient(to, nil, Chat.SysWhisperPrefix .. msg)
end

game.Players.PlayerAdded:Connect(function(ply)
	Chat.SysBroadcast(ply.Name .. " has joined the game.")
end)

game.Players.PlayerRemoving:Connect(function(ply)
	Chat.SysBroadcast(ply.Name .. " has left the game.")
end)




return Chat
