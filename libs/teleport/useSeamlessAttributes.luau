local Mechanic = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("Mechanic"))
local gt = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("gt"))

local SeamlessMeasurement = gt.build(gt.unionLiterals2("Relative", "World"))
export type SeamlessMeasurement = typeof(SeamlessMeasurement:type())

local function useSeamlessAttributes(implementation: Mechanic.MechanicImplementationLike, basename: string?)
	basename = basename or "Seamless"

	local attributes = {}
	attributes.Enabled = implementation:attribute(basename .. "Enabled", gt.boolean(), false)
	attributes.Scaled = implementation:attribute(basename .. "Scaled", gt.boolean(), true)
	attributes.Clamped = implementation:attribute(basename .. "Clamped", gt.boolean(), true)

	return attributes
end

return useSeamlessAttributes
