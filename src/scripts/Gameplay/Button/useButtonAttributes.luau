local std = require("@libs/std")
local tweens = require("@libs/tweens")

export type ButtonAttributes = {
	ButtonId: std.Attribute<string?>,
	ButtonPressed: std.Attribute<boolean>,
	ButtonPressedOffset: std.Attribute<CFrame>,
	Cooldown: std.Attribute<number>,
	Duration: std.Attribute<number>,
	PlaySound: std.Attribute<boolean>,
	ButtonPressedTween: tweens.TweenAttributes,
}

local function useButtonAttributes(self: std.MechanicImplementationLike): ButtonAttributes
	local attributes = {}

	attributes.ButtonId = self:attribute("ButtonId", std.gt.optional(std.gt.string()), nil)
	attributes.ButtonPressed = self:attribute("ButtonPressed", std.gt.boolean(), false)
	attributes.ButtonPressedOffset = self:attribute("ButtonPressedOffset", std.gt.CFrame(), CFrame.new(0, -0.5, 0))
	attributes.Cooldown = self:attribute("Cooldown", std.gt.positiveNumber, 0)
	attributes.Duration = self:attribute("Duration", std.gt.positiveNumber, 0)
	attributes.PlaySound = self:attribute("PlaySound", std.gt.boolean(), true)

	self:attributeSection("Transitions")
	attributes.ButtonPressedTween = tweens.useTweenAttributes(self, "ButtonPressed")

	return attributes
end

return useButtonAttributes
