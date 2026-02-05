local Life = require("@libs/Life")
local gt = require("@libs/gt")

local MechanicImplementation = {}
MechanicImplementation.__index = MechanicImplementation

export type Mechanic<Self = any, Instance = any> = {
	life: Life.Life,
	id: string,
	implementation: MechanicImplementation<Self, Instance>,
	instance: Instance,
	instanceConfiguration: Instance?,
	instanceActivationConfiguration: Instance?,
}

export type BaseMechanicImplementation<Instance = any> = {
	[any]: any,

	onInit: (self: any, level: any) -> ()?,

	onMechanize: (self: any, mechanic: any, level: any) -> ()?,
	onActivate: (self: any, mechanic: any, level: any) -> ()?,

	onPreRender: (self: any, deltaTime: number, level: any) -> ()?,
	onPreAnimation: (self: any, deltaTime: number, level: any) -> ()?,
	onPreSimulation: (self: any, deltaTime: number, level: any) -> ()?,
	onPostSimulation: (self: any, deltaTime: number, level: any) -> ()?,
}

export type MechanicImplementation<Self = any, Instance = any> =
	& BaseMechanicImplementation<Instance>
	& typeof(MechanicImplementation)
	& Self
	& {
		instanceTag: string,
		instanceType: Instance,
	}

local LevelInstance = gt.build(gt.instanceTree({
	Mechanics = gt.Instance(),
	Scripts = gt.Instance(),
	SpawnCharacter = gt.isA.BasePart(),
	SpawnCamera = gt.optional(gt.isA.BasePart()),
}))

export type LevelInstance = typeof(LevelInstance:type())

export type Level = {
	life: Life.Life,
	inheritedLevels: { Level },

	name: string,
	instance: LevelInstance,
	scripts: { [string]: any },
	startTimestamp: number,

	mechanics: { Mechanic },
	mechanicImplementationsByTags: { [string]: { MechanicImplementation } },
	mechanicsByImplementations: { [MechanicImplementation]: { Mechanic } },
}

function MechanicImplementation.__tostring(self: MechanicImplementation)
	return self.instanceTag
end

function MechanicImplementation.extend()
	error("not yet implemented")
end

function MechanicImplementation.replace()
	error("not yet implemented")
end

local function Mechanic<Instance>(instanceTag: string, instanceType: Instance)
	return function<T>(implementation: T & BaseMechanicImplementation<Instance>): MechanicImplementation<T>
		local self = table.clone(implementation)
		self.instanceTag = instanceTag
		self.instanceType = instanceType
		setmetatable(self, MechanicImplementation)
		return self :: any
	end
end

local function isMechanicImplementation(x: any)
	return typeof(x) == "table" and getmetatable(x) == MechanicImplementation
end

local function isMechanic(x: any)
	return typeof(x) == "table" and isMechanicImplementation(getmetatable(x))
end

return table.freeze {
	Mechanic = Mechanic,
	isMechanicImplementation = isMechanicImplementation,
	isMechanic = isMechanic,
}
