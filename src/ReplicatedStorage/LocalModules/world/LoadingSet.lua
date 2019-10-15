local F = require(game.ReplicatedStorage.LocalModules.FontGen)

local Par

local Load = {}

Load.PrevFrame = nil

function Load.SetText(txt)
	if Load.PrevFrame then
		Load.PrevFrame:Destroy()
	end
	Load.PrevFrame = F.CreateTextLabel(txt)
	Load.PrevFrame.Parent = Par
	Load.PrevFrame.AnchorPoint = Vector2.new(0.5, 1)
	Load.PrevFrame.Position = UDim2.new(0.5, 0, 0.5, -10)
end

function Load.SetProgress(float)
	Par.Loading.Completor.Size = UDim2.new(float, 0, 1, 0)
end

function Load.SetParent(par)
	Par = par
end

return Load