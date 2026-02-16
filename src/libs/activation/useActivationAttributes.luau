local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")
local types = require("./types")

local function useActivationAttributes(
	implementation: Mechanic.MechanicImplementationLike,
	baseName: string?
): types.ActivationAttributes
	baseName = baseName or "Activation"

	local attributes = {}
	attributes.Enabled = implementation:attribute(baseName .. "Enabled", gt.boolean(), false)
	attributes.Mode = implementation:attribute(baseName .. "Mode", gt.optional(gt.string()), nil)

	attributes.BaseName = implementation:attribute(baseName .. "BaseName", gt.string(), baseName)
	attributes.HumanoidStateType = implementation:attribute(
		baseName .. "HumanoidStateType",
		gt.optional(gt.enumOf(Enum.HumanoidStateType) :: Enum.HumanoidStateType),
		nil
	)

	attributes.Interval = implementation:attribute(baseName .. "Interval", gt.optional(gt.positiveNumber), nil)

	attributes.KeyCode =
		implementation:attribute(baseName .. "KeyCode", gt.optional(gt.enumOf(Enum.KeyCode) :: Enum.KeyCode), nil)

	attributes.MaxDistance = implementation:attribute(baseName .. "MaxDistance", gt.positiveNumber, math.huge)

	return attributes
end

return useActivationAttributes
