local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")

local SeamlessMeasurement = gt.build(gt.unionLiterals2("Relative", "World"))
export type SeamlessMeasurement = typeof(SeamlessMeasurement:type())

local function useSeamlessAttributes(implementation: Mechanic.MechanicImplementationLike, baseName: string?)
	baseName = baseName or "Seamless"

	local attributes = {}
	attributes.Enabled = implementation:attribute(baseName .. "Enabled", gt.boolean(), true)
	attributes.Scaled = implementation:attribute(baseName .. "Scaled", gt.boolean(), true)
	attributes.Clamped = implementation:attribute(baseName .. "Clamped", gt.boolean(), true)

	return attributes
end

return useSeamlessAttributes
