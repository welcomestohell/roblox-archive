const Lazy = require "@libs/Lazy"
const Attribute = require "@libs/attributes/Attribute"
const Level = require "@libs/core/Level"
const LevelState = require "@libs/core/LevelState"
const instances = require "@libs/instances"
const gt = require "@libs/vendor/gt"

const damage = {
	DEBOUNCE_COOLDOWN = 0.5,
	PRESET_DAMAGES = table.freeze {
		Base = 10,
		Doubled = 20,
		Quadrupled = 40,
		Lethal = math.huge,
	},

	isDebounced = LevelState.new(false),
	fire = Lazy.new(function()
		const net = require "@core/client/generated/net"
		return net.mechanics.damage.fire
	end),
}

function damage.useAttributes(basename: string?)
	basename = basename or "Damage"
	return {
		Mode = Attribute.new(basename .. "Mode", gt.literals { "Value", "Preset" }, "Preset" :: "Preset"),
		Value = Attribute.new(basename .. "Value", gt.optional(gt.positiveNumber), nil),
		Preset = Attribute.new(basename .. "Preset", gt.optional(gt.keysOf(damage.PRESET_DAMAGES)), "Base" :: "Base"),
		Measurement = Attribute.new(basename .. "Measurement", gt.literals { "Raw", "Scaled" }, "Raw" :: "Raw"),
		AsHeal = Attribute.new(basename .. "AsHeal", gt.boolean(), false),
	}
end

function damage.debounce(level: Level.Level)
	if damage.isDebounced:get(level) then return end
	damage.isDebounced:set(level, true)
	level.life:delay(damage.DEBOUNCE_COOLDOWN, function(damage: typeof(damage), level)
		damage.isDebounced:set(level, false)
	end, damage, level)
end

function damage.alwaysFireFromAttributes(attributes: DamageAttributes, instance: instances.InstanceLike)
	damage.fire:get() {
		mode = attributes.Mode(instance),
		value = attributes.Value(instance),
		preset = attributes.Preset(instance),
		measurement = attributes.Measurement(instance),
		asHeal = attributes.AsHeal(instance),
	}
end

function damage.fireFromAttributes(attributes: DamageAttributes, instance: instances.InstanceLike, level: Level.Level)
	if damage.isDebounced:get(level) then damage.alwaysFireFromAttributes(attributes, instance) end
end

export type DamageAttributes = typeof(damage.useAttributes())
export type DamageMode = typeof(damage.useAttributes().Mode:type())
export type DamagePreset = typeof(damage.useAttributes().Preset:type())
export type DamageMeasurement = typeof(damage.useAttributes().Measurement:type())

return table.freeze(damage)
