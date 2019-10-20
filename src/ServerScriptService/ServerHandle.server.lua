--[[
	This ServerScript handles everything on the server.
]]

-- create remote structure
local Structure = {
	LocalEvents = {
		gameproc = "BoolValue",
		Clicks = "BindableEvent",
		HBAnim = "BindableEvent",
		KeyDown = "BindableEvent",
		KeyUp = "BindableEvent",
		STOP = "BindableEvent",
		WorldReset = "BindableEvent"
	},
	
	Remote = {
		NetworkCharacter = {
			get_skin = "RemoteFunction",
			add = "RemoteEvent",
			kill = "RemoteEvent",
			update = "RemoteEvent"
		},
		
		GetAllowedBlocks = "RemoteFunction",
		GetSpawn = "RemoteFunction",
		
		ChangeBlock = "RemoteEvent",
		Chat = "RemoteEvent",
		HitMe = "RemoteEvent",
		LoadLocalCharacter = "RemoteEvent",
		OnSetPosition = "RemoteEvent",
		ReceiveWorldData = "RemoteEvent",

		GetCmdPrefix = "RemoteFunction"
	}
}

local function newClass(class, name, parent)
	local c = Instance.new(class)
	c.Name = name
	c.Parent = parent
	
	return c
end

local function handleStructure(t, par)
	for k, v in pairs(t) do
		if typeof(v) == "table" then
			local folder = newClass("Folder", k, par)
			handleStructure(v, folder)
		elseif typeof(v) == "string" then
			local c = newClass(v, k, par)
		end
	end
end

handleStructure(Structure, game.ReplicatedStorage)

local loadedVal = newClass("BoolValue", "Loaded", game.ReplicatedStorage)




-- load everything else
require(game.ServerStorage.TEMP_robloxNetworkPlayerReplication)
require(game.ServerStorage.client)

local sDefs = require(game.ServerStorage.sDefs)

local Chat = require(game.ServerStorage.Chat)

function GenWorld(x, y, z)
	sDefs.init(x, y, z, true, true)
end

local n = 5

repeat wait() until (#game.Players:GetChildren() > 0)


wait(.1)

GenWorld(92, 72, 92)



local physics = require(game.ServerStorage.Physics)

