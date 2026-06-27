const activation = require "@libs/activation"
const std = require "@libs/std"
const Signal = require "@pkgs/Signal"

const Activator = std.Mechanic {
	emoji = "👆",
	name = "Activator",
	description = "When activated, activates mechanics tagged with it's Group.",
	instanceType = std.gt.instanceTree { Target = std.gt.optional(std.isA.ObjectValue()) },

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Group = std.Attribute("Group", std.gt.group, ""),
	Tag = std.Attribute("Tag", std.gt.tag, ""),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	onActivatedSignal = Signal.new<<(ActivatorMechanic)>>(),
}

export type ActivatorMechanic = std.Mechanic<typeof(Activator)>

const function implementActivatorMode(context: activation.ActivationContext)
	Activator.onActivatedSignal:Connect(function(activator: ActivatorMechanic)
		const group = Activator.Group(context.instanceConfiguration)
		if activator:Group() == group or context.instanceConfiguration:HasTag(activator:Tag()) then
			context:onActivate(activation.castEvent { kind = "Activator", mechanic = activator })
		end
	end)
end

activation
	.registerMode("Activator", { implement = implementActivatorMode })
	:expect "Failed to regiser activation mode for Activator"

function Activator.onActivate(self: typeof(Activator), activator: ActivatorMechanic, level: std.Level)
	const wasActivatable = self.Activation.Enabled(activator)
	self.Activation.Enabled(activator, false)
	activator:Debounced(true)

	local targetInstance = activator.instance:FindFirstChild "Target"
	if targetInstance then self.tryActivate(targetInstance, level) end

	self.onActivatedSignal:Fire(activator)

	task.wait(activator:Cooldown())
	if activator.life.alive then
		self.Activation.Enabled(activator, wasActivatable)
		activator:Debounced(false)
	end
end

return Activator
