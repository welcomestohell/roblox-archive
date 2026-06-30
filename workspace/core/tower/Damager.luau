const activation = require "@libs/activation"
const damage = require "@libs/damage"
const emission = require "@libs/emission"
const std = require "@libs/std"

const Damager = std.Mechanic {
	name = "Damager",
	description = "When activated, damages the player.",
	instanceType = std.isA.Instance(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Damage = damage.useAttributes(),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Emission",
	EmitActivatedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Damager: On Activated"),
}

export type DamagerSelf = typeof(Damager)
export type DamagerMechanic = std.Mechanic<DamagerSelf>

function Damager.onActivate(self: DamagerSelf, damager: DamagerMechanic, level: std.Level)
	if damager:Debounced() or damage.isDebounced:get(level) then return end
	damager:Debounced(true)
	damage.debounce(level)

	const wasActivatable = self.Activation.Enabled(damager)
	self.Activation.Enabled(damager, false)

	damager.life:delay(damager:Cooldown(), function(damager: DamagerMechanic, wasActivatable)
		damager.Activation.Enabled(damager, wasActivatable)
		damager:Debounced(false)
	end, damager, wasActivatable)

	damage.alwaysFireFromAttributes(self.Damage, damager)
	emission.emitTaggedDescendants(damager.instance, damager:EmitActivatedTag())
end

return Damager
