local activation = require "@libs/activation"
local std = require "@libs/std"

--[=[
	@class Activator
	@tag Mechanic

	Activates the group when the Activator mechanic is activated. It's most
	useful in Contraptions.
]=]
local Activator = std.Mechanic {}
export type ActivatorMechanic = std.Mechanic<typeof(Activator)>
Activator.mechanicName = "Activator"
Activator.instanceType = std.gt.instanceTree {
	Target = std.gt.optional(std.isA.ObjectValue()),
}
Activator.debuggerEmoji = "👆"

Activator.Enabled = Activator:attribute("Enabled", std.gt.boolean(), true)
Activator.Cooldown = Activator:attribute("Cooldown", std.gt.positiveNumber, 0)
Activator.Group = Activator:attribute("Group", std.gt.string(), "")

Activator:attributeSection "Activation"
Activator.Activation = activation.useAttributes(Activator)

function Activator.tryActivate(instance: Instance, level: std.Level)
	local mechanics = level.mechanicsByInstance[instance]
	if mechanics then
		for _, mechanic in mechanics :: { std.Mechanic<std.AnyMechanicImplementation> } do
			if type(mechanic.onActivate) == "function" then
				mechanic.onActivate(mechanic.implementation, mechanic :: any, level, { type = "Activator" })
			end
		end
	end
end

function Activator.onActivate(self: typeof(Activator), activator: ActivatorMechanic, level: std.Level)
	if not activator:Enabled() then return end

	self.Activation.Enabled(activator, false)

	local targetInstance = activator.instance.Target
	if targetInstance then self.tryActivate(targetInstance, level) end

	for _, grouped in level:getGroupedInstances(self:Group()) do
		self.tryActivate(grouped, level)
	end

	task.wait(activator:Cooldown())
	self.Activation.Enabled(activator, true)
end

return Activator
