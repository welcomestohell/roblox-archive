local RunService = game:GetService("RunService")

local Fluid = require("@roblox_packages/Fluid")

local function useLifetime()
	local lifetime = Fluid.source(0)
	Fluid.cleanup(RunService.PreSimulation:Connect(function(dt)
		lifetime(lifetime() + dt)
	end))
	return lifetime
end

return useLifetime
