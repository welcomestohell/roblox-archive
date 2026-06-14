const Button = require "@core/tower/Button"
const activation = require "@libs/activation"
const std = require "@libs/std"

const ButtonDisabler = std.Mechanic {}
export type ButtonDisablerMechanic = std.Mechanic<typeof(ButtonDisabler)>
ButtonDisabler.name = "ButtonDisabler"
ButtonDisabler.instanceType = std.isA.Instance()
ButtonDisabler.emoji = "🕹️"

ButtonDisabler.Activation = activation.useAttributes(ButtonDisabler)
ButtonDisabler.Cooldown = ButtonDisabler:attribute("Cooldown", std.gt.positiveNumber, 0)
-- Investigate: Should we add disabling individual buttons?
ButtonDisabler.Group = ButtonDisabler:attribute("Group", std.gt.string(), "")

function ButtonDisabler.onActivate(self: typeof(ButtonDisabler), mechanic: ButtonDisablerMechanic, level: std.Level)
	self.Activation.Enabled(mechanic, false)
	const group = mechanic:Group()
	for _, button: Button.ButtonMechanic in level:getMechanics(Button) do
		if button:Group() == group then button:Active(false) end
	end
	task.wait(mechanic:Cooldown())
	self.Activation.Enabled(mechanic, true)
end

return ButtonDisabler
