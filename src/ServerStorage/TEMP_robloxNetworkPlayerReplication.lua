function GetPlayersSkin(ply)
	if ply == "Borsy" then
		return "rbxassetid://3438217011"
	end
	return "rbxassetid://3438200500"
end


game.ReplicatedStorage.Remote.NetworkCharacter.get_skin.OnServerInvoke = function(origin, plyName)
	return GetPlayersSkin(plyName)
end

local PlayersList = {}

function PlayerToID(ply)
	for k, v in pairs(PlayersList) do
		if v == ply then
			return k
		end
	end
end


local function onNewPlayer(ply)
	table.insert(PlayersList, ply)
	for k, v in ipairs(game.Players:GetChildren()) do
		if v ~= ply then
			-- TODO: send position along with add?
			game.ReplicatedStorage.Remote.NetworkCharacter.add:FireClient(ply, PlayerToID(v), v.Name)
			game.ReplicatedStorage.Remote.NetworkCharacter.add:FireClient(v, PlayerToID(ply), ply.Name)
		end
	end
	
end



game.Players.PlayerAdded:Connect(onNewPlayer)

game.Players.PlayerRemoving:Connect(function(ply)
	local plyId = PlayerToID(ply)
	if not plyId then
		error("Player removing, no plyID found")
	end
	
	PlayersList[plyId] = nil
	
	for k, v in ipairs(game.Players:GetChildren()) do
		if v ~= ply then
			game.ReplicatedStorage.Remote.NetworkCharacter.kill:FireClient(v, plyId)
		end
	end
end)

game.ReplicatedStorage.Remote.NetworkCharacter.update.OnServerEvent:Connect(function(ply, x, y, z, pitch, yaw)
	for k, v in ipairs(game.Players:GetChildren()) do
		if v ~= ply then
			game.ReplicatedStorage.Remote.NetworkCharacter.update:FireClient(v, PlayerToID(ply), x, y, z, pitch, yaw)
		end
	end
	
	
end)


for k, v in ipairs(game.Players:GetChildren()) do
	onNewPlayer(v)
end

return true