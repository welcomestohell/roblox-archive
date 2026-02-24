local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")

local function useAttributes(implementation: Mechanic.MechanicImplementationLike, baseName: string?)
	baseName = baseName or ""

	local attributes = {}
	attributes.Transition = implementation:attribute(baseName .. "Transition", gt.string(), "Instant")
	attributes.KeepVelocity = implementation:attribute(baseName .. "KeepVelocity", gt.boolean(), true)
	attributes.Offset = implementation:attribute(baseName .. "Offset", gt.CFrame(), CFrame.identity)
	attributes.ScreenFadeColor = implementation:attribute(baseName .. "ScreenFadeColor", gt.Color3(), Color3.new())

	return attributes
end

return useAttributes
