local Mechanic = require "@libs/core/Mechanic"
local gt = require "@libs/vendor/gt"

local SeamlessMeasurement = gt.build(gt.literals("Relative", "World"))
export type SeamlessMeasurement = typeof(SeamlessMeasurement:type())

local function useSeamlessAttributes(implementation: Mechanic.MechanicImplementation, basename: string?)
	basename = basename or "Seamless"

	implementation:attributeSection "Seamless"
	local attributes = {}
	attributes.Enabled = implementation:attribute(basename .. "Enabled", gt.boolean(), false)
	attributes.Scaled = implementation:attribute(basename .. "Scaled", gt.boolean(), true)
	attributes.Clamped = implementation:attribute(basename .. "Clamped", gt.boolean(), true)
	implementation:endAttributeSection()

	return attributes
end

return useSeamlessAttributes
