-- -- TODO: Mechanic's type is completely fucked please fix

-- local Attribute = require("@libs/Attribute")
-- local Life = require("./Life")
-- local activation = require("./activation")

-- export type MechanicMetatable = typeof(activation.attributes) & {
-- 	type: "Mechanic",

-- 	new: <I>(
-- 		instanceTag: string,
-- 		parentCheck: I
-- 	) -> <T>(implementation: BaseMechanicImplementation<T>) -> MechanicImplementation<T, I>,

-- 	isMechanicImplementation: (any) -> boolean,
-- 	isMechanic: (any) -> boolean,
-- 	isMechanicImplementationOf: (any) -> boolean,
-- 	isMechanicOf: (any) -> boolean,

-- 	Enabled: Attribute.Attribute<boolean>,
-- }

-- export type MechanicImplementation<Self = {}, InstanceType = Instance> = Self & BaseMechanicImplementation & {
-- 	super: any?,
-- 	overriden: any?,

-- 	instanceTag: string,
-- 	instanceCheck: InstanceType,
-- }

-- export type BaseMechanicImplementation = {
-- 	onInit: (self: never)?,
-- 	onStart: any?,
-- 	onActivated: any?,
-- }

-- export type Mechanic<Implementation = BaseMechanicImplementation> = index<Implementation, "_T">

-- export type LevelInstance = Instance & {
-- 	Mechanics: Instance,
-- 	Scripts: Instance,
-- 	SpawnCharacter: BasePart,
-- 	SpawnCamera: BasePart,
-- }

-- export type LevelSelf = {
-- 	life: Life.Life,
-- 	name: string,
-- 	instance: LevelInstance,
-- 	scripts: { [ModuleScript]: any },
-- 	mechanicImplementations: { [string]: MechanicImplementation },
-- 	mechanics: { Mechanic<any> },
-- 	mechanicsByImplementations: { [MechanicImplementation]: { Mechanic<any> } },
-- 	inheritedLevels: { Level },
-- 	loadedTimestamp: number,
-- }

-- export type LevelMetatable = {
-- 	__index: LevelMetatable,
-- 	__tostring: (self: Level) -> string,

-- 	type: "Level",

-- 	new: (life: Life.Life, name: string, instance: LevelInstance) -> Level,
-- 	inherit: (self: Level, name: string, instance: LevelInstance) -> Level,

-- 	loadMechanicsFromInstance: (self: Level, instance: Instance) -> (),
-- 	start: (self: Level) -> (),

-- 	baseScripts: { [ModuleScript]: any },
-- 	baseMechanicImplementations: { [string]: MechanicImplementation },
-- 	collectScripts: (
-- 		parent: Instance,
-- 		scripts: { [ModuleScript]: any },
-- 		mechanicImplementations: { [string]: MechanicImplementation }
-- 	) -> (),

-- 	getLifetime: (self: Level) -> number,
-- 	getMechanics: <T>(self: Level, implementation: T) -> Mechanic<T>,
-- }

-- export type Level = setmetatable<LevelSelf, LevelMetatable>

-- return nil
