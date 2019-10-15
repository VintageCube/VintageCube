-- the main code for the local character


-- keybinds
local KEYBIND_FORWARD = Enum.KeyCode.W
local KEYBIND_BACK = Enum.KeyCode.S
local KEYBIND_LEFT = Enum.KeyCode.A
local KEYBIND_RIGHT = Enum.KeyCode.D
local KEYBIND_JUMP = Enum.KeyCode.Space
local KEYBIND_SPEED = Enum.KeyCode.LeftShift
local KEYBIND_HALF_SPEED = Enum.KeyCode.LeftControl
local KEYBIND_FLY_UP = Enum.KeyCode.E
local KEYBIND_FLY_DOWN = Enum.KeyCode.Q
local KEYBIND_NOCLIP = Enum.KeyCode.X
local KEYBIND_FLY = Enum.KeyCode.Z
local KEYBIND_RESPAWN = Enum.KeyCode.R
local KEYBIND_SET_SPAWN = Enum.KeyCode.Return
local KEYBIND_TPS = Enum.KeyCode.F5


local MoveSpeed = 0.98

local Keys = {}

local world = require(game.ReplicatedStorage.LocalModules.world)
local Blocks = require(game.ReplicatedStorage.LocalModules.Blocks)


local UIS = game:GetService("UserInputService")

local AABB = require(game.ReplicatedStorage.LocalModules.AABB)

local vals = require(game.ReplicatedStorage.LocalModules.CharValue)
local entityClass = require(game.ReplicatedStorage.LocalModules.Entity)

local gameproc = game.ReplicatedStorage.LocalEvents.gameproc



local LocalEntity

-- we use custom method for processing key inputs
function is_gameprocessed()
	return gameproc.Value == true
end

UIS.InputBegan:Connect(function(input, gameProcessedEvent)
	--if gameProcessedEvent then return end
	if is_gameprocessed() then return end
	if not HandlesKey then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		Keys[input.KeyCode] = true
		HandlesKey(input.KeyCode)
	end
	
end)

UIS.InputChanged:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		MouseMoved(input)
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessedEvent)
	if not HandlesKey then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		Keys[input.KeyCode] = nil
		HandlesKey(nil)
	end
end)


local Character = nil
local HeadGyro = nil

local LegHeight = 0

local CameraRotation = Vector3.new(0,0,0)

-- in a table to force passing value by pointer when CameraRotation is returned later on in the module. if it is not in a table, then it returns a permanent unchanging Vector3.new(0,0,0)
local CMR = {CameraRotation}


function MouseMoved(input)
	if not Character then
		return
	end
	
	if not is_gameprocessed() then
		
		local sensitivity = 0.6
		local smoothness = 0.05
		
		local delta = Vector2.new(input.Delta.x/sensitivity, input.Delta.y/sensitivity) * -smoothness
		
		
		CameraRotation = Vector3.new(math.clamp(CameraRotation.X + delta.y, -90, 90), CameraRotation.Y + delta.x, CameraRotation.Z)
		
		CMR[1] = CameraRotation
		
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end





local eyeLevel = 1.59625
local ColliderSize = 0.5


local disabled = false

-- Settings module doesn't actually work or do anything meaningful yet
local Settings = require(game.ReplicatedStorage.LocalModules.Settings)



function reset_localcharacter()
	-- our actual localcharacter
	local LocalCharacter = {
		Base = {
			xVel = 0,
			yVel = 0,
			zVel = 0, --all of this could be a Vector3, however since ROBLOX Lua does not support assigning a number to one axis directly we just separate all of this
			xPos = 0,
			yPos = 0,
			zPos = 0,
			
			eyePos = Vector3.new()
		},
		
		Animate = { --animation variables
			BobbingHor = 0,
			BobbingVer = 0,
			WalkTimeO = 0,
			WalkTimeN = 0,
			SwingO = 0,
			SwingN = 0,
			
			WalkTime = 0,
			Swing = 0,
			
			BobStrengthO = 0,
			BobStrengthN = 0,
			BobStrength = 0,
			
			OldPosX = 0,
			OldPosZ = 0,
			
			distance = 0,
			wd = 0
			
		},
		
		Physics = {
			OnGround = false,
			Jumping = false,
			MultiJumps = 0,
			CanLiquidJump = false,
			UseLiquidGravity = Settings.get("UseLiquidGravity"),
			JumpVel = Settings.get("JumpVel"),
			
			HitXMin = false,
			HitYMin = false,
			HitZMin = false,
			HitXMax = false,
			HitYMax = false,
			HitZMax = false,
			StepSize = Settings.get("StepSize")
		},
		Hacks = {
			Speeding = false,
			HalfSpeeding = false,
			CanSpeed = Settings.get("CanSpeed"),
			FlyingUp = false,
			FlyingDown = false,
			Floating = false,
			CanBePushed = false,
			NoclipSlide = false,
			Noclip = false,
			CanDoubleJump = Settings.get("CanDoubleJump"),
			WOMStyleHacks = Settings.get("WOMStyleHacks"),
			BaseHorSpeed = Settings.get("BaseHorSpeed"),
			SpeedMultiplier = Settings.get("SpeedMultiplier"),
			Flying = false,
			MaxJumps = Settings.get("MaxJumps"),
			CanNoclip = Settings.get("CanNoclip"),
			ThirdPersonMode = 0,
			CanFly = Settings.get("CanFly")
		},
		Model = {
			Gravity = 0.08,
			Drag = Vector3.new(0.91, 0.98, 0.91),
			GroundFriction = Vector3.new(0.6, 1.0, 0.6)
		},
		Tilt = {
			TiltX = 0,
			TiltY = 0,
			VelTiltStrength = 1.0,
			VelTiltStrengthO = 1.0,
			VelTiltStrengthN = 1.0
		},
		
		LocalEntity = LocalEntity
	}
	
	-- now we handle when a value is changed in Settings
	local these = {
		UseLiquidGravity = LocalCharacter.Physics,
		JumpVel = LocalCharacter.Physics,
		StepSize = LocalCharacter.Physics,
		
		CanSpeed = LocalCharacter.Hacks,
		CanDoubleJump = LocalCharacter.Hacks,
		WOMStyleHacks = LocalCharacter.Hacks,
		BaseHorSpeed = LocalCharacter.Hacks,
		SpeedMultiplier = LocalCharacter.Hacks,
		MaxJumps = LocalCharacter.Hacks,
		CanNoclip = LocalCharacter.Hacks,
		CanFly = LocalCharacter.Hacks
	}
	
	local function onChanged(val, idx)
		these[idx][idx] = val
	end
	
	for key, _ in pairs(these) do
		Settings.on_changed(key, onChanged)
	end
	
	return LocalCharacter
end


local LocalCharacter = reset_localcharacter()

-- makes our character model visible or not
function vis_char(bool)
	for k, v in pairs(Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.LocalTransparencyModifier = bool and 0 or 1
		elseif v:IsA("Texture") then
			v.Transparency = bool and 0 or 1
		end
	end
end


-- oh god
local mod = require(script.Collisions)(AABB, LocalCharacter, world, Blocks)
local Collisions_MoveAndWallSlide, IVec3_Ceil, IVec3_Floor, SolidBlock, blockToBB, GetEntityBB, Entity_TouchesAnyLava, Entity_TouchesAnyWater, Entity_TouchesAny, PhysicsComp_TouchesLiquid, IsSolid = unpack(mod)



local timeSinceJump = 0

local Spawn = game.ReplicatedStorage.Remote.GetSpawn:InvokeServer()
local SpawnOrt = Vector3.new(0, 0, 0)


local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5
local Gas = 6
local function isIgnored(blk)
	return blk == 0 or (Blocks[blk].Solidity == Liquid) or (Blocks[blk].Solidity == Plant)
end

local function respawn()
	
	local thisSpawn = Spawn
	
	while(world.exists(thisSpawn.X, thisSpawn.Y, thisSpawn.Z)) do
		if (not isIgnored(world.get(thisSpawn.X, thisSpawn.Y, thisSpawn.Z))) or (not isIgnored(world.get(thisSpawn.X, thisSpawn.Y + 1, thisSpawn.Z))) then
			thisSpawn = thisSpawn + Vector3int16.new(0, 1, 0)
		else
			break
		end
	end
	
	LocalCharacter.Base.xPos = thisSpawn.X
	LocalCharacter.Base.yPos = thisSpawn.Y
	LocalCharacter.Base.zPos = thisSpawn.Z
	LocalCharacter.Base.xVel = 0
	LocalCharacter.Base.yVel = 0
	LocalCharacter.Base.zVel = 0
	
	CameraRotation = SpawnOrt
end

function HandlesKey(key)
	if key == KEYBIND_RESPAWN then
		-- handlerespawn
		--Character:SetPrimaryPartCFrame(Spawn)
		respawn()
	elseif key == KEYBIND_SET_SPAWN then
		-- setspawn
		Spawn = Vector3int16.new(math.floor(LocalCharacter.Base.xPos + 0.5), math.floor(LocalCharacter.Base.yPos + 0.5), math.floor(LocalCharacter.Base.zPos + 0.5))
		SpawnOrt = CameraRotation
		LocalCharacter.Base.xVel = 0
		LocalCharacter.Base.yVel = 0
		LocalCharacter.Base.zVel = 0
		
		respawn()
	elseif key == KEYBIND_FLY then
		-- handlefly
		LocalCharacter.Hacks.Flying = (not LocalCharacter.Hacks.Flying) and LocalCharacter.Hacks.CanFly
	elseif key == KEYBIND_NOCLIP then
		-- handlenoclip
		if LocalCharacter.Hacks.WOMStyleHacks then
			return
		end
		if LocalCharacter.Hacks.Noclip then
			LocalCharacter.Base.yVel = 0
		end
		LocalCharacter.Hacks.Noclip = (not LocalCharacter.Hacks.Noclip) and LocalCharacter.Hacks.CanNoclip
	elseif key == KEYBIND_JUMP and (not LocalCharacter.Physics.OnGround) and not (LocalCharacter.Hacks.Noclip or LocalCharacter.Hacks.Flying) then
		local maxJumps = LocalCharacter.Hacks.CanDoubleJump and LocalCharacter.Hacks.WOMStyleHacks and 2 or 0
		maxJumps = math.max(maxJumps, LocalCharacter.Hacks.MaxJumps - 1)
		
		if (LocalCharacter.Physics.MultiJumps < maxJumps) then
			DoNormalJump()
			LocalCharacter.Physics.MultiJumps = LocalCharacter.Physics.MultiJumps + 1
		end
	elseif key == KEYBIND_TPS then
		LocalCharacter.Hacks.ThirdPersonMode = (LocalCharacter.Hacks.ThirdPersonMode + 1) % 3
		vis_char(not(LocalCharacter.Hacks.ThirdPersonMode == 0))
	end
	
	-- Comment system has been removed
	--[[
	if not LocalCharacter.Hacks.WOMStyleHacks then
		wait() --wait 2 frames for HandleInput to handle input
		local Comment = {}
		if LocalCharacter.Hacks.Flying then
			table.insert(Comment, "Fly ON")
		end
		if LocalCharacter.Hacks.CanNoclip and LocalCharacter.Hacks.Noclip then
			table.insert(Comment, "Noclip ON")
		end
		if LocalCharacter.Hacks.CanSpeed and (LocalCharacter.Hacks.Speeding or LocalCharacter.Hacks.HalfSpeeding) then
			table.insert(Comment, "Speed ON")
		end
		Comment = table.concat(Comment, "        ")
		game.ReplicatedStorage.LocalEvents.SetComment:Fire(Comment)
	end
	]]
	
end

function HandleInput()
	local xMoving, zMoving = 0, 0
	if Keys[KEYBIND_LEFT] then
		xMoving = xMoving - MoveSpeed
	end
	if Keys[KEYBIND_RIGHT] then
		xMoving = xMoving + MoveSpeed
	end
	
	if Keys[KEYBIND_BACK] then
		zMoving = zMoving - MoveSpeed
	end
	if Keys[KEYBIND_FORWARD] then
		zMoving = zMoving + MoveSpeed
	end
	
	LocalCharacter.Hacks.Speeding = Keys[KEYBIND_SPEED] == true
	LocalCharacter.Hacks.HalfSpeeding = Keys[KEYBIND_HALF_SPEED] == true
	
	LocalCharacter.Physics.Jumping = Keys[KEYBIND_JUMP] == true
	
	LocalCharacter.Hacks.FlyingUp = Keys[KEYBIND_FLY_UP] == true
	LocalCharacter.Hacks.FlyingDown = Keys[KEYBIND_FLY_DOWN] == true
	
	if LocalCharacter.Hacks.WOMStyleHacks and LocalCharacter.Hacks.CanNoclip then
		if LocalCharacter.Hacks.Noclip then
			LocalCharacter.Base.xVel = 0
			LocalCharacter.Base.yVel = 0
			LocalCharacter.Base.zVel = 0
		end
		LocalCharacter.Hacks.Noclip = Keys[KEYBIND_NOCLIP] == true
	end
	
	return xMoving, zMoving
end

function PhysicsGetSpeed(speedMul)
	local factor = LocalCharacter.Hacks.Floating and speedMul or 1.0
	local speed = factor
	if LocalCharacter.Hacks.Speeding and LocalCharacter.Hacks.CanSpeed then
		speed = speed + (factor * LocalCharacter.Hacks.SpeedMultiplier)
	end
	if LocalCharacter.Hacks.HalfSpeeding and LocalCharacter.Hacks.CanSpeed then
		speed = speed + (factor * LocalCharacter.Hacks.SpeedMultiplier/2)
	end
	return LocalCharacter.Hacks.CanSpeed and speed or math.min(speed, 1.0)
end

local Liquid = 2

local prevUseLiquidGravity = false

function PhysicsComp_LowestModifier(bounds, checkSolid)
	local bbMin = IVec3_Floor(bounds.Start)
	local bbMax = IVec3_Ceil(bounds.End)
	local modifier = math.huge
	
	bbMin = Vector3.new(
		math.max(bbMin.X, 0),
		math.max(bbMin.Y, 0),
		math.max(bbMin.Z, 0)
	)
	
	bbMax = Vector3.new(
		math.min(bbMax.X, world.size.X-1),
		math.min(bbMax.Y, world.size.Y-1),
		math.min(bbMax.Z, world.size.Z-1)
	)
	
	for y = bbMin.Y, bbMax.Y do
		for z = bbMin.Z, bbMax.Z do
			for x = bbMin.X, bbMax.X do
				local block = world.get(x, y, z)
				
				if block ~= 0 then
					if not ((IsSolid(block)) and not checkSolid) then
						local blockBB = blockToBB(block, Vector3.new(x, y, z))
						if blockBB:Intersects(bounds) then
							modifier = math.min(modifier, Blocks[block].SpeedMultiplier or 1)
							if Blocks[block].Solidity == Liquid then
								LocalCharacter.Physics.UseLiquidGravity = true
							end
						end
					end
				end
			end
		end
	end
	return modifier
end

function PhysicsComp_YPosAt(t, u)
	local a = math.exp(-0.0202027 * t)
	return a * (-49 * u - 196) - 4 * t + 50 * u + 196
end
function PhysicsComp_CalcMaxHeight(u)
	local t = 49.49831645 * math.log(0.247483075 * u + 0.9899323)
	local value_floor = PhysicsComp_YPosAt(math.floor(t), u)
	local value_ceil = PhysicsComp_YPosAt(math.floor(t+1), u)
	return math.max(value_floor, value_ceil)
end
function PhysicsComp_CalcJumpVelocity(jumpHeight)
	local jumpVel = 0
	if jumpHeight == 0 then return jumpVel end
	if jumpHeight >= 256 then jumpVel = 10.0 end
	if jumpHeight >= 512 then jumpVel = 16.5 end
	if jumpHeight >= 768 then jumpVel = 22.5 end
	
	while (PhysicsComp_CalcMaxHeight(jumpVel) <= jumpHeight) do jumpVel = jumpVel + 0.001 end
	
	return jumpVel
end

function PhysicsGetBaseSpeed()
	local entityBB = GetEntityBB()
	LocalCharacter.Physics.UseLiquidGravity = false
	
	local baseModifier = PhysicsComp_LowestModifier(entityBB, false)
	entityBB:SetMin(entityBB.Start - Vector3.new(0, 0.5/16, 0))
	local solidModifier = PhysicsComp_LowestModifier(entityBB, true)
	
	if baseModifier == math.huge and solidModifier == math.huge then return 1.0 end
	return baseModifier == math.huge and solidModifier or baseModifier
end



function MoveHor(vel, factor)
	local dist = math.sqrt(vel.X * vel.X + vel.Z * vel.Z)
	if dist < 0.00001 then return end
	if dist < 1.0 then dist = 1.0 end
	LocalCharacter.Base.xVel = LocalCharacter.Base.xVel + vel.X * (factor / dist)
	LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + vel.Y * (factor / dist)
	LocalCharacter.Base.zVel = LocalCharacter.Base.zVel + vel.Z * (factor / dist)
end

function Move(drag, gravity, yMul)
	debug.profilebegin("move")
	
	LocalCharacter.Base.yVel = LocalCharacter.Base.yVel * yMul
	if not LocalCharacter.Hacks.Noclip then
		Collisions_MoveAndWallSlide()
	end
	debug.profilebegin("resets")
	LocalCharacter.Base.xPos = LocalCharacter.Base.xPos + LocalCharacter.Base.xVel
	LocalCharacter.Base.yPos = LocalCharacter.Base.yPos + LocalCharacter.Base.yVel
	LocalCharacter.Base.zPos = LocalCharacter.Base.zPos + LocalCharacter.Base.zVel
	
	LocalCharacter.Base.yVel = LocalCharacter.Base.yVel / yMul
	
	LocalCharacter.Base.xVel = LocalCharacter.Base.xVel * drag.X
	LocalCharacter.Base.yVel = LocalCharacter.Base.yVel * drag.Y
	LocalCharacter.Base.zVel = LocalCharacter.Base.zVel * drag.Z
	
	LocalCharacter.Base.yVel = LocalCharacter.Base.yVel - gravity
	debug.profileend()
	debug.profileend()
end

function MoveFlying(vel, factor, drag, gravity, yMul)
	MoveHor(vel, factor)
	local yVel = math.sqrt(LocalCharacter.Base.xVel * LocalCharacter.Base.xVel + LocalCharacter.Base.zVel * LocalCharacter.Base.zVel)
	
	if ((vel.X ~= 0 or vel.Y ~= 0) and (yVel > 0.001)) then
		LocalCharacter.Base.yVel = 0.0
		yMul = 1.0
		if LocalCharacter.Hacks.FlyingUp or LocalCharacter.Physics.Jumping then
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + yVel
		end
		if LocalCharacter.Hacks.FlyingDown then
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel - yVel
		end
	end
	
	Move(drag, gravity, yMul)
end

function MoveNormal(vel, factor, drag, gravity, yMul)
	MoveHor(vel, factor)
	Move(drag, gravity, yMul)
end

local LIQUID_GRAVITY = 0.02

function PhysicsTick(vel)
	if LocalCharacter.Hacks.Noclip then
		LocalCharacter.Physics.OnGround = false
	end
	
	debug.profilebegin("basespeed")
	local baseSpeed = PhysicsGetBaseSpeed()
	local verSpeed = baseSpeed * (PhysicsGetSpeed(8.0) / 5.0)
	local horSpeed = baseSpeed * (PhysicsGetSpeed(8.0 / 5.0)) * LocalCharacter.Hacks.BaseHorSpeed
	
	math.clamp(horSpeed, -75, 75)
	
	if (verSpeed < baseSpeed) then
		verSpeed = baseSpeed
	end
	debug.profileend()
	
	debug.profilebegin("checks")
	local womSpeedBoost = LocalCharacter.Hacks.CanDoubleJump and LocalCharacter.Hacks.WOMStyleHacks
	if ((not LocalCharacter.Hacks.Floating) and womSpeedBoost) then
		if LocalCharacter.Physics.MultiJumps == 1 then
			horSpeed = horSpeed * 46.5
			verSpeed = verSpeed * 7.5
		elseif LocalCharacter.Physics.MultiJumps > 1 then
			horSpeed = horSpeed * 93.0
			verSpeed = verSpeed * 10.0
		end
	end
	debug.profileend()
	
	
	debug.profilebegin("moves")
	if(Entity_TouchesAnyWater() and not LocalCharacter.Hacks.Floating) then
		local waterdrag = Vector3.new(0.8, 0.8, 0.8)
		MoveNormal(vel, 0.02*horSpeed, waterdrag, LIQUID_GRAVITY, verSpeed)
	elseif (Entity_TouchesAnyLava() and not LocalCharacter.Hacks.Floating) then
		local lavadrag = Vector3.new(0.5, 0.5, 0.5)
		MoveNormal(vel, 0.02*horSpeed, lavadrag, LIQUID_GRAVITY, verSpeed)
	elseif (false) then
		--TouchesAnyRope
	else
		local factor = (LocalCharacter.Hacks.Floating or LocalCharacter.Physics.OnGround) and 0.1 or 0.02
		local gravity = LocalCharacter.Physics.UseLiquidGravity and LIQUID_GRAVITY or LocalCharacter.Model.Gravity
		
		if LocalCharacter.Hacks.Floating then
			--MoveFlying
			MoveFlying(vel, factor * horSpeed, LocalCharacter.Model.Drag, gravity, verSpeed)
		else
			--MoveNormal
			MoveNormal(vel, factor * horSpeed, LocalCharacter.Model.Drag, gravity, verSpeed)
		end
		
		if (false and not LocalCharacter.Hacks.Floating) then --OnIce
			if (math.abs(LocalCharacter.Base.xVel) > 0.25) or (math.abs(LocalCharacter.Base.zVel) > 0.25) then
				local xScale = math.abs(0.25 / LocalCharacter.Base.xVel)
				local zScale = math.abs(0.25 / LocalCharacter.Base.zVel)
				
				local scale = math.min(xScale, zScale)
				LocalCharacter.Base.xVel = LocalCharacter.Base.xVel * scale
				LocalCharacter.Base.zVel = LocalCharacter.Base.zVel * scale
			end
		elseif LocalCharacter.Physics.OnGround or LocalCharacter.Hacks.Flying then
			LocalCharacter.Base.xVel = LocalCharacter.Base.xVel * LocalCharacter.Model.GroundFriction.X
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel * LocalCharacter.Model.GroundFriction.Y
			LocalCharacter.Base.zVel = LocalCharacter.Base.zVel * LocalCharacter.Model.GroundFriction.Z
		end
	end
	debug.profileend()
	
	if LocalCharacter.Physics.OnGround then
		LocalCharacter.Physics.MultiJumps = 0
	end
end

local Game_ViewBobbing = true


-- this function actually updates everything and moves character not limbs
function AnimateUpdateLimbs(dt)
	local lla, rra, lle, rre = CFrame.new(), CFrame.new(), CFrame.new(), CFrame.new()
	local oldVelocityY = 0
	
	local dt = game:GetService("RunService").RenderStepped:wait()
	local swing = 0
	local max = 3
	if max < 1 then
		max = 1
	end
	
	local i = 0
	
	local waited = 0
	
	local base
	local oldPos = Vector3.new()
	local anim = LocalCharacter.Animate
	
	local function copy_base()
		base = {
			xPos = LocalCharacter.Base.xPos,
			yPos = LocalCharacter.Base.yPos,
			zPos = LocalCharacter.Base.zPos,
			
			xVel = LocalCharacter.Base.xVel,
			yVel = LocalCharacter.Base.yVel,
			zVel = LocalCharacter.Base.zVel
		}
	end
	
	copy_base()
	
	local waited_rep = 0
	
	local function onRender(dt)
		i = i + 1
		waited = waited + dt
		waited_rep = waited_rep + dt
		if waited >= 1/20 then
			Tick(waited)
			waited = 0
			i = 1
		end
		
		if waited_rep >= 1/5 then
			waited_rep = 0
			game.ReplicatedStorage.Remote.NetworkCharacter.update:FireServer(base.xPos, base.yPos, base.zPos, CameraRotation.X, CameraRotation.Y)
		end
		
		if i == 1 then
			oldPos = Vector3.new(base.xPos, base.yPos, base.zPos)
			copy_base()
		end
		
		do
			-- position stuff
			
			--local oldPos = Vector3.new(oldbase.xPos, oldbase.yPos, oldbase.zPos)
			local newPos = Vector3.new(base.xPos, base.yPos, base.zPos)
			
			local tgtPos = Vector3.new()
			
			
			if LocalCharacter.Hacks.Noclip then
				tgtPos = newPos
			else
				tgtPos = oldPos:Lerp(newPos, i/max)
			end
			
			if base.xVel == 0 then
				tgtPos = tgtPos * Vector3.new(0, 1, 1) + newPos * Vector3.new(1, 0, 0)
			end
			if base.yVel == 0 then
				tgtPos = tgtPos * Vector3.new(1, 0, 1) + newPos * Vector3.new(0, 1, 0)
			end
			if base.zVel == 0 then
				tgtPos = tgtPos * Vector3.new(1, 1, 0) + newPos * Vector3.new(0, 0, 1)
			end
			
			
			
			
			
			LocalEntity:set_position(tgtPos, newPos)
			LocalEntity:set_orientation(Vector3.new(CameraRotation.X, CameraRotation.Y, 0))
			
			
			
			-- animate stuff
			-- (moved to entity)

			
			-- tick char
			
			LocalEntity:tick(dt*3)
			
			
			
			-- camera stuff
			
			TiltComp_GetCurrent(i/max)
			
			if LocalCharacter.Physics.OnGround and (anim.distance > 0.05) then
				local walkDelta = anim.distance * 2 * (20 * dt)
				anim.wd = (anim.wd or 0) + walkDelta
			end
			swing = lerp(swing, anim.SwingN, i/max)
			
			vals.BobbingHor = 0
			vals.BobbingVer = 0
			
			LocalCharacter.Base.eyePos = tgtPos + Vector3.new(0, eyeLevel, 0)
			
			if LocalCharacter.Hacks.ThirdPersonMode == 0 then
				
					anim.BobbingHor = math.cos(anim.wd) * swing * (2.5/16)
					anim.BobbingVer = math.abs(math.sin(anim.wd)) * swing * (2.5/16)
					
					local BobbingHor = (anim.BobbingHor * 0.3) * 1.0
					local BobbingVer = (anim.BobbingVer * 0.6) * 1.0
					
					vals.BobbingHor = BobbingHor
					vals.BobbingVer = BobbingVer
				
				local vel = lerp(oldVelocityY + 0.08, base.yVel + 0.08, i/max)
				oldVelocityY = base.yVel				
				local bobbing = CFrame.new(BobbingHor, BobbingVer, 0)  * CFrame.Angles(0, 0, LocalCharacter.Tilt.TiltX * 1.0) * CFrame.Angles(math.abs(LocalCharacter.Tilt.TiltY) * 3.0 * 1, 0, 0) * CFrame.Angles(math.rad(vel*math.pi),0,0)
				vals.jumpoffset = CFrame.Angles(math.rad(vel*math.pi),0,0)

				workspace.CurrentCamera.CFrame = CFrame.new(LocalCharacter.Base.eyePos) * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(CameraRotation.Y)) * CFrame.fromAxisAngle(Vector3.new(1, 0, 0), math.rad(CameraRotation.X)) * bobbing
			else
				
				vals.BobbingHor = 0
				vals.BobbingVer = 0
				vals.jumpoffset = 0
				
				local Mult = (LocalCharacter.Hacks.ThirdPersonMode == 1) and 1 or -1
				workspace.CurrentCamera.CFrame = CFrame.new(CFrame.new(
					(CFrame.new(LocalCharacter.Base.eyePos) *
						CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(CameraRotation.Y)) *
						CFrame.fromAxisAngle(Vector3.new(1, 0, 0), math.rad(CameraRotation.X)) *
						CFrame.new(0, 0, 4 * Mult)
					).p,
					
					LocalCharacter.Base.eyePos
					
				).p) * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(CameraRotation.Y + (Mult == -1 and 180 or 0))) * CFrame.fromAxisAngle(Vector3.new(1, 0, 0), math.rad(CameraRotation.X * Mult))
				-- turn the cframe into .p and back into cframe because CFrame.new(v31, v32) breaks when rotation is over ~85 degrees, but we allow camera rotation of up to 90 degrees
			end
			
		end
		
		if i == 3 then
			i = 0
		end
	end
	
	game:GetService("RunService"):BindToRenderStep("localchar", Enum.RenderPriority.Camera.Value+1, onRender)
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function DoTilt(n, reduce)
	if reduce then
		n = n * 0.84
	else
		n = n + 0.1
	end
	return math.clamp(n, 0, 1)
end

function AnimateTick(dt)
	local anim = LocalCharacter.Animate

	anim.BobStrengthO = anim.BobStrengthN
	for i=1, 3 do
		anim.BobStrengthN = DoTilt(anim.BobStrengthO, (not Game_ViewBobbing) or (not LocalCharacter.Physics.OnGround))
	end
	
	LocalCharacter.Tilt.VelTiltStrengthO = LocalCharacter.Tilt.VelTiltStrengthN
	for i=1, 3 do
		LocalCharacter.Tilt.VelTiltStrengthN = DoTilt(LocalCharacter.Tilt.VelTiltStrengthO, LocalCharacter.Hacks.Floating)
	end
	
	
	anim.WalkTimeO = anim.WalkTimeN
	anim.SwingO = anim.SwingN
	
	local dx = LocalCharacter.Base.xPos - anim.OldPosX
	local dz = LocalCharacter.Base.zPos - anim.OldPosZ
	
	local distance = math.sqrt(dx * dx + dz * dz) or 0
	
	anim.distance = distance
	
	if (distance > 0.05) and LocalCharacter.Physics.OnGround then
		local walkDelta = distance * 2 * (20*dt)
		anim.WalkTimeN = anim.WalkTimeN + walkDelta
		anim.SwingN = anim.SwingN + (dt * 3)
		
	else
		anim.SwingN = anim.SwingN - (dt * 3)
	end
	
	anim.OldPosX = LocalCharacter.Base.xPos
	anim.OldPosZ = LocalCharacter.Base.zPos
	
	
	
	anim.SwingN = math.clamp(anim.SwingN, 0.0, 1.0)
	
	--AnimateUpdateLimbs()
end

function AnimatedComp_GetCurrent(t)
	LocalCharacter.Animate.Swing = lerp(LocalCharacter.Animate.SwingO, LocalCharacter.Animate.SwingN, t)
	LocalCharacter.Animate.WalkTime = lerp(LocalCharacter.Animate.WalkTimeO, LocalCharacter.Animate.WalkTimeN, t)
	
end

function TiltComp_GetCurrent(t)
	AnimatedComp_GetCurrent(t)
	
	LocalCharacter.Tilt.VelTiltStrength = lerp(LocalCharacter.Tilt.VelTiltStrengthO, LocalCharacter.Tilt.VelTiltStrengthN, t)
	
	if not LocalCharacter.Physics.OnGround then
		LocalCharacter.Tilt.TiltX = 0
		LocalCharacter.Tilt.TiltY = 0
	else
		LocalCharacter.Tilt.TiltX = math.cos(LocalCharacter.Animate.wd) * LocalCharacter.Animate.Swing * (0.15 * math.rad(1))
		LocalCharacter.Tilt.TiltY = math.sin(LocalCharacter.Animate.wd) * LocalCharacter.Animate.Swing * (0.15 * math.rad(1))
	end
end

function Collisions_HitHorizontal()
	return
		LocalCharacter.Physics.HitZMax or LocalCharacter.Physics.HitZMin or
		LocalCharacter.Physics.HitXMax or LocalCharacter.Physics.HitXMin
end


function UpdateVelocityState()
	if LocalCharacter.Hacks.Floating then
		LocalCharacter.Base.yVel = 0
		local dir = (LocalCharacter.Hacks.FlyingUp or LocalCharacter.Physics.Jumping) and 1 or (LocalCharacter.Hacks.FlyingDown and -1 or 0)
		
		LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.12 * dir
		
		if LocalCharacter.Hacks.Speeding and LocalCharacter.Hacks.CanSpeed then
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.12 * dir
		end
		if LocalCharacter.Hacks.HalfSpeeding and LocalCharacter.Hacks.CanSpeed then
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.06 * dir
		end
	elseif (false) then --touchesanyrope
		
	end
	
	if not LocalCharacter.Physics.Jumping then 
		LocalCharacter.Physics.CanLiquidJump = false
		return
	end
	
	local touchWater = Entity_TouchesAnyWater()
	local touchLava = Entity_TouchesAnyLava()
	

	
	if touchWater or touchLava then
		local bounds = GetEntityBB()
		local feetY = math.floor(bounds.Start.Y)
		local bodyY = feetY + 1
		local headY = math.floor(bounds.End.Y)
		if bodyY > headY then
			bodyY = headY
		end
		
		bounds:SetMax(Vector3.new(0, feetY+0.01, 0), Vector3.new(0,1,0))
		bounds:SetMin(Vector3.new(0, feetY-0.01, 0), Vector3.new(0,1,0))
		
		local liquidFeet = Entity_TouchesAny(bounds, PhysicsComp_TouchesLiquid)
		
		bounds:SetMin(Vector3.new(0, math.min(bodyY, headY), 0), Vector3.new(0,1,0))
		bounds:SetMax(Vector3.new(0, math.max(bodyY, headY), 0), Vector3.new(0,1,0))

		local liquidRest = Entity_TouchesAny(bounds, PhysicsComp_TouchesLiquid)

		
		local pastJumpPoint = liquidFeet and (not liquidRest) --and (math.fmod(LocalCharacter.Base.yPos, 1) >= 0.4)
		
		if not pastJumpPoint then
			LocalCharacter.Physics.CanLiquidJump = true
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.04
			if LocalCharacter.Hacks.Speeding and LocalCharacter.Hacks.CanSpeed then
				LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.04
			end
			if LocalCharacter.Hacks.HalfSpeeding and LocalCharacter.Hacks.CanSpeed then
				LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.02
			end
		elseif pastJumpPoint then
			if Collisions_HitHorizontal() then
				LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + (touchLava and 0.30 or 0.13)
			elseif LocalCharacter.Physics.CanLiquidJump then
				LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + (touchLava and 0.20 or 0.10)
			end
			LocalCharacter.Physics.CanLiquidJump = false
		end
		
	elseif LocalCharacter.Physics.UseLiquidGravity then
			LocalCharacter.Physics.CanLiquidJump = false
			LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.04
			if LocalCharacter.Hacks.Speeding and LocalCharacter.Hacks.CanSpeed then
				LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.04
			end
			if LocalCharacter.Hacks.HalfSpeeding and LocalCharacter.Hacks.CanSpeed then
				LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + 0.02
			end
	elseif false then --TouchesAnyRope
		
	elseif LocalCharacter.Physics.OnGround then
		DoNormalJump()
	end
end

function DoNormalJump()
	if LocalCharacter.Physics.JumpVel == 0 or LocalCharacter.Hacks.MaxJumps <= 0 then
		return
	end
	
	LocalCharacter.Base.yVel = LocalCharacter.Physics.JumpVel
	if LocalCharacter.Hacks.Speeding and LocalCharacter.Hacks.CanSpeed then
		LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + LocalCharacter.Physics.JumpVel
	end
	if LocalCharacter.Hacks.HalfSpeeding and LocalCharacter.Hacks.CanSpeed then
		LocalCharacter.Base.yVel = LocalCharacter.Base.yVel + LocalCharacter.Physics.JumpVel / 2
	end
	LocalCharacter.Physics.CanLiquidJump = false
end

game.ReplicatedStorage.LocalEvents.STOP.Event:Connect(function()
	LocalCharacter.Base.yVel = 0
end)

local pTouchWater = false

function Tick(dt)
	
	
	if not disabled then
	
	debug.profilebegin("tick")
	
	local xMoving, zMoving = HandleInput()
	
	LocalCharacter.Hacks.Floating = LocalCharacter.Hacks.Noclip or (LocalCharacter.Hacks.Flying and LocalCharacter.Hacks.CanFly)
	
	if (not LocalCharacter.Hacks.Floating) and LocalCharacter.Hacks.CanBePushed then
		-- push
	end
	
	if ((not LocalCharacter.Hacks.NoclipSlide) and (LocalCharacter.Hacks.Noclip and xMoving == 0 and zMoving == 0)) then
		LocalCharacter.Base.xVel = 0
		LocalCharacter.Base.yVel = 0
		LocalCharacter.Base.zVel = 0
	end
	
	
	debug.profilebegin("updatevelocity")
	UpdateVelocityState()
	debug.profileend()
	


	local LV = CFrame.new() * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(CameraRotation.Y))
	local HeadingVelocity = (LV.LookVector * zMoving) + (LV.RightVector * xMoving)
	debug.profilebegin("physicstick")
	PhysicsTick(HeadingVelocity)
	debug.profileend()

	
	debug.profileend()
	
	end
	
	debug.profilebegin("animatetick")
	AnimateTick(dt)
	debug.profileend()
end

function SetJumpHeight(height)
	LocalCharacter.Physics.JumpVel = PhysicsComp_CalcJumpVelocity(height)
end

function main()
	while not world.array do wait() end
	LocalEntity = entityClass.new(game.Players.LocalPlayer.Name, -1)
	LocalEntity:set_model("humanoid")
	LocalEntity:show_nametag(false)
	LocalEntity:init(false)
	LocalCharacter.LocalEntity = LocalEntity
	Character = LocalEntity.model
	vis_char(false)
	SetJumpHeight(1.233)
	LegHeight = Character:WaitForChild("RLeg").Size.Y
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		LocalCharacter.Base.xPos = Spawn.X
		LocalCharacter.Base.yPos = Spawn.Y
		LocalCharacter.Base.zPos = Spawn.Z
		LocalCharacter.Base.xVel = 0
		LocalCharacter.Base.yVel = 0
		LocalCharacter.Base.zVel = 0
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	spawn(function()
		AnimateUpdateLimbs()
	end)
end

game.ReplicatedStorage.Remote.OnSetPosition.OnClientEvent:Connect(function(x, y, z, pitch, yaw)
	
	LocalCharacter.Base.xPos = x or LocalCharacter.Base.xPos
	LocalCharacter.Base.yPos = y or LocalCharacter.Base.yPos
	LocalCharacter.Base.zPos = z or LocalCharacter.Base.zPos
	
	CameraRotation = Vector3.new(pitch or CameraRotation.X, yaw or CameraRotation.Y, 0)
	
end)

return {
	init = main,
	LocalCharacter = LocalCharacter,
	CameraRotation = CMR
}