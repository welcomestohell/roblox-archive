local Attribute = require("@libs/Attribute")
local MechanicTypes = require("./MechanicTypes")
local gt = require("@pkgs/gt")

export type Level = MechanicTypes.Level
export type Mechanic<Implementation> = MechanicTypes.Mechanic<Implementation>
export type MechanicImplementation<Self = {}, InstanceType = Instance> = MechanicTypes.MechanicImplementation<
	Self,
	InstanceType
>

-- TODO: extend, override, xOf functions
local Mechanic = {} :: MechanicTypes.MechanicMetatable
Mechanic.__index = Mechanic
Mechanic.type = "Mechanic"

Mechanic.Enabled = Attribute.new("Enabled", gt.boolean(), false)

function Mechanic.isMechanicImplementation(x: any): boolean
	return typeof(x) == "table" and x.type == "Mechanic"
end

function Mechanic.isMechanic(x: any): boolean
	if typeof(x) == "table" then
		local metatable = getmetatable(x)
		return Mechanic.isMechanicImplementation(metatable)
	end
	return false
end

function Mechanic.isMechanicImplementationOf() end

function Mechanic.isMechanicOf() end

function Mechanic.new<InstanceType>(instanceTag: string, instanceCheck: InstanceType)
	return function<T>(
		implementation: MechanicTypes.BaseMechanicImplementation<T>
	): MechanicTypes.MechanicImplementation<T, InstanceType>
		local self = table.clone(implementation)
		self.__index = self
		self.type = "Mechanic"
		self.instanceTag = instanceTag
		self.instanceCheck = instanceCheck or gt.Instance()
		setmetatable(self, Mechanic)
		return self :: any
	end
end

return table.freeze(Mechanic)
