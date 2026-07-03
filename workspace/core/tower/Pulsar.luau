-- FIXME: Applying on a spawned Box (from a BoxSpawner) somehow makes it pulse
-- TWICE????????????? I have no fucking clue why

local TweenService = game:GetService "TweenService"

local logger = require "@core/shared/logger"
local activation = require "@libs/activation"
local instances = require "@libs/instances"
local lerp = require "@libs/lerp"
local functions = require "@libs/primitives/functions"
local std = require "@libs/std"
local tweens = require "@libs/tweens"

local isSequence = std.gt.union(std.gt.ColorSequence, std.gt.NumberSequence)
local isSetAs = std.gt.literals {
	"Color3",
	"ColorSequence",
	"BrickColor",
	"number",
	"NumberSequence",
	"NumberRange",
}

local Pulsar = std.Mechanic {
	name = "Pulsar",
	description = "Tweens it's properties using sequence data types.",
	instanceType = std.isA.Instance(),

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cycle = tweens.useAttributes "Cycle",
	Elapsed = std.Attribute("Elapsed", std.gt.positiveNumber, 0),
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Activation = activation.useAttributes(),

	std.AttributeSection "Properties",
	Set = std.AttributeMap("Set", std.gt.optional(isSequence), nil),
	SetAs = std.AttributeMap("SetAs", std.gt.optional(isSetAs), nil),

	isSequence = std.gt.build(isSequence),
	isSetAs = std.gt.build(isSetAs),
	setAslocalructors = {
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
	self:step(pulsar, 0)
end

function Pulsar.step(self: PulsarSelf, pulsar: PulsarMechanic, alpha: number)
	for property, sequence: typeof(isSequence) in self.Set:getAll(pulsar) do
		local sequenceType = typeof(sequence) :: "ColorSequence" | "NumberSequence"

		local value = if sequenceType == "ColorSequence"
			then lerp.evaluateColorSequence(sequence :: ColorSequence, alpha)
			else lerp.evaluateNumberSequence(sequence :: NumberSequence, alpha)

		local setAs: typeof(isSetAs) = self.SetAs:get(pulsar, property) or typeof(value) :: "Color3" | "number"
		local localructor = self.setAslocalructors[sequenceType][setAs]
		if not localructor then
			logger:Error("Invalid SetAs value for", property, ":", setAs)
			continue
		end

		pcall(instances.setUnsafe, pulsar.instance, property, localructor(value))
	end
end

function Pulsar.onActivate(self: PulsarSelf, pulsar: PulsarMechanic)
	if pulsar:Active() or pulsar:Debounced() then return end
	pulsar:Debounced(true)

	local wasActivatable = self.Activation.Enabled(pulsar)
	pulsar.Activation.Enabled(pulsar, false)

	pulsar:Active(false)
	pulsar:Synchronized(false)
	pulsar:Elapsed(0)
	self:step(pulsar, 0)
	pulsar:Active(true)

	pulsar.life:delay(self.Cycle.Duration(pulsar), function(pulsar: PulsarMechanic)
		pulsar:Active(false)
		self:step(pulsar, 0)
	end, pulsar)

	pulsar.life:delay(pulsar:Cooldown(), function(pulsar: PulsarMechanic, wasActivatable)
		pulsar.Activation.Enabled(pulsar, wasActivatable)
		pulsar:Debounced(false)
	end, pulsar, wasActivatable)
end

function Pulsar.onPreRender(self: PulsarSelf, deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()
	for _, pulsar: PulsarMechanic in level:getMechanics(self) do
		if pulsar:Active() then
			local elapsed = if pulsar:Synchronized()
				then lifetime
				else pulsar:Elapsed(pulsar:Elapsed() :: number + deltaTime)

			local cycleDuration = self.Cycle.Duration(pulsar)
			local cycleProgress = elapsed % cycleDuration / cycleDuration

			local alpha = TweenService:GetValue(cycleProgress, self.Cycle.Style(pulsar), self.Cycle.Direction(pulsar))

			self:step(pulsar, alpha)
		end
	end
end

return Pulsar
