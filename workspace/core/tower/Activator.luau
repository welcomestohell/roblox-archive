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

const function shouldActivate(context: activation.ActivationContext, activator: ActivatorMechanic)
	const group = Activator.Group(context.instanceConfiguration)
	const targetInstance = activator.instance:FindFirstChild "Target"

	return activator:Group() == group
		or context.instanceConfiguration:HasTag(activator:Tag())
		or targetInstance
			and targetInstance:IsA "ObjectValue"
			and (targetInstance.Value == context.instance or targetInstance.Value == context.instanceConfiguration)
end

const function implementActivatorMode(context: activation.ActivationContext)
	Activator.onActivatedSignal:Connect(function(activator: ActivatorMechanic)
		if shouldActivate(context, activator) then
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

	self.onActivatedSignal:Fire(activator)

	activator.life:delay(activator:Cooldown(), function(activator: typeof(activator))
		activator.Activation.Enabled(activator, wasActivatable)
		activator:Debounced(false)
	end, activator)
end

return Activator
