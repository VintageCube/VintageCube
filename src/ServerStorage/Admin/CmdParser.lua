local CmdParser = {}

local Commands = require(game.ServerStorage.Admin.Commands)
local Permissions = require(game.ServerStorage.Admin.Permissions)

local ArgTypes = Commands.ArgTypes

function CmdParser.FindPly(plyName)
    local found = 0
    local ply
    for k, v in pairs(game.Players:GetChildren()) do
        if v.Name:sub(0, #plyName) == plyName then
            ply = v
            found = found + 1
        end
        if(v.Name == plyName) then -- if there's a guy named Troller and another named Troller101, we wouldn't be able to match "Troller" without this
            return v
        end
    end

    if (found ~= 1) then
        error("Found " .. tostring(found) .. " players with a name of " .. plyName)
    end

    return ply
end

function CmdParser.FindUID(uid)
    if not tonumber(uid) then
        local foundID
        local success, msg = pcall(function()
            foundID = game.Players:GetUserIdFromNameAsync(uid)
        end)
        if not success then
            error("Found no matching players with a name of " .. uid .. ". Error message: " .. msg)
        else
            return foundID
        end
    else
        return tonumber(uid)
    end
end

function CmdParser.TryToParseArgs(args, cmd_args)
    local newArgs = {}
    local idx = 1

    if not args then
        error("Fatal error: No arguments passed to argument parser")
    end

    if not cmd_args then
        error("Fatal error: Command has no argument definitions")
    end

    for k, v in pairs(cmd_args) do
        idx = idx + 1

        if #args < idx then
            error("Expected " .. tostring(#cmd_args) .. " arguments, got " .. tostring(#newArgs))
            -- TODO: show command usage instead of unhelpful error?
        end

        if v == ArgTypes.PLAYER then
            newArgs[k] = CmdParser.FindPly(args[idx])
        elseif v == ArgTypes.UID then
            newArgs[k] = CmdParser.FindUID(args[idx])
        elseif v == ArgTypes.WORD then
            newArgs[k] = args[idx]
        elseif v == ArgTypes.STRING then
            local str = ""
            for n = k + 1, #args - ((#cmd_args) - k) do
                if(#str > 1) then
                    str = str .. " "
                end
                idx = n
                str = str .. args[idx]
                
            end
            newArgs[k] = str
        elseif v == ArgTypes.COMMAND then
            local cmd = Commands.FindCommand(args[idx])
            if not cmd then
                error("Could not find command " .. cmd)
            end
            newArgs[k] = cmd
        end
    end

    return newArgs
end

function CmdParser.Parse(caller, cmd_args)
    local curr_cmd = Commands.FindCommand(cmd_args[1])

    if not curr_cmd then
        return {
            Success = false,
            Message = "Unknown command " .. cmd_args[1]
        }
    end

    if not Permissions.IsPermittedToRun(caller, curr_cmd.Permission) then
        return {
            Success = false,
            Message = "You're not permitted to run " .. cmd_args[1] .. "!"
        }
    end

    local resultingArgs
    local success, msg = pcall(function()
        resultingArgs = CmdParser.TryToParseArgs(cmd_args, curr_cmd.Arguments)
    end)

    if not success then
        return {
            Success = false,
            Message = "Argument parsing error: " .. msg
        }
    end

    local resultingOutput
    local success, msg = pcall(function()
        resultingOutput = curr_cmd.Run(unpack(resultingArgs))
    end)

    if not success then
        return {
            Success = false,
            Message = "Command Lua error: " .. msg
        }
    end

    return resultingOutput
end

return CmdParser