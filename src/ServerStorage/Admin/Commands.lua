local Commands = {}

local Permissions = require(game.ServerStorage.Admin.Permissions)
local Groups = Permissions.Groups

local ARG = {
    PLAYER = 0,
    UID = 1,
    WORD = 2,
    STRING = 3,
    COMMAND = 4
}

function Commands.ArgTypeToStr(argtype)
    for k, v in pairs(ARG) do
        if v == argtype then
            return k
        end
    end
end

function Commands.FindCommand(name)
    local curr_cmd = Commands.CmdList[name]
    if not curr_cmd then
        for k, v in pairs(Commands.CmdList) do
            local found = false
            for _, e in pairs(v.Aliases) do
                if e == name then
                    curr_cmd = v
                    found = true
                    break
                end
            end
            if found then break end
        end
    end
    if not curr_cmd then return end
    curr_cmd.Name = name
    return curr_cmd
end

local serverbanplayers = {}
local pbanstore = game:GetService("DataStoreService"):GetDataStore("pbans01")

local bbanstore = game:GetService("DataStoreService"):GetDataStore("bbans01") --building bans

function Commands.IsBuildBanned(ply)
    return bbanstore:GetAsync(tostring(ply.UserId))
end

game.Players.PlayerAdded:Connect(function(ply)
    if(serverbanplayers[ply.UserId]) then
        ply:Kick("You have been banned for " .. tostring(serverbanplayers[ply.UserId]))
    end

    local pban = pbanstore:GetAsync(tostring(ply.UserId))
    if pban then
        ply:Kick("You have been permanently banned for " .. tostring(pban))
    end
end)

Commands.CmdList = {
    -- general commands
    ping = {
        Aliases = {},
        Permission = Groups.User,
        Arguments = {},
        Run = function()
            return {Success = true, Message = "Pong!"}
        end
    },

    echo = {
        Aliases = {"say"},
        Permission = Groups.User,
        Arguments = {ARG.STRING},
        Run = function(str)
            return {Success = true, Message = str}
        end
    },

    help = {
        Aliases = {"cmdinfo"},
        Permission = Groups.User,
        Arguments = {ARG.COMMAND},
        Run = function(cmd)
            local helpstr = "cmd " .. cmd.Name  
            for k, v in pairs(cmd.Arguments) do
                helpstr = helpstr .. " [" .. Commands.ArgTypeToStr(v) .. "]"
            end

            return {
                Success = true,
                Message = helpstr
            }
        end
    },

    -- administrative commands
    kick = {
        Aliases = {"remove"},
        Permission = Groups.Admin,
        Arguments = {ARG.PLAYER, ARG.STRING},
        Run = function(ply, reason)
            ply:Kick(reason)
            return {
                success = true,
                Message = "Kicked " .. ply.Name .. " for " .. reason
            }
        end
    },

    ban = {
        Aliases = {"sban"},
        Permission = Groups.Admin,
        Arguments = {ARG.UID, ARG.STRING},
        Run = function(uid, reason)
            serverbanplayers[uid] = reason
            for k, v in pairs(game.Players:GetChildren()) do
                if(v.UserId == uid) then
                    v:Kick("You have been banned for " .. reason)
                end
            end
            return {
                success = true,
                Message = "Banned " .. uid .. " for " .. reason
            }
        end
    },

    unban = {
        Aliases = {"uban"},
        Permission = Groups.Admin,
        Arguments = {ARG.UID},
        Run = function(uid)
            local wasBanned = serverbanplayers[uid]
            if not wasBanned then
                return {
                    success = false,
                    Message = tostring(uid) .. " was not server-banned on this server!"
                }
            else
                serverbanplayers[uid] = nil
                return {
                    success = true,
                    Message = tostring(uid) .. " has been unbanned (previously banned for " .. wasBanned .. ")"
                }
            end

        end
    },
    
    -- permanent
    pban = {
        Aliases = {"permaban"},
        Permission = Groups.Owner,
        Arguments = {ARG.UID, ARG.STRING},
        Run = function(uid, reason)
            pbanstore:SetAsync(tostring(uid), reason)
            for k, v in pairs(game.Players:GetChildren()) do
                if(v.UserId == uid) then
                    v:Kick("You have been banned for " .. reason)
                end
            end
            return {
                success = true,
                Message = "Permanently banned " .. uid .. " for " .. reason
            }
        end
    },

    unpban = {
        Aliases = {"upban", "unpermaban"},
        Permission = Groups.Owner,
        Arguments = {ARG.UID},
        Run = function(uid)
            local wasBanned = pbanstore:GetAsync(tostring(uid))
            if not wasBanned then
                return {
                    success = false,
                    Message = tostring(uid) .. " was not perma-banned!"
                }
            else
                pbanstore:SetAsync(tostring(uid), false)
                return {
                    success = true,
                    Message = tostring(uid) .. " has been unbanned (previously banned for " .. wasBanned .. ")"
                }
            end

        end
    },

   -- permanent building bans
   bban = {
        Aliases = {"buildban", "breakban", "nobuild"},
        Permission = Groups.Admin,
        Arguments = {ARG.UID},
        Run = function(uid, reason)
            bbanstore:SetAsync(tostring(uid), true)
            return {
                success = true,
                Message = "Permanently banned " .. uid .. " from building."
            }
        end
    },

    unbban = {
        Aliases = {"unbuildban", "unbreakban", "unnobuild"},
        Permission = Groups.Admin,
        Arguments = {ARG.UID},
        Run = function(uid)
            bbanstore:SetAsync(tostring(uid), false)
            return {
                success = true,
                Message = "Unbanned " .. uid .. " from building."
            }
        end
    },



}



Commands.ArgTypes = ARG

return Commands