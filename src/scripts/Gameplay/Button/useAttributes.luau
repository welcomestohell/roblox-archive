local std = require("@libs/std")

local function useAttributes(self: std.MechanicImplementationLike)
	local attributes = {}

	attributes.Enabled = self:withEnabled()
	attributes.Active = self:withActive()
	attributes.Id = self:attribute("Id", std.gt.optional(std.gt.string()), nil)
	attributes.Pressed = self:attribute("Pressed", std.gt.boolean(), false)
	attributes.PressedOffset = self:attribute("PressedOffset", std.gt.CFrame(), CFrame.new(0, -0.5, 0))
	attributes.Cooldown = self:attribute("Cooldown", std.gt.positiveNumber, 0)
	attributes.Duration = self:attribute("Duration", std.gt.positiveNumber, 0)

	return attributes
end

export type ButtonAttributes = typeof(useAttributes(nil :: any))

return useAttributes
