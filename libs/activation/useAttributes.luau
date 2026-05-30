local Mechanic = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("Mechanic"))
local gt = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("gt"))
local touch = require(game:GetService("ReplicatedStorage"):WaitForChild("Libs"):WaitForChild("touch"))
local types = require("./types")

local function useAttributes(
	implementation: Mechanic.MechanicImplementationLike,
	basename: string?
): types.ActivationAttributes
	basename = basename or "Activation"

	local attributes = {}
	attributes.Enabled = implementation:attribute(basename .. "Enabled", gt.boolean(), false)
	attributes.Mode = implementation:attribute(basename .. "Mode", gt.optional(gt.string()), nil)

	attributes.BaseName = implementation:attribute(basename .. "BaseName", gt.string(), basename)
	attributes.HumanoidStateType = implementation:attribute(
		basename .. "HumanoidStateType",
		gt.optional(gt.enumOf(Enum.HumanoidStateType) :: Enum.HumanoidStateType),
		nil
	)

	attributes.Interval = implementation:attribute(basename .. "Interval", gt.optional(gt.positiveNumber), nil)

	attributes.KeyCode =
		implementation:attribute(basename .. "KeyCode", gt.optional(gt.enumOf(Enum.KeyCode) :: Enum.KeyCode), nil)

	attributes.MaxDistance = implementation:attribute(basename .. "MaxDistance", gt.positiveNumber, math.huge)

	attributes.Id = implementation:attribute(basename .. "Id", gt.optional(gt.string()), nil)

	attributes.Touch = touch.useAttributes(implementation, basename)

	return attributes
end

return useAttributes
