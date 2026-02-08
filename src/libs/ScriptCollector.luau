local Mechanic = require("./Mechanic")

local ScriptCollector = {}
ScriptCollector.__index = ScriptCollector

export type ScriptCollector = setmetatable<{
	mechanicImplementations: { Mechanic.MechanicImplementation },
	mechanicImplementationsByTag: { [string]: { Mechanic.MechanicImplementation } },
}, typeof(ScriptCollector)>

function ScriptCollector.new(): ScriptCollector
	return setmetatable({
		mechanicImplementations = {},
		mechanicImplementationsByTag = {},
	}, ScriptCollector)
end

function ScriptCollector.tryMechanicImplementation(
	self: ScriptCollector,
	implementation: Mechanic.MechanicImplementation
)
	if Mechanic.isMechanicImplementation(implementation) then
		local tagged = self.mechanicImplementationsByTag[implementation.instanceTag]
		if not tagged then
			tagged = {}
			self.mechanicImplementationsByTag[implementation.instanceTag] = tagged
		end
		table.insert(tagged, implementation)
		table.insert(self.mechanicImplementations, implementation)
	end
end

function ScriptCollector.tryRegister(self: ScriptCollector, x: any)
	self:tryMechanicImplementation(x)
end

function ScriptCollector.tryInstance(self: ScriptCollector, instance: Instance)
	if not instance:IsA("ModuleScript") then
		return
	end

	local requireSuccess, required = pcall(require, instance)
	if not requireSuccess then
		return
	end

	self:tryRegister(required)
end

function ScriptCollector.tryInstances(self: ScriptCollector, instances: { Instance })
	for _, instance in instances do
		self:tryInstance(instance)
	end
end

function ScriptCollector.clone(self: ScriptCollector): ScriptCollector
	return setmetatable({
		mechanicImplementations = table.clone(self.mechanicImplementations),
		mechanicImplementationsByTag = table.clone(self.mechanicImplementationsByTag),
	}, ScriptCollector)
end

return table.freeze(ScriptCollector)
