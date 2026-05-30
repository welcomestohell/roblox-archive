local Mechanic = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("Mechanic"))
local gt = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("gt"))

local function useAttributes(implementation: Mechanic.MechanicImplementationLike, basename: string?)
	basename = basename or ""

	local attributes = {}
	attributes.Transition = implementation:attribute(basename .. "Transition", gt.string(), "Instant")
	attributes.KeepVelocity = implementation:attribute(basename .. "KeepVelocity", gt.boolean(), true)
	attributes.Offset = implementation:attribute(basename .. "Offset", gt.CFrame(), CFrame.identity)
	attributes.ScreenFadeColor = implementation:attribute(basename .. "ScreenFadeColor", gt.Color3(), Color3.new())

	return attributes
end

return useAttributes
