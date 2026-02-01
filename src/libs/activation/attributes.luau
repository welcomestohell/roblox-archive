local Attribute = require("@libs/Attribute")
local gt = require("@libs/gt")

local attributes = {}

attributes.Activatable = Attribute.new("Activatable", gt.boolean(), false)
attributes.Enabled = Attribute.new("Enabled", gt.boolean(), false)
attributes.ActivationBehavior = Attribute.new("ActivationBehavior", gt.string())
attributes.MaxActivationDistance = Attribute.new("MaxActivationDistance", gt.positiveNumber)
attributes.ActivationKeyCode = Attribute.new("ActivationKeyCode", gt.Enum(Enum.KeyCode))
attributes.ActivationInterval = Attribute.new("ActivationInterval", gt.positiveNumber)
attributes.ActivationHumanoidStateType = Attribute.new("ActivationHumanoidStateType", gt.Enum(Enum.HumanoidStateType))

return table.freeze(attributes)
