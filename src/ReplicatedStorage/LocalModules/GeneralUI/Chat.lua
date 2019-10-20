local Chat = {}


Chat.justOpened = false

Chat.LastText = ""

Chat.InvisTexts = {}
Chat.VisTexts = {}

Chat.CmdPrefix = "?"

function Chat.on_text_change(text)
	Chat.LastText = Chat.Text
	Chat.Text = text
	Chat.redraw_textbox("")
end

function Chat.redraw_textbox(newtxt)
	if Chat.TextBox then
		Chat.TextBox:Destroy()
	end
	Chat.TextBox = Chat.api.CreateTextLabel(Chat.Text .. newtxt, nil, nil, true)
	Chat.TextBox.Position = UDim2.new(0, 24, 0, 4)
	Chat.TextBox.Parent = Chat.InputFrame
end

function Chat.open()
	wait() --wait for pending T to go away
	Chat.lock()
	Chat.UI.Enabled = true
	Chat.isopen = true
	Chat.justOpened = true
	Chat.api.clear_text()
	

	
	for k, v in pairs(Chat.VisTexts) do
		if Chat.InvisTexts[v] then
			v.Visible = true
		end
	end
end

function Chat.add_message(sender, message)
	local name_col = "&a"
	local msg_col = "&f"
	local full_str
	if sender then
		full_str = name_col .. sender .. msg_col .. ": " .. message
	else
		full_str = msg_col .. message
	end
	local txt_lbl = Chat.api.CreateTextLabel(full_str, Vector2.new(512, 128), "> ")
	table.insert(Chat.VisTexts, txt_lbl)
	
	txt_lbl.Parent = Chat.MessagesFrame
	
	local vt = {}
	for k, v in pairs(Chat.VisTexts) do
		if k > (#Chat.VisTexts)-12 then
			table.insert(vt, v)
		else
			v:Destroy()
		end
	end
	Chat.VisTexts = vt
	
	spawn(function()
		wait(15)
		if txt_lbl and txt_lbl.Parent then
			Chat.InvisTexts[txt_lbl] = true
			if not Chat.isopen then
				txt_lbl.Visible = false
			end
		end
	end)
end


function Chat.send()
	local txt = Chat.Text
	txt = txt:gsub("\n", ""):gsub("\13", ""):gsub("\r", ""):gsub("\10", "")
	if #txt == 0 or (string.gsub(txt, "%s", "") == "") then Chat.LastText = "" Chat.Text = "" return end
	game.ReplicatedStorage.Remote.Chat:FireServer(txt)
	if(txt:sub(0, #Chat.CmdPrefix) == Chat.CmdPrefix) then return end
	Chat.add_message(game.Players.LocalPlayer.Name, txt)
end

function Chat.close()
	Chat.UI.Enabled = false
	Chat.isopen = false
	Chat.closed = tick()
	wait() --wait for pending RETURN or other to be processed
	Chat.unlock()
	for k, v in pairs(Chat.VisTexts) do
		if Chat.InvisTexts[v] then
			v.Visible = false
		end
	end
end

function Chat.on_uis(input, gameproc)
	if input == Enum.KeyCode.T and not gameproc then
		Chat.open()
	elseif input == Enum.KeyCode.Return and Chat.isopen then
		Chat.send()
		Chat.close()
	end
end

function Chat.isOpen()
	return (Chat.isopen == true) or ((tick() - Chat.closed) < 0.1)
end

game.ReplicatedStorage.Remote.GetCmdPrefix.OnClientInvoke = function(newPrefix)
	Chat.CmdPrefix = newPrefix
end

function Chat.init(lockfunc, unlockfunc, api)
	spawn(function()
		Chat.CmdPrefix = game.ReplicatedStorage.Remote.GetCmdPrefix:InvokeServer()
	end)
	Chat.lock = lockfunc
	Chat.unlock = unlockfunc
	Chat.api = api
	Chat.isopen = false
	
	Chat.UI = api.ScreenGui("Chat", 25)
	Chat.UI.Enabled = false
	Chat.InputFrame = api.Frame{
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(0,0,0);
		Size = UDim2.new(1, -10, 0, 26);
		AnchorPoint = Vector2.new(0.5, 1);
		Position = UDim2.new(0.5, 0, 1, -5);
		Parent = Chat.UI
	}
	
	Chat.AlwaysOnUI = api.ScreenGui("ChatMessages", 20)
	Chat.MessagesFrame = api.Frame{
		BackgroundTransparency = 1;
		AnchorPoint = Vector2.new(0, 1);
		Position = UDim2.new(0, 10, 1, -64);
		Size = UDim2.new(1, -(10*2), 1, -(64*2));
		Parent = Chat.AlwaysOnUI
	}
	
	Chat.Layout = Instance.new("UIListLayout")
	Chat.Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	Chat.Layout.Parent = Chat.MessagesFrame
	Chat.Layout.Padding = UDim.new(0, 6 - 2)
	
	Chat.GreaterThan = api.CreateTextLabel(">")
	Chat.GreaterThan.Position = UDim2.new(0, 5, 0, 4)
	Chat.GreaterThan.Parent = Chat.InputFrame
	
	Chat.closed = 0
	
	Chat.Text = ""
	Chat.redraw_textbox("")
	
	api.register_esc(Chat.isOpen, Chat.close)
	api.bind_text_label(Chat.isOpen, Chat.on_text_change)
	
	game.ReplicatedStorage.Remote.Chat.OnClientEvent:Connect(Chat.add_message)
end

return Chat
