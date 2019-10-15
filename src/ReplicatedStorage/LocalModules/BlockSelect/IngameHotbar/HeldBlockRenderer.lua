--[[
	Held block renderer
	
]]

local generator = require(game.ReplicatedStorage.LocalModules.BlockGen)
local vals = require(game.ReplicatedStorage.LocalModules.CharValue)
local blocks = require(game.ReplicatedStorage.LocalModules.Blocks)




local renderer = {}

local SolidBlock = 1
local Liquid = 2
local Transparent = 3
local TransparentInside = 4
local Plant = 5
local Gas = 6

renderer.HeldBlock = nil
renderer.Sprite = false
renderer.BaseOffset = Vector3.new(0,0,0)

local normal_offset = CFrame.new(0.56, -0.52, -0.72)
local sprite_offset = CFrame.new(0.46, -0.52+0.2, -0.72)

local breakTimer = 0
local breakAnimTicks = 7
local applyBreakAnim = false

local startAnim = false
local elapsedTicksBreak = 0


local LocalCharacter = require(game.ReplicatedStorage.LocalModules.Characterize).LocalCharacter

game:GetService("RunService").RenderStepped:Connect(function(dt)
	
	local tgt_cf
	

	breakTimer = breakTimer + 20*dt
	if breakTimer >= breakAnimTicks then
		applyBreakAnim = false
		breakTimer = 0
	end
	
	if startAnim then
		startAnim = false
		breakTimer = 0
		applyBreakAnim = true
	end
	
	if LocalCharacter.Hacks.ThirdPersonMode == 0 then
		

			
		if renderer.HeldBlock then
			
			tgt_cf = (workspace.CurrentCamera.CFrame * vals.jumpoffset:inverse()) * (renderer.Sprite and sprite_offset or normal_offset) * CFrame.new(-vals.BobbingHor, -vals.BobbingVer, -vals.BobbingHor)
			local rot = CFrame.Angles(0, math.rad(45), 0)
			if applyBreakAnim then
				elapsedTicksBreak = breakTimer + dt
				local lerp = elapsedTicksBreak/breakAnimTicks
				local sinHalfCircle = math.sin(lerp * math.pi)
				local sqrtLerp = math.sqrt(lerp) * math.pi
				tgt_cf = tgt_cf * CFrame.new(-math.sin(sqrtLerp) * 0.4, math.sin(sqrtLerp * 2) * 0.2, -sinHalfCircle * 0.2)
				
				-- set held block position ???
				
				local sinHCW = math.sin(lerp*lerp*math.pi)
				tgt_cf = tgt_cf * CFrame.Angles(0, math.rad(math.sin(sqrtLerp) * 80), 0)
				tgt_cf = tgt_cf * CFrame.Angles(math.rad(-sinHCW*20), 0, 0)
			end
			tgt_cf = tgt_cf * rot
		end
	else
		tgt_cf = CFrame.new(-99999, 99999, -99999)
	end
	if(renderer.HeldBlock:IsA("Part")) then
		renderer.HeldBlock.CFrame = tgt_cf
	elseif (renderer.HeldBlock:IsA("Model")) then
		renderer.HeldBlock:SetPrimaryPartCFrame(tgt_cf)
	end
end)

function renderer.set(id)
	if renderer.HeldBlock then
		renderer.HeldBlock:Destroy()
	end
	renderer.HeldBlock = generator.CreateBlock(id, nil, false, Vector3.new(0,0,0))--thisBlock, Visibles, InViewportFrame, pos
	if renderer.HeldBlock:IsA("Part") then
		renderer.HeldBlock.Size = Vector3.new(0.4, 0.4, 0.4)

					for _, s in pairs(renderer.HeldBlock:GetChildren()) do
						if s:IsA("Texture") then
							s.StudsPerTileU = s.StudsPerTileU * 0.4
							s.StudsPerTileV = s.StudsPerTileV * 0.4
							
						end
					end
	elseif renderer.HeldBlock:IsA("Model") then
			for k, v in ipairs(renderer.HeldBlock:GetDescendants()) do
				if v:IsA("Part") then
					v.Size = v.Size * 0.4
					for _, s in pairs(v:GetChildren()) do
						if s:IsA("Texture") then
							s.StudsPerTileU = s.StudsPerTileU * 0.4
							s.StudsPerTileV = s.StudsPerTileV * 0.4
							
						end
					end
					
					
				end
			end
	end
	if blocks[id].Solidity == Plant then
		renderer.Sprite = true
	else
		renderer.Sprite = false
	end
	renderer.HeldBlock.Parent = workspace.CurrentCamera
end

game.ReplicatedStorage.LocalEvents.HBAnim.Event:Connect(function(t)
	if t == 0 then --break
		startAnim = true
	elseif t == 1 then --build
		startAnim = true
	end
end)


renderer.set(1)

return renderer
