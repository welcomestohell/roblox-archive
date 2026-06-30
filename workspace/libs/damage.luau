const net = require "@core/client/generated/net"
const Attribute = require "@libs/attributes/Attribute"
const instances = require "@libs/instances"
const gt = require "@libs/vendor/gt"

const damage = {
	EVENT = net.mechanics.damage,
	PRESET_DAMAGES = table.freeze {
		Base = 10,
		Doubled = 20,
		Quadrupled = 40,
		Lethal = math.huge,
	},
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

function damage.damageFromAttributes(attributes: DamageAttributes, instance: instances.InstanceLike)
	damage.EVENT.fire {
		mode = attributes.Mode(instance),
		value = attributes.Value(instance),
		preset = attributes.Preset(instance),
		measurement = attributes.Measurement(instance),
		asHeal = attributes.AsHeal(instance),
	}
end

export type DamageAttributes = typeof(damage.useAttributes())
export type DamageMode = typeof(damage.useAttributes().Mode:type())
export type DamagePreset = typeof(damage.useAttributes().Preset:type())
export type DamageMeasurement = typeof(damage.useAttributes().Measurement:type())

return table.freeze(damage)
