local Settings = {}

Settings.vals = {
	UseLiquidGravity = false,
	JumpVel = 0.46,
	StepSize = 0.5,
	CanSpeed = true,
	CanDoubleJump = false,
	WOMStyleHacks = true,
	BaseHorSpeed = 1,
	SpeedMultiplier = 10,
	MaxJumps = 1,
	CanNoclip = true,
	CanFly = true,
	
	ReachDistance = 5
}

Settings.possible_vals = {
	UseLiquidGravity = {true, false},
	-- todo more
}

Settings.bounds = {}

function Settings.set(idx, value)
	Settings.vals[idx] = value
	if Settings.bounds[idx] then
		for _, update_func in pairs(Settings.bounds[idx]) do
			update_func(value, idx)
		end
	end
end

function Settings.get(idx)
	return Settings.vals[idx]
end

function Settings.on_changed(idx, func)
	if not Settings.bounds[idx] then
		Settings.bounds[idx] = {}
	end
	table.insert(Settings.bounds[idx], func)
end


local cycles = {
	8,
	24,
	--64,
	--128,
	2048
}

local curr_cycle = 1

game.ReplicatedStorage.LocalEvents.KeyDown.Event:Connect(function(input, gameproc)
	
	if gameproc then return end
	if input == Enum.KeyCode.F then
		curr_cycle = curr_cycle + 1
		if curr_cycle > #cycles then
			curr_cycle = 1
		end
		Settings.set("render_dist", cycles[curr_cycle])
	end
end)

return Settings
