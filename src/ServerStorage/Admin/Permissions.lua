local Permissions = {}

Permissions.GROUP_ID = 5132530

Permissions.Groups = {
    User = 0,
    Builder = 1,
    Admin = 127,
    Owner = 255
}

function Permissions.GetPermissionLevel(ply)
    return ply:GetRankInGroup(Permissions.GROUP_ID)
end

function Permissions.IsPermittedToRun(ply, grouplvl)
    return (Permissions.GetPermissionLevel(ply) >= grouplvl)
end

return Permissions