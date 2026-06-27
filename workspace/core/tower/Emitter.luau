const activation = require "@libs/activation"
const emission = require "@libs/emission"
const std = require "@libs/std"

const Emitter = std.Mechanic {
	emoji = "✨",
	name = "Emitter",
	description = "When activated, emits all Sounds and ParticleEmitters under itself.",
	instanceType = std.isA.Instance(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type Emitter = typeof(Emitter)
export type EmitterMechanic = std.Mechanic<Emitter>

function Emitter.onActivate(self: Emitter, emitter: EmitterMechanic)
	const wasActivatable = self.Activation.Enabled(emitter)
	self.Activation.Enabled(emitter, false)
	emitter:Debounced(true)

	emitter.life:delay(emitter:Cooldown(), function(emitter: typeof(emitter))
		emitter:Debounced(false)
		self.Activation.Enabled(emitter, wasActivatable)
	end, emitter)

	for _, instance in emitter.instance:GetDescendants() do
		emission.emit(instance)
	end
end

return Emitter
