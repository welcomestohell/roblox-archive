const character = require "@libs/character"
const logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const emission = require "@libs/emission"
const std = require "@libs/std"
const teleport = require "@libs/teleport"
const tweens = require "@libs/tweens"

const Teleporter = std.Mechanic {
	emoji = "🌀",
	name = "Teleporter",
	description = "When activated, teleports the activator to a destination matching it's Group.",
	instanceType = std.isA.BasePart(),

	debounce = std.LevelState(false),
	debouncedTeleporters = std.LevelState<<{ [TeleporterMechanic]: true }>> {},

	Active = std.Attribute("Active", std.gt.boolean(), true),
	Group = std.Attribute("Group", std.gt.group, ""),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Teleport = teleport.useAttributes(),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Seamless",
	Seamless = teleport.useSeamlessAttributes(),

	std.AttributeSection "Emission",
	EmitActivatedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Teleporter: On Activated"),

	std.AttributeSection "Tween",
	Tween = tweens.useAttributes(),
}

export type TeleporterMechanic = std.Mechanic<typeof(Teleporter)>

function Teleporter.onActivate(self: typeof(Teleporter), teleporter: TeleporterMechanic, level: std.Level, event)
	const root = character.getMaybeHumanoidRootPart()
	if not root then return end

	const group = teleporter:Group()
	const groupInstances = level:getGroupedInstances(group)
	const len = #groupInstances
	if len == 0 then return end

	math.randomseed(os.clock())
	const targetDestination = groupInstances[if len == 1 then 1 else math.random(1, len)]
	if not targetDestination:IsA "BasePart" then
		logger:Warn("Expected teleporter destination", targetDestination:GetFullName(), "to be a BasePart")
		return
	end

	if self.debounce:get(level) then return end
	self.debounce:set(level, true)

	const wasActivatable = self.Activation.Enabled(teleporter)
	self.Activation.Enabled(teleporter, false)
	teleporter:Active(true)
	teleporter:Debounced(true)

	emission.emitTaggedDescendants(teleporter.instance, teleporter:EmitActivatedTag())

	teleport.teleport {
		teleporter = teleporter.instance,
		teleporterConfiguration = teleporter.instanceConfiguration or teleporter.instance,
		teleporterLife = teleporter.life,

		target = root,
		destination = targetDestination,

		attributes = self.Teleport,
		seamlessAttributes = self.Seamless,
		tweenAttributes = self.Tween,
	}

	self.debounce:set(level, false)
	teleporter:Active(false)

	task.wait(teleporter:Cooldown())
	self.Activation.Enabled(teleporter, wasActivatable)
	teleporter:Debounced(false)
end

return Teleporter
