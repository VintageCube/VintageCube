-- ui stuff

local GUI = {}

GUI.text_funcs = {}

GUI.esc_funcs = {}

GUI.gameproc_changed_funcs = {}

GUI.reg_esc_funcs = {}

GUI.text_change_funcs = {}

function GUI.on_text(text)
--	if not GUI.islocked() then return end
--	for _, text_changed_function in pairs(GUI.text_funcs) do
--		text_changed_function(text)
--	end
	if not GUI.islocked() then return end
	for _, event in pairs(GUI.text_change_funcs) do
		if event.is_active() then
			event.on_change_func(text)
		end
	end
end

function GUI.bind_text_label(is_active, on_change_func)
	table.insert(GUI.text_change_funcs, {is_active = is_active, on_change_func = on_change_func})
end

function GUI.clear_text()
	GUI.esc_capture_box.Text = ""
end

function GUI.get_text()
	
end

function GUI.on_esc()
	for _, t in pairs(GUI.reg_esc_funcs) do
		if t.is_active() then
			t.run()
			return
		end
	end
	for _, esc_function in pairs(GUI.esc_funcs) do
		esc_function()
	end
end

function GUI.on_gameproc_changed(to)
	for _, gameproc_changed_function in pairs(GUI.gameproc_changed_funcs) do
		gameproc_changed_function(to)
	end
end

function GUI.register_esc(is_active_func, run)
	table.insert(GUI.reg_esc_funcs, {is_active = is_active_func, run = run})
end

function GUI.tick_esc_capture()
	GUI.esc_capture_box:CaptureFocus()
end

-- esc capturing is a hack
function GUI.run_esc_capture()
	GUI.esc_capture = Instance.new("ScreenGui")
	GUI.esc_capture_box = Instance.new("TextBox")
	GUI.esc_capture_box.Position = UDim2.new(999, 0, 999, 0)
	GUI.esc_capture_box.ClearTextOnFocus = false
	GUI.esc_capture_box.FocusLost:Connect(function()
		GUI.esc_capture_box:CaptureFocus()
	end)
	GUI.esc_capture_box:GetPropertyChangedSignal("Text"):Connect(function()
		local new_txt = GUI.esc_capture_box.Text
		GUI.on_text(new_txt)
	end)
	
	spawn(function()
		while wait(1/20) do --check every tick if we lost focus because FocusLost doesn't always fire
			if not GUI.esc_capture_box:IsFocused() then
				GUI.esc_capture_box:CaptureFocus()
			end
		end
	end)
	
	GUI.esc_capture_box.Parent = GUI.esc_capture
	GUI.esc_capture.Parent = game.Players.LocalPlayer.PlayerGui
	GUI.esc_capture_box:CaptureFocus()
	
	
	game.ReplicatedStorage.LocalEvents.KeyDown.Event:Connect(function(key, gameproc)
		if key == Enum.KeyCode.Escape then
			GUI.on_esc()
		end
	end)
end

function GUI.islocked()
	return game.ReplicatedStorage.LocalEvents.gameproc.Value == true
end

function GUI.lock_gameproc()
	game.ReplicatedStorage.LocalEvents.gameproc.Value = true
	GUI.on_gameproc_changed(true)
end

function GUI.unlock_gameproc()
	game.ReplicatedStorage.LocalEvents.gameproc.Value = false
	game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
	GUI.on_gameproc_changed(false)
end

function GUI.init()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
	GUI.run_esc_capture()
	for k, v in ipairs(script:GetChildren()) do
		local module = require(v)
		
		module.init(GUI.lock_gameproc, GUI.unlock_gameproc, GUI.Generators)
		
		if module.on_text then
			table.insert(GUI.text_funcs, module.on_text)
		end
		
		if module.on_esc then
			table.insert(GUI.esc_funcs, module.on_esc)
		end
		
		if module.on_gameproc_changed then
			table.insert(GUI.gameproc_changed_funcs, module.on_gameproc_changed)
		end
		
		if module.on_uis then
			game.ReplicatedStorage.LocalEvents.KeyDown.Event:Connect(module.on_uis)
		end
		
		if module.on_uiu then
			game.ReplicatedStorage.LocalEvents.KeyUp.Event:Connect(module.on_uiu)
		end
	end
	
	-- preload stuff
	do
		local AssetsUsed = {}
		local function searchChildren(t)
			for k, v in pairs(t:GetDescendants()) do
				if v:IsA("ImageLabel") or v:IsA("ImageButton") then
					table.insert(AssetsUsed, v)
				end
			end
		end
		searchChildren(game.Players.LocalPlayer.PlayerGui)
		
		
		
		game:GetService("ContentProvider"):PreloadAsync(AssetsUsed)
	end
end


local fgen = require(game.ReplicatedStorage.LocalModules.FontGen)


GUI.Generators = {}


local hvimg = "http://www.roblox.com/asset/?id=3732228551"
local primg = "http://www.roblox.com/asset/?id=3732228133"
local stimg = "http://www.roblox.com/asset/?id=3732228982"
local slicecenter = Rect.new(4, 4, 396, 34)
function GUI.Generators.Button(text, onPress, disabled)
	local img = Instance.new("ImageButton")
	img.Image = disabled and primg or stimg
	--img.PressedImage = primg
	--img.HoverImage = hvimg
	img.ScaleType = Enum.ScaleType.Slice
	img.BorderSizePixel = 0
	img.SliceCenter = slicecenter
	
	img.Size = UDim2.new(0, 400, 0, 40)

	local textlabel = fgen.CreateTextLabel(text, Vector2.new(360, 36))
	textlabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textlabel.Position = UDim2.new(0.5, -1, 0.5, -1)
	textlabel.Parent = img
	
	local gtextlabel = fgen.CreateTextLabel("&s" .. text, Vector2.new(360, 36))
	gtextlabel.AnchorPoint = Vector2.new(0.5, 0.5)
	gtextlabel.Position = UDim2.new(0.5, -1, 0.5, -1)
	gtextlabel.Visible = false
	gtextlabel.Parent = img
	
	local function enter()
		img.Image = hvimg
		textlabel.Visible = false
		gtextlabel.Visible = true
	end
	
	local function leave()
		img.Image = stimg
		gtextlabel.Visible = false
		textlabel.Visible = true
	end
	if not disabled then
		img.MouseEnter:Connect(enter)
		
		img.MouseLeave:Connect(leave)
		
		img.MouseButton1Down:Connect(function()
			leave()
			onPress()
		end)
	end
	
	
	return img
end

function GUI.Generators.CenterHolderFrame(x, y)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(0, x, 0, y)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(0.5, 0, 0.5, 0)
	return f
end

function GUI.Generators.ScreenGui(name, dporder)
	local ui = Instance.new("ScreenGui")
	ui.IgnoreGuiInset = true
	ui.Name = name or "UI"
	ui.DisplayOrder = dporder or 1
	ui.Parent = game.Players.LocalPlayer.PlayerGui
	return ui
end

function GUI.Generators.Frame(properties)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(1,1,1)
	for k, v in pairs(properties) do
		f[k] = v
	end
	return f
end


GUI.Generators.CreateTextLabel = fgen.CreateTextLabel



GUI.Generators.BtnSizeX = 400
GUI.Generators.BtnSizeY = 40
GUI.Generators.BtnPadding = 10
GUI.Generators.Back = "http://www.roblox.com/asset/?id=3732292179"

GUI.Generators.register_esc = GUI.register_esc
GUI.Generators.clear_text = GUI.clear_text
GUI.Generators.get_text = GUI.get_text
GUI.Generators.bind_text_label = GUI.bind_text_label

return GUI
