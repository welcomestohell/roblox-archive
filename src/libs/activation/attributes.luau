local Attribute = require("@libs/Attribute")
local gt = require("@libs/gt")

return table.freeze {
	IsActivatable = Attribute.new("IsActivatable", gt.boolean(), false),
	ActivationMode = Attribute.new("ActivationMode", gt.string()),

	MaxActivationDistance = Attribute.new("MaxActivationDistance", gt.positiveNumber),
	ActivationKeyCode = Attribute.new("ActivationKeyCode", gt.enumOf(Enum.KeyCode) :: Enum.KeyCode),
	ActivationInterval = Attribute.new("ActivationInterval", gt.positiveNumber),
	ActivationHumanoidStateType = Attribute.new(
		"ActivationHumanoidStateType",
		gt.enumOf(Enum.HumanoidStateType) :: Enum.HumanoidStateType
	),
}
