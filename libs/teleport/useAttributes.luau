local Mechanic = require "@libs/core/Mechanic"
local gt = require "@libs/vendor/gt"

local function useAttributes(implementation: Mechanic.MechanicImplementation, basename: string?)
	basename = basename or ""

	implementation:attributeSection "Teleportation"
	local attributes = {}
	attributes.Transition = implementation:attribute(basename .. "Transition", gt.string(), "Instant")
	attributes.KeepVelocity = implementation:attribute(basename .. "KeepVelocity", gt.boolean(), true)
	attributes.Offset = implementation:attribute(basename .. "Offset", gt.CFrame(), CFrame.identity)
	attributes.ScreenFadeColor = implementation:attribute(basename .. "ScreenFadeColor", gt.Color3(), Color3.new())
	implementation:endAttributeSection()

	return attributes
end

return useAttributes
