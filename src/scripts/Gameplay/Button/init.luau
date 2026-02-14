local std = require("@libs/std")
local useButtonAttributes = require("@self/useButtonAttributes")

local Button = std.Mechanic({})
export type ButtonMechanic = std.Mechanic<typeof(Button)>
Button.instanceTag = "Button"
Button.instanceType = std.isA.BasePart()

Button.useButtonAttributes = useButtonAttributes
local attributes = useButtonAttributes(Button)
Button.ButtonId = attributes.ButtonId
Button.ButtonPressed = attributes.ButtonPressed
Button.ButtonPressedOffset = attributes.ButtonPressedOffset
Button.Cooldown = attributes.Cooldown
Button.Duration = attributes.Duration
Button.PlaySound = attributes.PlaySound
Button.ButtonPressedTween = attributes.ButtonPressedTween

return Button
