--[[
	Entity class for creating entities. New models may be defined by adding a model parented to this script, with a "ModelScript" module that handles everything.
]]

local entlist = {}
local fullentlist = {}

local Entity = {}

local fontgen = require(game.ReplicatedStorage.LocalModules.FontGen)
local SCALE_NAMETAGS = false
local NAMETAGS_ALWAYS_VISIBLE = false

local plyList = require(game.ReplicatedStorage.LocalModules.GeneralUI.PlyList)

local genEntity = require(script.model_gen)

function Entity:generate_model()
	local curr_model = self.model
	if curr_model then
		curr_model:Destroy()
	end
	
	local tgt_model = script:FindFirstChild(self.model_name)
	if not tgt_model then
		error("Invalid model name " .. tostring(self.model_name))
	end
	
	self.model = tgt_model:Clone()
	self.api = require(self.model.ModelScript)
	
	if self.api.ModelData then
		genEntity(self.api.ModelData, self.api.getSkin(self.name), self.model)
	end

	self.api.init(self, self.name)
	
	self.model.Parent = workspace
end

function Entity:destroy_model()
	local curr_model = self.model
	if curr_model then
		curr_model:Destroy()
	end
	
	self.model = nil
	self.api = nil
end

function Entity:set_model(mdl)
	if typeof(mdl) ~= "string" then
		error("Attempt to call Entity:set_model with invalid model type " .. typeof(mdl))
	end
	
	self.model_name = mdl
	if self.active then
		self:generate_model()
	end
end

function Entity:tick(dt)
	if self.show_nametag and not self.nametag then
		self.nametag = Instance.new("BillboardGui") --TODO: make nametags only appear when you hover over the entity
		
		self.nametag.StudsOffsetWorldSpace = self.api.calculate_nametag_offset()
		
		self.nametag_txt = fontgen.CreateTextLabel(self.name, nil, nil, nil, true) 
		if SCALE_NAMETAGS then
			self.nametag.Size = UDim2.new(0, self.nametag_txt.Size.X.Offset + 8, 0, self.nametag_txt.Size.Y.Offset + 8)
		else
			self.nametag.Size = UDim2.new(((self.nametag_txt.Size.X.Offset+24) / 64), 0, ((self.nametag_txt.Size.Y.Offset+8) / 64) , 0)
			-- HACK: scale all imagelabels
			for k, v in pairs(self.nametag_txt:GetDescendants()) do
				v.Size = UDim2.new(v.Size.X.Offset / v.Parent.AbsoluteSize.X, 0, v.Size.Y.Offset / v.Parent.AbsoluteSize.Y, 0)
				v.Position = UDim2.new(v.Position.X.Offset / v.Parent.AbsoluteSize.X, 0, v.Position.Y.Offset / v.Parent.AbsoluteSize.Y, 0)
			end
			self.nametag_txt.Size = UDim2.new(0.9, 0, 0.9, 0)
		end
		

		local nametag_bg = Instance.new("Frame")
		nametag_bg.Size = UDim2.new(1, 0, 1, 0)
		nametag_bg.AnchorPoint = Vector2.new(0.5, 0.5)
		nametag_bg.Position = UDim2.new(0.5, 0, 0.5, 0)
		nametag_bg.BackgroundTransparency = 1--0.5
		nametag_bg.BackgroundColor3 = Color3.new(0, 0, 0)
		nametag_bg.BorderSizePixel = 0
		
		nametag_bg.Parent = self.nametag
		
		self.nametag_txt.Position = UDim2.new(0.5, 0, 0.5, 0)
		self.nametag_txt.AnchorPoint = Vector2.new(0.5, 0.5)
		
		self.nametag_txt.Parent = nametag_bg
		
		self.nametag.AlwaysOnTop = NAMETAGS_ALWAYS_VISIBLE
		
		self.nametag.Parent = self.model.PrimaryPart
	end
	
	local oldpos
	local newpos
	
	if self.interpolate then
		-- set position, orientation using interpolation
		if not self.interp_position then
			self.interp_position = self.position
		end
		
		if not self.interp_ort then
			self.interp_ort = self.orientation
		end

		-- animate 
		oldpos = Vector3.new(self.interp_position.X, 0, self.interp_position.Z)
		
		self.interp_position = self.interp_position:Lerp(self.true_position, 1/self.interpolate)
		self.interp_ort = self.interp_ort:Lerp(self.orientation, 1/self.interpolate)
		
		self.api.set_position(self.interp_position.X, self.interp_position.Y, self.interp_position.Z)
		self.api.set_orientation(self.interp_ort.Y, self.interp_ort.X, 0)
		
		newpos = Vector3.new(self.interp_position.X, 0, self.interp_position.Z)
	else
		-- set position, orientation using current position, orientation
		self.api.set_position(self.position.X, self.position.Y, self.position.Z)
		self.api.set_orientation(self.orientation.Y, self.orientation.X, 0)
		
		-- animate
		oldpos = self.old_pos
		newpos = self.position
	end
	
	
	self.swing = self.swing or 0
	self.wd = self.wd or 0
	
	local dx = oldpos.X - newpos.X
	local dz = oldpos.Z - newpos.Z
	
	local dist = math.sqrt(dx * dx + dz * dz)/(20*dt)
	
	
	
	if dist > 0.02 then
		local walkDelta = dist * 2 * (20 * dt)
		self.wd = self.wd + walkDelta
		self.swing = self.swing + (dt * 3 * (20 * dt))
	else
		self.swing = self.swing - (dt * 3 * (20 * dt))
	end
	
	self.swing = math.clamp(self.swing, 0.0 , 1.0)
	
	self.bobbing_model = math.abs(math.cos(self.wd)) * self.swing * (4.0 / 16)
	
	self.anim_data = {
		["swing"] = self.swing,
		["walktime"] = self.wd,
		["tick"] = tick(),
		["bobbing_model"] = self.bobbing_model
	}
		
	self.api.animate(self.anim_data)
end

function Entity:set_position(v3, TrueV3)
	local oldpos = self.position or Vector3.new()
	self.position = v3
	
	if not self.interpolate then
		self.true_position = TrueV3
	else
		self.true_position = v3
--		local dx = oldpos.X - v3.X
--		local dz = oldpos.Z - v3.Z
--		self.distance = math.sqrt(dx * dx + dz * dz)
	end
	
	self.old_pos = oldpos
end

function Entity:set_orientation(v3)
	self.orientation = v3
end

function Entity:set_animate(anim_data)
	self.anim_data = anim_data
end

function Entity:show_nametag(show)
	self.show_nametag = show
end

function Entity:destroy()
	self.active = false
	self:destroy_model()
	
	-- deregister from tick
	entlist[self] = nil
	fullentlist[self] = nil
	
	plyList.remove_ply(self.id)
end

function Entity:init(autotick)
	if self.active then
		warn("Attempt to initialize already-active entity")
		return
	end
	if not self.model_name then
		error("Attempt to init with no model")
	end
	
	self.active = true
	self:generate_model()
	
	-- register to tick
	entlist[self] = autotick
	fullentlist[self] = true
	
	plyList.add_ply(self.id, self.name)
end



function Entity.new(name, id)
	local ent = {}
	setmetatable(ent, {__index = Entity})
	
	ent.name = name
	ent.id = id
	
	ent:set_model("None")
	ent.interpolate = false
	
	ent.position = Vector3.new(0, 0, 0)
	ent.orientation = Vector3.new(0, 0, 0)
	
	return ent
end


function EntityTick(dt)
	for entity, is_active in pairs(entlist) do
		if is_active then
			entity:tick(dt)
		end
	end
end

game:GetService("RunService"):BindToRenderStep("entity_ticks", Enum.RenderPriority.Character.Value+1, EntityTick)

-- checks if any entity AABBs intersect with the given AABB. used to prevent building inside of yourself and other entities
function Entity.intersectsWithAny(aabb)
	for entity, exists in pairs(fullentlist) do
		if exists and entity.api then
			local entity_bb = entity.api.get_aabb()
			if entity_bb:Intersects(aabb) then
				return entity
			end
		end
	end
	return false
end

function Entity.getallentities()
	return fullentlist
end

return Entity