local assets = require "@core/assets"
local character = require "@libs/character"
local logger = require "@core/shared/logger"
const activation = require "@libs/activation"
local sounds = require "@libs/sounds"
local std = require "@libs/std"
local teleport = require "@libs/teleport"
const tweens = require "@libs/tweens"

local Teleporter = std.Mechanic {}
export type TeleporterMechanic = std.Mechanic<typeof(Teleporter)>

Teleporter.name = "Teleporter"
Teleporter.instanceType = std.isA.BasePart()
Teleporter.emoji = "🌀"

Teleporter.debounce = std.LevelState(false)
Teleporter.debouncedTeleporters = std.LevelState<<{ [TeleporterMechanic]: true }>> {}

Teleporter.Group = Teleporter:attribute("Group", std.gt.optional(std.gt.string()), nil)
Teleporter.Cooldown = Teleporter:attribute("Cooldown", std.gt.positiveNumber, 0)
Teleporter.Debounced = Teleporter:attribute("Debounced", std.gt.boolean(), false)

Teleporter.Teleport = teleport.useAttributes(Teleporter)
Teleporter.Activation = activation.useAttributes(Teleporter)
Teleporter.Seamless = teleport.useSeamlessAttributes(Teleporter)
Teleporter.Sound = sounds.useAttributes(Teleporter)
Teleporter.Transition = tweens.useAttributes(Teleporter)

function Teleporter.onActivate(self: typeof(Teleporter), teleporter: TeleporterMechanic, level: std.Level, event)
	local root = character.getMaybeHumanoidRootPart()
	if not root then return end

	if self.debounce:get(level) or teleporter:Debounced() then return end

	teleporter.Activation.Enabled(teleporter, false)

	local group = teleporter:Group()
	if not group then return end

	local groupInstances = level:getGroupedInstances(group)
	local len = #groupInstances
	if len == 0 then return end

	self.debounce:set(level, true)
	teleporter:Debounced(true)
	self.Activation.Enabled(teleporter, false)
	task.delay(teleporter:Cooldown(), function(self: typeof(self), teleporter: TeleporterMechanic)
		teleporter:Debounced(false)
		self.Activation.Enabled(teleporter, true)
	end, self, teleporter)

	math.randomseed(os.clock())
	local targetDestination = groupInstances[if len == 1 then 1 else math.random(1, len)]
	if not targetDestination:IsA "BasePart" then
		logger:Warn("Expected teleporter destination", targetDestination:GetFullName(), "to be a BasePart")
		return
	end

	if self.Sound.Play(teleporter) then
		sounds.playInstance(self.Sound, teleporter.instance, teleporter.instanceConfiguration, assets.sfx.teleport)
	end

	teleport.teleport {
		teleporter = teleporter.instance,
		teleporterConfiguration = teleporter.instanceConfiguration or teleporter.instance,
		teleporterLife = teleporter.life,

		target = root,
		destination = targetDestination,

		attributes = self.Teleport,
		seamlessAttributes = self.Seamless,
		tweenAttributes = self.Transition,
	}

	self.debounce:set(level, false)
end

return Teleporter
