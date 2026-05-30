local Workspace = game:GetService("Workspace")

local Vide = require("@roblox_packages/Vide")

local function useCamera()
	local camera = Vide.source(Workspace.CurrentCamera)
	Vide.cleanup(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if Workspace.CurrentCamera then
			camera(Workspace.CurrentCamera)
		end
	end))
	return camera
end

return useCamera
