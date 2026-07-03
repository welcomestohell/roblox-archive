local activation = require "@libs/activation"
local character = require "@libs/character"
local emission = require "@libs/emission"
local logger = require "@core/shared/logger"
local std = require "@libs/std"
local teleport = require "@libs/teleport"
local touch = require "@libs/touch"
local tweens = require "@libs/tweens"

local Teleporter = std.Mechanic {
	emoji = "🌀",
	name = "Teleporter",
	description = "When activated, teleports the activator to a destination matching it's Group.",
	instanceType = std.isA.BasePart(),

	debounce = std.LevelState(false),
	debouncedTeleporters = std.LevelState<<{ [TeleporterMechanic]: true }>> {},

	Active = std.Attribute("Active", std.gt.boolean(), true),
	Group = std.Attribute("Group", std.gt.group, ""),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
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

function Teleporter.onActivate(
	self: typeof(Teleporter),
	teleporter: TeleporterMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	local target = event.kind == "Touch" and touch.castIntoTarget(event.toucher) or character.getMaybeHumanoidRootPart()
	if not target then return end

	local group = teleporter:Group()
	local groupInstances = level:getGroupedInstances(group)
	local len = #groupInstances
	if len == 0 then return end

	math.randomseed(os.clock())
	local targetDestination = groupInstances[if len == 1 then 1 else math.random(1, len)]
	if not targetDestination:IsA "BasePart" then
		logger:Warn("Expected teleporter destination", targetDestination:GetFullName(), "to be a BasePart")
		return
	end

	if self.debounce:get(level) then return end
	self.debounce:set(level, true)

	local wasActivatable = self.Activation.Enabled(teleporter)
	self.Activation.Enabled(teleporter, false)
	teleporter:Active(true)
	teleporter:Debounced(true)

	emission.emitTaggedDescendants(teleporter.instance, teleporter:EmitActivatedTag())
	teleport.teleport {
		teleporter = teleporter.instance,
		teleporterConfiguration = teleporter.instanceConfiguration or teleporter.instance,
		teleporterLife = teleporter.life,

		target = target,
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
