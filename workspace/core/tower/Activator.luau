local Signal = require "@pkgs/Signal"
local activation = require "@libs/activation"
local std = require "@libs/std"

local Activator = std.Mechanic {
	emoji = "👆",
	name = "Activator",
	description = "When activated, activates mechanics tagged with it's Group.",
	instanceType = std.gt.instanceTree { Target = std.gt.optional(std.isA.ObjectValue()) },

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Group = std.Attribute("Group", std.gt.optional(std.gt.group), nil),
	Tag = std.Attribute("Tag", std.gt.tag, ""),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	onActivatedSignal = Signal.new<<(ActivatorMechanic)>>(),
}

export type ActivatorMechanic = std.Mechanic<typeof(Activator)>

local function shouldActivate(context: activation.ActivationContext, activator: ActivatorMechanic)
	local group = activator:Group()
	local targetInstance = activator.instance:FindFirstChild "Target"

	return group and group == Activator.Group(context.instanceConfiguration)
		or context.instanceConfiguration:HasTag(activator:Tag())
		or targetInstance
			and targetInstance:IsA "ObjectValue"
			and (targetInstance.Value == context.instance or targetInstance.Value == context.instanceConfiguration)
end

local function implementActivatorMode(context: activation.ActivationContext)
	Activator.onActivatedSignal:Connect(function(activator: ActivatorMechanic)
		if shouldActivate(context, activator) then
			context:onActivate(activation.castEvent { kind = "Activator", mechanic = activator })
		end
	end)
end

activation
	.registerMode("Activator", { implement = implementActivatorMode })
	:expect "Failed to regiser activation mode for Activator"

function Activator.onActivate(self: typeof(Activator), activator: ActivatorMechanic, level: std.Level)
	if activator:Debounced() then return end
	activator:Debounced(true)

	local wasActivatable = self.Activation.Enabled(activator)
	self.Activation.Enabled(activator, false)

	self.onActivatedSignal:Fire(activator)

	activator.life:delay(activator:Cooldown(), function(activator: typeof(activator))
		activator.Activation.Enabled(activator, wasActivatable)
		activator:Debounced(false)
	end, activator)
end

return Activator
