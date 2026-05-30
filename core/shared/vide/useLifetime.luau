local RunService = game:GetService("RunService")

local Vide = require("@roblox_packages/Vide")

local function useLifetime()
	local lifetime = Vide.source(0)
	Vide.cleanup(RunService.PreSimulation:Connect(function(dt)
		lifetime(lifetime() + dt)
	end))
	return lifetime
end

return useLifetime
