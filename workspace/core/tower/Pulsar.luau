const TweenService = game:GetService "TweenService"

const logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const instances = require "@libs/instances"
const lerp = require "@libs/lerp"
const functions = require "@libs/primitives/functions"
const std = require "@libs/std"
const tweens = require "@libs/tweens"

const isSequence = std.gt.union(std.gt.ColorSequence, std.gt.NumberSequence)

const isSetAs = std.gt.literals {
	"Color3",
	"ColorSequence",
	"BrickColor",
	"number",
	"NumberSequence",
	"NumberRange",
}

const Pulsar = std.Mechanic {
	name = "Pulsar",
	description = "Tweens it's properties using sequence data types.",
	instanceType = std.isA.Instance(),

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cycle = tweens.useAttributes "Cycle",
	Elapsed = std.Attribute("Elapsed", std.gt.positiveNumber, 0),
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),

	std.AttributeSection "Activation",
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Activation = activation.useAttributes(),

	std.AttributeSection "Properties",
	Set = std.AttributeMap("Set", std.gt.optional(isSequence), nil),
	SetAs = std.AttributeMap("SetAs", std.gt.optional(isSetAs), nil),

	isSequence = std.gt.build(isSequence),
	isSetAs = std.gt.build(isSetAs),
	setAsConstructors = {
		ColorSequence = {
			Color3 = functions.passthrough,
			ColorSequence = ColorSequence.new,
			BrickColor = BrickColor.new,
		},
		NumberSequence = {
			number = functions.passthrough,
			NumberRange = NumberRange.new,
			NumberSequence = NumberSequence.new,
		},
	},
}

export type PulsarSelf = typeof(Pulsar)
export type PulsarMechanic = std.Mechanic<PulsarSelf>

function Pulsar.onStart(self: PulsarSelf, pulsar: PulsarMechanic)
	self.Activation.Enabled:onBind(pulsar, function(activatable)
		if activatable and pulsar:Synchronized() then
			logger:Warn "Activation and Synchronized conflicts when both enabled, so Synchronized will be disabled."
			pulsar:Synchronized(false)
		end
	end)

	self.Synchronized:onBind(pulsar, function()
		pulsar:Elapsed(0)
	end)

	self:step(pulsar, 0)
end

function Pulsar.step(self: PulsarSelf, pulsar: PulsarMechanic, alpha: number)
	for property, sequence: typeof(isSequence) in self.Set:getAll(pulsar) do
		const sequenceType = typeof(sequence) :: "ColorSequence" | "NumberSequence"

		const value = if sequenceType == "ColorSequence"
			then lerp.evaluateColorSequence(sequence :: ColorSequence, alpha)
			else lerp.evaluateNumberSequence(sequence :: NumberSequence, alpha)

		const setAs: typeof(isSetAs) = self.SetAs:get(pulsar, property) or typeof(value) :: "Color3" | "number"
		const constructor = self.setAsConstructors[sequenceType][setAs]
		if not constructor then
			logger:Error("Invalid SetAs value for", property, ":", setAs)
			continue
		end

		pcall(instances.setUnsafe, pulsar.instance, property, constructor(value))
	end
end

function Pulsar.onActivate(self: PulsarSelf, pulsar: PulsarMechanic)
	if pulsar:Active() or pulsar:Debounced() then return end
	pulsar:Debounced(true)

	const wasActivatable = self.Activation.Enabled(pulsar)
	pulsar.Activation.Enabled(pulsar, false)

	pulsar:Elapsed(0)
	self:step(pulsar, 0)
	pulsar:Active(true)

	pulsar.life:delay(self.Cycle.Duration(pulsar), function(pulsar: PulsarMechanic)
		pulsar:Active(false)
	end, pulsar)

	pulsar.life:delay(pulsar:Cooldown(), function(pulsar: PulsarMechanic, wasActivatable)
		pulsar.Activation.Enabled(pulsar, wasActivatable)
		pulsar:Debounced(false)
	end, pulsar, wasActivatable)
end

function Pulsar.onPreRender(self: PulsarSelf, deltaTime: number, level: std.Level)
	const lifetime = level:getLifetime()
	for _, pulsar: PulsarMechanic in level:getMechanics(self) do
		if pulsar:Active() then
			const elapsed = if pulsar:Synchronized()
				then lifetime
				else pulsar:Elapsed(pulsar:Elapsed() :: number + deltaTime)

			const cycleDuration = self.Cycle.Duration(pulsar)
			const cycleProgress = elapsed % cycleDuration / cycleDuration

			const alpha = TweenService:GetValue(cycleProgress, self.Cycle.Style(pulsar), self.Cycle.Direction(pulsar))

			self:step(pulsar, alpha)
		end
	end
end

return Pulsar
