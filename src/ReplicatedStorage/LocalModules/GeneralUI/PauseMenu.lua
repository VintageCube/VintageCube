local PauseMenu = {}

function PauseMenu.on_esc()
	PauseMenu.UI.Enabled = not PauseMenu.UI.Enabled
	if PauseMenu.UI.Enabled then
		PauseMenu.Lock()
	else
		wait()
		PauseMenu.Unlock()
	end
end

function PauseMenu.init(lockfunc, unlockfunc, generators)
	PauseMenu.Lock = lockfunc
	PauseMenu.Unlock = unlockfunc
	PauseMenu.UI = generators.ScreenGui("PauseMenu", 999)
	PauseMenu.UI.Enabled = false
	
	PauseMenu.Overlay = Instance.new("ImageLabel")
	PauseMenu.Overlay.Size = UDim2.new(1,0,1,0)
	PauseMenu.Overlay.BackgroundTransparency = 1
	PauseMenu.Overlay.Image = generators.Back
	PauseMenu.Overlay.Parent = PauseMenu.UI
	
	PauseMenu.ResumeBtn = generators.Button("Back to game", PauseMenu.on_esc)
	PauseMenu.ResumeBtn.AnchorPoint = Vector2.new(0.5, 1)
	PauseMenu.ResumeBtn.Position = UDim2.new(0.5, 0, 1, -25)
	PauseMenu.ResumeBtn.Parent = PauseMenu.Overlay
	
	local buttons = {
		"Options...",
		"Generate new level...",
		"Load level...",
		"Save level..."
	}
	
	PauseMenu.CenterBtns = generators.CenterHolderFrame(generators.BtnSizeX, #buttons*generators.BtnSizeY + (#buttons-1)*generators.BtnPadding )
	
	PauseMenu.CenterBtns.Position = UDim2.new(0.5, 0, 0.5, -(generators.BtnSizeY/2 + generators.BtnPadding/2))
	
	PauseMenu.Buttons = {}
	for k, v in pairs(buttons) do
		local btn = generators.Button(v, function() end, true)
		btn.Position = UDim2.new(0, 0, 0, (k-1)*generators.BtnSizeY + (k-1)*generators.BtnPadding)
		btn.Parent = PauseMenu.CenterBtns
	end
	
	PauseMenu.CenterBtns.Parent = PauseMenu.UI
	
	PauseMenu.UI.Parent = game.Players.LocalPlayer.PlayerGui
end

return PauseMenu
