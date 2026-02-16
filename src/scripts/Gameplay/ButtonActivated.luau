local std = require("@libs/std")
local tweens = require("@libs/tweens")

local ButtonActivated = std.Mechanic({})
export type ButtonActivatedMechanic = std.Mechanic<typeof(ButtonActivated)>

ButtonActivated.instanceTag = "ButtonActivated"
ButtonActivated.instanceType = std.isA.Instance()
ButtonActivated.debuggerEmoji = "💡"

ButtonActivated.Invert = ButtonActivated:attribute("Invert", std.gt.boolean(), false)

ButtonActivated:attributeSection("Properties")
-- TODO: itll probably be smarter to have AttributeGroups for these
ButtonActivated.KeepCollision = ButtonActivated:attribute("KeepCollision", std.gt.boolean(), false)
ButtonActivated.KeepTransparency = ButtonActivated:attribute("KeepTransparency", std.gt.boolean(), false)
ButtonActivated.KeepEnabled = ButtonActivated:attribute("KeepEnabled", std.gt.boolean(), false)
ButtonActivated.ActiveTransparency = ButtonActivated:attribute("ActiveTransparency", std.gt.constrainNumber(0, 1), 0)
ButtonActivated.InactiveTransparency =
	ButtonActivated:attribute("InactiveTransparency", std.gt.constrainNumber(0, 1), 0)

ButtonActivated:attributeSection("Transitions")
ButtonActivated.TransitionActivated = tweens.useTweenAttributes(ButtonActivated, "TransitionActivated")
ButtonActivated.TransitionDeactivated = tweens.useTweenAttributes(ButtonActivated, "TransitionDeactivated")

return ButtonActivated
