function GenTex(face, csize, offset, scale, skin)
    local tex = Instance.new("Texture")
    tex.Texture = skin
    tex.StudsPerTileU = csize.X * scale
    tex.StudsPerTileV = csize.Y * scale
    tex.OffsetStudsU = offset.X * scale
    tex.OffsetStudsV = offset.Y * scale

    tex.Name = face.Name .. "_Texture"
    tex.Face = face

    return tex
end

local faces = Enum.NormalId:GetEnumItems()

function GenLimb(name, size, texdata, defaultSkin)
    local part = Instance.new("Part")
    part.Anchored = true --crazy roblox physics without this
    part.CanCollide = false
    part.Name = name
    part.Size = size

    local textures = {}

    for k, v in pairs(faces) do
        textures[k] = GenTex(v, texdata[v].Size or texdata.Size, texdata[v]
                                 .Offset +
                                 (texdata.pOffset or Vector2.new(0, 0)),
                             texdata[v].Scale or 1,
                             texdata[v].Skin or texdata.Skin or defaultSkin)
        textures[k].Parent = part
    end

    return part

end

function autoGenTexData(size, offset)
    --[[
        automatically generates texData, assuming the layout is
             TB
            LFRb (where b = back, B = bottom)
        ]]
    local texData = {
        Size = Vector2.new(4, 4),
        pOffset = offset,
        [Enum.NormalId.Top] = {Offset = Vector2.new(size.Z, 0)},
        [Enum.NormalId.Bottom] = {Offset = Vector2.new(size.Z + size.X, 0)},
        [Enum.NormalId.Front] = {Offset = Vector2.new(size.Z, size.Z)},
        [Enum.NormalId.Back] = {
            Offset = Vector2.new(size.Z + size.X + size.Z, size.Z)
        },
        [Enum.NormalId.Left] = {Offset = Vector2.new(size.Z + size.X, size.Z)},
        [Enum.NormalId.Right] = {Offset = Vector2.new(0, size.Z)}
    }

    return texData
end

function genEntity(modelData, skin, mdl)
    local EntityModel = mdl or Instance.new("Model")
    for k, v in pairs(modelData) do
        local limb = GenLimb(k, v.Size,
                             v.TexData or autoGenTexData(v.Size, v.tOffset),
                             skin)
        limb.CFrame = CFrame.new(v.Offset)
        limb.Parent = EntityModel
        if v.isPrimaryPart then
            EntityModel.PrimaryPart = limb
        end
    end

    return EntityModel
end


return genEntity