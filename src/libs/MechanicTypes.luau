-- TODO: Mechanic's type is completely fucked please fix

local Attribute = require("@libs/Attribute")
local Life = require("./Life")

export type MechanicMetatable = {
	__index: MechanicMetatable,
	__tostring: (BaseMechanicImplementation<any>) -> string,

	type: "Mechanic",

	new: <I>(
		instanceTag: string,
		parentCheck: I
	) -> <T>(implementation: BaseMechanicImplementation<T>) -> MechanicImplementation<T, I>,

	isMechanicImplementation: (any) -> boolean,
	isMechanic: (any) -> boolean,
	isMechanicImplementationOf: (any) -> boolean,
	isMechanicOf: (any) -> boolean,

	Enabled: Attribute.Attribute<boolean>,
}

-- type function merge(intersection: type)
-- 	local components = intersection:components()
-- 	local result = types.newtable()
-- 	for _, component in components do
-- 		local table: type = if component.tag == "intersection" then merge(component) else component
-- 		for key, value in table:properties() do
-- 			if value.read then
-- 				result:setreadproperty(key, value.read)
-- 			end

-- 			if value.write then
-- 				result:setreadproperty(key, value.write)
-- 			end
-- 		end
-- 	end
-- 	return result
-- end

export type MechanicImplementation<Self = {}, InstanceType = Instance> = setmetatable<
	BaseMechanicImplementation<Self> & {
		-- Due to restrictions with Luau, using the correct types here breaks
		-- the type solver. Therefore we have to cast with any.
		super: any?,
		overriden: any?,

		instanceTag: string,
		instanceCheck: InstanceType,

		_T: BaseMechanicImplementation<Self> & {
			super: any?,
			overriden: any?,

			instanceTag: string,
			instanceCheck: InstanceType,

			id: string,
			implementation: any,
			instance: InstanceType,
			instanceConfiguration: Instance,
			life: Life.Life,
			level: any,
		},
	},
	MechanicMetatable
>

export type BaseMechanicImplementation<Self = {}> = Self & {
	[any]: any,
	__index: Self,
	onInit: any?,
	onStart: any?,
	onActivated: any?,
}

-- export type MechanicSelf<Implementation> = {
-- 	id: string,
-- 	implementation: Implementation,
-- 	instance: index<Implementation, "parentCheck">,
-- 	instanceConfiguration: Instance,
-- 	life: Life.Life,
-- 	level: Level,
-- }

-- todo luau is explosive as fuck
-- FIXME: shit doesnt infer implementation type??
export type Mechanic<Implementation = BaseMechanicImplementation> = index<Implementation, "_T">

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
	mechanicImplementations: { [string]: MechanicImplementation },
	mechanics: { Mechanic<any> },
	mechanicsByImplementations: { [MechanicImplementation]: { Mechanic<any> } },
	inheritedLevels: { Level },
	loadedTimestamp: number,
}

export type LevelMetatable = {
	__index: LevelMetatable,
	__tostring: (self: Level) -> string,

	type: "Level",

	new: (life: Life.Life, name: string, instance: LevelInstance) -> Level,
	inherit: (self: Level, name: string, instance: LevelInstance) -> Level,

	loadMechanicsFromInstance: (self: Level, instance: Instance) -> (),
	start: (self: Level) -> (),

	baseScripts: { [ModuleScript]: any },
	baseMechanicImplementations: { [string]: MechanicImplementation },
	collectScripts: (
		parent: Instance,
		scripts: { [ModuleScript]: any },
		mechanicImplementations: { [string]: MechanicImplementation }
	) -> (),

	getLifetime: (self: Level) -> number,
	getMechanics: <T>(self: Level, implementation: T) -> Mechanic<T>,
}

export type Level = setmetatable<LevelSelf, LevelMetatable>

return nil
