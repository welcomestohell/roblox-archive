local gt = require "@pkgs/gt"
local types = require "../types"

-- TODO: extend, override, xOf functions
local Mechanic = {} :: types.MechanicMetatable
Mechanic.__index = Mechanic
Mechanic.type = "Mechanic"

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

function Mechanic.new<InstanceType>(instanceTag: string, instanceType: InstanceType)
	return function<T>(implementation: types.BaseMechanicImplementation<T>): types.MechanicImplementation<T, InstanceType>
		local self = table.clone(implementation)
		self.__index = self
		self.type = "Mechanic"
		self.instanceTag = instanceTag
		self.instanceType = instanceType or gt.Instance()
		return setmetatable(self, Mechanic) :: any
	end
end

table.freeze(Mechanic)
return Mechanic
