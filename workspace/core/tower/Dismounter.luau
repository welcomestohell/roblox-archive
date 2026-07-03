local activation = require "@libs/activation"
local character = require "@libs/character"
local mounts = require "@libs/mounts"
local std = require "@libs/std"
local Signal = require "@pkgs/Signal"

local Dismounter = std.Mechanic {
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
	Dismount = std.AttributeMap("Dismount", std.gt.boolean(), true),

	onDismount = Signal.new<<(string)>>(),
}

export type Dismounter = typeof(Dismounter)
export type DismounterMechanic = std.Mechanic<Dismounter>

function Dismounter.onActivate(self: Dismounter, dismounter: DismounterMechanic, _, event: activation.ActivationEvent)
	local wasActivatable = self.Activation.Enabled(dismounter)
	self.Activation.Enabled(dismounter, false)
	dismounter:Debounced(true)

	-- stylua: ignore
	local activator = mounts.castToucher(event.kind == "Touch" and event.toucher or character.getHumanoidRootPart()) :: BasePart

	local dismountMap = self.Dismount:getAll(dismounter)
	local dismountAll = dismounter:DismountAll()
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
