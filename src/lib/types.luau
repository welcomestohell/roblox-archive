local Life = require "./memory/Life"
local Result = require "./core/Result"
local gt = require "@pkgs/gt"

export type MechanicMetatable = {
	__index: MechanicMetatable,
	__tostring: (BaseMechanicImplementation<any>) -> string,

	type: "Mechanic",

	new: <I>(
		instanceTag: string,
		instanceType: I
	) -> <T>(implementation: BaseMechanicImplementation<T>) -> MechanicImplementation<T, I>,

	isMechanicImplementation: (any) -> boolean,
	isMechanic: (any) -> boolean,
	isMechanicImplementationOf: (any) -> boolean,
	isMechanicOf: (any) -> boolean,
}

export type MechanicImplementation<Self = {}, InstanceType = Instance> = setmetatable<
	BaseMechanicImplementation<Self> & {
		-- Due to restrictions with Luau, using the correct types here breaks
		-- the type solver. Therefore we have to cast with any.
		__index: any,
		super: any?,
		overriden: any?,

		instanceTag: string,
		instanceType: InstanceType,
	},
	MechanicMetatable
>

export type BaseMechanicImplementation<Self = {}> = Self & {
	[any]: any,

	onInit: (self: never) -> ()?,
	onStart: (self: never) -> ()?,
	onActivated: (self: never) -> ()?,
}

export type MechanicSelf<Implementation> = {
	id: string,
	instance: index<Implementation, "instanceType">,
	life: Life.Life,
}

-- See note on `MechanicImplementation.__index`, therefore we have to mock the
-- `__index` property. Ideally you would be able to set `Implementation` as the
-- metatable.
export type Mechanic<Implementation> = setmetatable<MechanicSelf<Implementation>, { __index: Implementation }>

export type LevelInstance = Instance & {
	Mechanics: Instance,
	Scripts: Instance,
	SpawnCharacter: BasePart,
	SpawnCamera: BasePart,
}

export type LevelSelf = {
	life: Life.Life,
	name: string,
	instance: LevelInstance,
	scripts: { [ModuleScript]: any },
	mechanics: { Mechanic<any> },
	mechanicImplementations: { [string]: MechanicImplementation },
}

export type LevelMetatable = {
	__index: LevelMetatable,
	__tostring: (self: Level) -> string,

	baseScripts: { [ModuleScript]: any },
	baseMechanicImplementations: { [string]: MechanicImplementation },
	collectScripts: (
		parent: Instance,
		scripts: { [ModuleScript]: any },
		mechanicImplementations: { [string]: MechanicImplementation }
	) -> (),

	type: "Level",

	loadMechanicsFromInstance: (self: Level, instance: Instance) -> (),
	bootstrap: (self: Level) -> (),

	new: (life: Life.Life, name: string, instance: LevelInstance) -> Level,
	inner: (self: Level, name: string, instance: LevelInstance) -> Level,
}

export type Level = setmetatable<LevelSelf, LevelMetatable>

return nil
