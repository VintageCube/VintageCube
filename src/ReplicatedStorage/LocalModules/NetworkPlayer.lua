local Entity = require(game.ReplicatedStorage.LocalModules.Entity)

local NetworkPlayer = {}

NetworkPlayer.Players = {}

function NetworkPlayer.Add(plyId, name)
	local ent = Entity.new(name, plyId)
	ent:set_model("humanoid")
	ent:show_nametag(true)
	ent.interpolate = 10
	
	
	local datatable = {
		ent = ent,
		initiated = false,
		model = "humanoid"
	}
	
	NetworkPlayer.Players[plyId] = datatable
end

function NetworkPlayer.Kill(plyId)
	local datatable = NetworkPlayer.Players[plyId]
	if datatable then
		datatable.ent:destroy()
	end
	NetworkPlayer.Players[plyId] = nil
end

function NetworkPlayer.Update(plyId, x, y, z, pitch, yaw)
	local datatable = NetworkPlayer.Players[plyId]
	if datatable then
		datatable.ent:set_position(Vector3.new(x, y, z))
		datatable.ent:set_orientation(Vector3.new(pitch, yaw, 0))
		
		if not datatable.initiated then
			datatable.initiated = true
			datatable.ent:init(true)
		end
	end
end





local NC = game.ReplicatedStorage.Remote.NetworkCharacter

NC.add.OnClientEvent:Connect(NetworkPlayer.Add)
NC.kill.OnClientEvent:Connect(NetworkPlayer.Kill)
NC.update.OnClientEvent:Connect(NetworkPlayer.Update)

return NetworkPlayer
