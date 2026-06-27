const activation = require "@libs/activation"
const character = require "@libs/character"
const mounts = require "@libs/mounts"
const std = require "@libs/std"
const Signal = require "@pkgs/Signal"

const Dismounter = std.Mechanic {
	emoji = "⏏️",
	name = "Dismounter",
	description = "When activated, dismounts the activator from the given mounts.",
	instanceType = std.isA.Instance(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes "Activation",

	std.AttributeSection "Dismount",
	DismountAll = std.Attribute("DismountAll", std.gt.boolean(), true),
	Dismount = std.AttributeMap<<boolean>>("Dismount", std.gt.boolean()),

	onDismount = Signal.new<<(string)>>(),
}

export type Dismounter = typeof(Dismounter)
export type DismounterMechanic = std.Mechanic<Dismounter>

function Dismounter.onActivate(self: Dismounter, dismounter: DismounterMechanic, _, event: activation.ActivationEvent)
	const wasActivatable = self.Activation.Enabled(dismounter)
	self.Activation.Enabled(dismounter, false)
	dismounter:Debounced(true)

	-- stylua: ignore
	const activator = mounts.castToucher(event.kind == "Touch" and event.toucher or character.getHumanoidRootPart()) :: BasePart

	const dismountMap = self.Dismount:getAll(dismounter)
	const dismountAll = dismounter:DismountAll()
	for _, mounter in mounts.getInstanceMounts(activator) do
		if dismountAll or dismountMap[mounter.name] then mounter.onDismount:Fire() end
	end

	dismounter.life:delay(
		dismounter:Cooldown(),
		function(self: typeof(self), dismounter: typeof(dismounter), wasActivatable: typeof(wasActivatable))
			self.Activation.Enabled(dismounter, wasActivatable)
			dismounter:Debounced(false)
		end,
		self,
		dismounter,
		wasActivatable
	)
end

return Dismounter
