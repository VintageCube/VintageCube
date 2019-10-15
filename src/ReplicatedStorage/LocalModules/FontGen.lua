-- renders text

local F = {}

F.Font = "rbxassetid://3108589584"

F.FontBreakout = {
	{"\00", "☺", "☻", "♥", "♦", "♣", "♠", "•", "◘", "○", "◙", "♂", "♀", "♪", "♫", "☼"  },
	{"►", "◄", "↕", "‼", "¶", "§", "▬", "↨", "↑", "↓", "→", "←", "∟", "↔", "▲", "▼" },
	{" ", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/"},
	{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?" },
	{"@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O" },
	{"P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_"},
	{"`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o" },
	{"p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~"      }
}

F.FontWidth = {
	{64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64  },
	{64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64  },
	{16, 8, 32, 40, 40, 48, 48, 16, 32, 32, 56, 40, 8, 40, 8, 40  },
	{40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 8, 8, 32, 40, 32, 40  },
	{48, 40, 40, 40, 40, 40, 40, 40, 40, 24, 40, 40, 40, 40, 40, 40  },
	{40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 24, 40, 24, 40, 40  },
	{16, 40, 40, 40, 40, 40, 32, 40, 40, 8, 40, 32, 16, 40, 40, 40  },
	{40, 40, 40, 40, 24, 40, 40, 40, 40, 40, 40, 32, 8, 32, 48 },



}

function F.CreateLetter(letter, color)
	local LetterX, LetterY = 1, 1
	for y=1, #F.FontBreakout do
		for x=1, #F.FontBreakout[y] do
			if F.FontBreakout[y][x] == letter then
				LetterX = x
				LetterY = y
				break
			end
		end
	end
	
	local ImageLabel = Instance.new("ImageLabel")
	ImageLabel.Size = UDim2.new(0, 16, 0, 16)
	ImageLabel.Image = F.Font
	ImageLabel.ImageRectSize = Vector2.new(16, 16)
	ImageLabel.ImageRectOffset = Vector2.new((LetterX-1) * 16, (LetterY-1) * 16)
	ImageLabel.ScaleType = "Fit"
	ImageLabel.Name = tostring(16 / (64 / F.FontWidth[LetterY][LetterX]))
	ImageLabel.BackgroundTransparency = 1
	ImageLabel.ImageColor3 = color[1]
	
	
	local ImgClone = ImageLabel:Clone()
	ImgClone.Parent = ImageLabel
	ImgClone.Position = UDim2.new(0, 2, 0, 2)
	ImgClone.ImageColor3 = color[2]
	ImageLabel.ZIndex = ImgClone.ZIndex + 1
	
	return ImageLabel
end

local colorcodes = {
	["0"] = {Color3.new(0,0,0), Color3.new(0,0,0)},
	["1"] = {Color3.fromRGB(0, 0, 191), Color3.fromRGB(0, 0, 47)},
	["2"] = {Color3.fromRGB(0, 191, 0), Color3.fromRGB(0, 47, 0)},
	["3"] = {Color3.fromRGB(0, 191, 191), Color3.fromRGB(0, 47, 47)},
	["4"] = {Color3.fromRGB(191, 0, 0), Color3.fromRGB(47, 0, 0)},
	["5"] = {Color3.fromRGB(191, 0, 191), Color3.fromRGB(47, 0, 47)},
	["6"] = {Color3.fromRGB(191, 191, 0), Color3.fromRGB(47, 47, 0)},
	["7"] = {Color3.fromRGB(191, 191, 191), Color3.fromRGB(47, 47, 47)},
	["8"] = {Color3.fromRGB(64, 64, 64), Color3.fromRGB(16, 16, 16)},
	["9"] = {Color3.fromRGB(64, 64, 255), Color3.fromRGB(16, 16, 63)},
	["a"] = {Color3.fromRGB(64, 255, 64), Color3.fromRGB(16, 63, 16)},
	["b"] = {Color3.fromRGB(64, 255, 255), Color3.fromRGB(16, 63, 63)},
	["c"] = {Color3.fromRGB(255, 64, 64), Color3.fromRGB(63, 16, 16)},
	["d"] = {Color3.fromRGB(255, 64, 255), Color3.fromRGB(63, 16, 63)},
	["e"] = {Color3.fromRGB(255, 255, 64), Color3.fromRGB(63, 63, 16)},
	["f"] = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(63, 63, 63)},
	
	["s"] = {Color3.fromRGB(255, 255, 160), Color3.fromRGB(63, 63, 40)} -- button selected (not a classic color)
}

local cursors = {}

local v = false

function F.CreateTextLabel(Text, sizeLimit, linesep, cursor)
	local Frame = Instance.new("Frame")
	local X = 0
	local Y = 0
	local CurrColor = colorcodes["f"]
	local switchingColors = false

	local function add_letter(letter, ign_linesep)
		if (not ign_linesep) and letter == "&" then
			switchingColors = true
		elseif (not ign_linesep) and switchingColors then
			CurrColor = colorcodes[string.lower(letter)]
			switchingColors = false
			if not CurrColor then
				CurrColor = colorcodes["f"]
				add_letter("&", true)
				add_letter(letter)
			end
		else

			local LetterImg = F.CreateLetter(letter, CurrColor)
			LetterImg.Parent = Frame
			if (not ign_linesep) and sizeLimit and ((X + tonumber(LetterImg.Name)) > sizeLimit.X) then
				X = 0
				Y = Y + 16 + 2
				if linesep then
					for ls in linesep:gmatch(".") do
						add_letter(ls, true)
					end
				end
			end
			LetterImg.Position = UDim2.new(0, X, 0, Y)
			X = X + tonumber(LetterImg.Name) + 2
		end
	end
	
	for _, letter_cp in utf8.codes(Text) do
		local letter = utf8.char(letter_cp)
		add_letter(letter)
	end
	if switchingColors then
		add_letter("&", true)
		switchingColors = false
	end
	if cursor then
		local LetterImg = F.CreateLetter("_", CurrColor)
		LetterImg.Parent = Frame
		LetterImg.Position = UDim2.new(0, X, 0, Y)
		X = X + tonumber(LetterImg.Name) + 2
		cursors[LetterImg] = true
		v = false
	end
	Frame.Size = UDim2.new(0, X, 0, Y+16)
	Frame.BackgroundTransparency = 1
	return Frame
end



function F.Tick()
	v = not v
	for k, op in pairs(cursors) do
		if k and k.Parent then
			k.Visible = v
		end
	end
end


spawn(function()
	while wait(1/2) do
		F.Tick()
	end
end)


return F
