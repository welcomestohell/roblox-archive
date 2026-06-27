const Button = require "@core/tower/Button"
const activation = require "@libs/activation"
const std = require "@libs/std"

const ButtonDisabler = std.Mechanic {
	emoji = "🕹️",
	name = "ButtonDisabler",
	description = "When activated, deactivates all active Buttons matching it's Group.",
	instanceType = std.isA.Instance(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Group = std.Attribute("Group", std.gt.tag, ""),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}
export type ButtonDisablerMechanic = std.Mechanic<typeof(ButtonDisabler)>

-- Investigate: Should we add disabling individual buttons?
function ButtonDisabler.onActivate(self: typeof(ButtonDisabler), disabler: ButtonDisablerMechanic, level: std.Level)
	const wasActivatable = self.Activation.Enabled(disabler)
	self.Activation.Enabled(disabler, false)
	disabler:Debounced(true)

	const group = disabler:Group()
	for _, button: Button.ButtonMechanic in level:getMechanics(Button) do
		if button:Group() == group then button:Active(false) end
	end

	task.wait(disabler:Cooldown())
	if disabler.life.alive then
		self.Activation.Enabled(disabler, wasActivatable)
		disabler:Debounced(false)
	end
end

return ButtonDisabler
