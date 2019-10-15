-- human animation variables
local ANIM_MAX_ANGLE = math.rad(110)
local ANIM_ARM_MAX = math.rad(60)
local ANIM_LEG_MAX = math.rad(80)
local ANIM_IDLE_MAX = math.rad(3.0)
local ANIM_IDLE_XPERIOD = 2 * math.pi / 5
local ANIM_IDLE_ZPERIOD = 2 * math.pi / 3.5



local AABB = require(game.ReplicatedStorage.LocalModules.AABB)


local ModelScript = {
	Swing = 0,
	SimpleArmsAnim = false --whether or not to use simple animation
}

-- sets model CFrame after changing orientation or position, used locally
function ModelScript.set_ppcframe()
	local mdl = ModelScript.model
	local btm_feet_offset = CFrame.new(0, mdl.Torso.Size.Y/2 + mdl.LLeg.Size.Y, 0)
	local bobbing_offset = CFrame.new(0, ModelScript.BobbingModel, 0)
	mdl:SetPrimaryPartCFrame(ModelScript.position * ModelScript.ort * btm_feet_offset * bobbing_offset)
end


-- set position, orientation. used by Entity
function ModelScript.set_position(x, y, z)
	ModelScript.position = CFrame.new(x, y, z)
	ModelScript.ort = ModelScript.ort or CFrame.new()
	ModelScript.set_ppcframe()
end

function ModelScript.set_orientation(yaw, pitch, roll)
	local mdl = ModelScript.model
	local tor = mdl.Torso

	ModelScript.position = ModelScript.position or CFrame.new()
	ModelScript.ort = CFrame.new() * CFrame.Angles(0, math.rad(yaw), 0)
	ModelScript.set_ppcframe()
	
	mdl.Head.CFrame = tor.CFrame * CFrame.new(0, tor.Size.Y/2, 0) * CFrame.Angles(math.rad(pitch), 0, 0) * CFrame.new(0, mdl.Head.Size.Y/2, 0)
end



-- animates arms and legs. used only locally in script
function ModelScript.update_animated(anim)
	
	local mdl = ModelScript.model
	
	local tor = mdl.Torso
	local lw = mdl.LLeg.Size.X
	local lh = mdl.LLeg.Size.Y
	
	mdl.LArm.CFrame = tor.CFrame * CFrame.new(-tor.Size.X/2 -lw/2, tor.Size.Y/2 - lw/2, 0) * CFrame.Angles(anim.LAX, 0, anim.LAZ) * CFrame.new(0, -tor.Size.Y/2 + lw/2, 0)
	mdl.RArm.CFrame = tor.CFrame * CFrame.new(tor.Size.X/2 + lw/2, tor.Size.Y/2 - lw/2, 0) * CFrame.Angles(anim.RAX, 0, anim.RAZ) * CFrame.new(0, -tor.Size.Y/2 + lw/2, 0)
	
	mdl.LLeg.CFrame = tor.CFrame * CFrame.new(-lw/2, -tor.Size.Y/2, 0) * CFrame.Angles(anim.LLX, 0, anim.LLZ) * CFrame.new(0, -lh/2, 0)
	mdl.RLeg.CFrame = tor.CFrame * CFrame.new( lw/2, -tor.Size.Y/2, 0) * CFrame.Angles(anim.RLX, 0, anim.RLZ) * CFrame.new(0, -lh/2, 0)
	
end


-- animate using anim_data. used by Entity
function ModelScript.animate(anim_data)
	--[[
		animdata = {
			swing = 0,
			walktime = 0,
			tick = tick(),
			bobbing_model
		}
	]]
	
	local swing = anim_data.swing
	local walktime = anim_data.walktime
	
	local idletime = anim_data.tick
	
	local idleXRot = math.sin(idletime * ANIM_IDLE_XPERIOD) * ANIM_IDLE_MAX
	local idleZRot = math.sin(idletime * ANIM_IDLE_ZPERIOD) * ANIM_IDLE_MAX + ANIM_IDLE_MAX
	
	local LeftArmX = (math.cos(walktime) * swing * ANIM_ARM_MAX) - idleXRot
	local LeftArmZ = -idleZRot
	local LeftLegX = -(math.cos(walktime) * swing * ANIM_ARM_MAX)
	local LeftLegZ = 0
	
	local RightLegX = -LeftLegX; local RightLegZ = -LeftLegZ;
	local RightArmX = -LeftArmX; local RightArmZ = -LeftArmZ
	
	if not ModelScript.SimpleArmsAnim then
		local verAngleL = 0.5 + 0.5 * math.sin(walktime * 0.23)
		local verAngleR = 0.5 + 0.5 * math.sin(walktime * 0.28)
		local horAngle = math.cos(walktime)
		
		local zRotL = -idleZRot - verAngleL * swing * ANIM_MAX_ANGLE
		local zRotR = -idleZRot - verAngleR * swing * ANIM_MAX_ANGLE
		local xRot = idleXRot + horAngle * swing * ANIM_ARM_MAX * 1.5
		
		LeftArmX = xRot
		LeftArmZ = zRotL
		RightArmX = -xRot
		RightArmZ = -zRotR
	end
	
	ModelScript.update_animated{
		LAX = LeftArmX,
		LAZ = LeftArmZ,
		RAX = RightArmX,
		RAZ = RightArmZ,
		
		LLX = LeftLegX,
		LLZ = LeftLegZ,
		RLX = RightLegX,
		RLZ = RightLegZ
	}
	
	ModelScript.BobbingModel = anim_data.bobbing_model
end


-- get offset for nametag. used by Entity
function ModelScript.calculate_nametag_offset()
	local mdl = ModelScript.model

	return Vector3.new(0, mdl.Torso.Size.Y/2 + mdl.Head.Size.Y + 0.5, 0)
end

-- get AABB of self. used by Entity
function ModelScript.get_aabb(position)
	local ent = ModelScript.entity
	local pos = position or ent.true_position
	
	local size_hor = Vector3.new(8.6/16, 0, 8.6/16)
	
	local size_height = Vector3.new(0, 28.1/16, 0)
	
	local entityBB = AABB.New(pos - size_hor/2, pos + size_hor/2 + size_height)
	
	return entityBB
end


-- returns true if the model is supposed to be pushy. used by Entity
function ModelScript.pushes()
	return true
end


-- function that returns the skin for a specific entity name
function ModelScript.getSkin(name)
	return game.ReplicatedStorage.Remote.NetworkCharacter.get_skin:InvokeServer(name)
end


-- intiializes the model. used by Entity
function ModelScript.init(entity, name)
	ModelScript.entity = entity
	ModelScript.model = script.Parent
	
	ModelScript.BobbingModel = 0
end


-- the data of the model
ModelScript.ModelData = {
	Head = {
		Size = Vector3.new(0.5, 0.5, 0.5),
		Offset = Vector3.new(0, 0.75*2 + 0.5/2, 0),
		tOffset = Vector2.new(0, 0)
	},
	Torso = {
		Size = Vector3.new(0.5, 0.75, 0.25),
		Offset = Vector3.new(0, 0.75*1.5, 0),
		tOffset = Vector2.new(1, 1),
		isPrimaryPart = true
	},
	LArm = {
		Size = Vector3.new(0.25, 0.75, 0.25),
		Offset = Vector3.new(-0.25/2 - 0.5/2, 0.75*1.5, 0),
		tOffset = Vector2.new(2, 3)
	},
	RArm = {
		Size = Vector3.new(0.25, 0.75, 0.25),
		Offset = Vector3.new(0.25/2 + 0.5/2, 0.75*1.5, 0),
		tOffset = Vector2.new(2.5, 1)
	},
	LLeg = {
		Size = Vector3.new(0.25, 0.75, 0.25),
		Offset = Vector3.new(-0.25/2, 0.75/2, 0),
		tOffset = Vector2.new(1, 3)
	},
	RLeg = {
		Size = Vector3.new(0.25, 0.75, 0.25),
		Offset = Vector3.new(0.25/2, 0.75/2, 0),
		tOffset = Vector2.new(0, 1)
	}
}

return ModelScript