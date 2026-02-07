local HttpService = game:GetService("HttpService")

local Life = require("@libs/Life")
local Mechanic = require("./Mechanic")
local Promise = require("@pkgs/Promise")
local Result = require("@libs/Result")
local activation = require("./activation")
local functions = require("./functions")
local gt = require("@libs/gt")

local LevelInstance = gt.build(gt.instanceTree(gt.Instance(), {
	Mechanics = gt.Instance(),
	Scripts = gt.optional(gt.Instance()),
	SpawnCharacter = gt.isA.BasePart(),
	SpawnCamera = gt.optional(gt.isA.BasePart()),
}))

export type LevelInstance = typeof(LevelInstance:type())
export type NewLevelError = { id: "invalidInstance", cause: gt.Cause }

type Mechanic<Self = any> = Mechanic.Mechanic<Self>
type MechanicMetadata = Mechanic.MechanicImplementationMetadata
type MechanicImplementationLike = Mechanic.MechanicImplementation

local Level = {}
Level.__index = Level
Level.baseScripts = {} :: { [ModuleScript]: unknown }
Level.baseMechanicImplementations = {} :: { [string]: { MechanicImplementationLike } }
Level.LevelInstance = LevelInstance

export type Level = setmetatable<{
	life: Life.Life,
	inheritedLevels: { Level },

	name: string,
	instance: LevelInstance,
	scripts: { [ModuleScript]: unknown },
	startTimestamp: number,

	mechanics: { Mechanic },
	mechanicImplementations: { MechanicImplementationLike },
	mechanicImplementationsByTag: { [string]: { MechanicImplementationLike } },
	mechanicsByImplementations: { [MechanicImplementationLike]: { Mechanic } },
}, typeof(Level)>

function Level.new(outerLife: Life.Life, name: string, instance: Instance): Result.Result<Level, NewLevelError>
	local instanceCause: gt.Cause = LevelInstance._matches(instance)

	if instanceCause.ok then
		local self: Level = setmetatable({
			life = outerLife:inner(),
			inheritedLevels = {},

			name = name,
			instance = instance :: LevelInstance,
			scripts = table.clone(Level.baseScripts),
			startTimestamp = os.clock(),

			mechanics = {},
			mechanicImplementations = table.clone(Level.baseMechanicImplementations) :: any,
			mechanicImplementationsByTag = table.clone(Level.baseMechanicImplementations) :: any,
			mechanicsByImplementations = {},
		}, Level)

		return Result.Ok(self)
	end

	return Result.Err({ id = functions.literal "invalidInstance", cause = instanceCause } :: NewLevelError)
end

function Level.inherit(outerLevel: Level, name: string, instance: Instance): Result.Result<Level, NewLevelError>
	print(instance)
	local instanceCause: gt.Cause = LevelInstance._matches(instance)

	if instanceCause.ok then
		local self: Level = setmetatable({
			life = outerLevel.life:inner(),
			inheritedLevels = {},

			name = name,
			instance = instance :: LevelInstance,
			scripts = table.clone(Level.baseScripts),
			startTimestamp = os.clock(),

			mechanics = {},
			mechanicImplementations = table.clone(Level.baseMechanicImplementations) :: any,
			mechanicImplementationsByTag = table.clone(Level.baseMechanicImplementations) :: any,
			mechanicsByImplementations = {},
		}, Level)

		table.insert(outerLevel.inheritedLevels, self)

		self.life:add(function()
			table.remove(outerLevel.inheritedLevels, table.find(outerLevel.inheritedLevels, self))
		end)

		return Result.Ok(self)
	end

	return Result.Err({ id = functions.literal "invalidInstance", cause = instanceCause } :: NewLevelError)
end

function Level.isLevel(x: any)
	return typeof(x) == "table" and getmetatable(x) == Level
end

function Level.collectScripts(
	parent: Instance,
	scripts: { [ModuleScript]: unknown },
	mechanicImplementationsByTag: { [string]: { MechanicImplementationLike } }
)
	for _, instance in parent:GetDescendants() do
		if not instance:IsA("ModuleScript") then
			continue
		end

		local requireSuccess, required = pcall(require, instance)
		if not requireSuccess then
			continue
		end

		local isMechanicImplementation = Mechanic.isMechanicImplementation(required)
		local isScript = isMechanicImplementation

		if isScript then
			scripts[instance] = required
		end

		if isMechanicImplementation then
			mechanicImplementationsByTag[required.instanceTag] = mechanicImplementationsByTag[required.instanceTag]
				or {}

			table.insert(mechanicImplementationsByTag[required.instanceTag], required)
			print("got mech impl", required.instanceTag, mechanicImplementationsByTag[required.instanceTag])
		end
	end
end

function Level.loadMechanicsFromInstance(self: Level, instance: Instance)
	for _, tag: string in instance:GetTags() do
		local implementations = self.mechanicImplementationsByTag[tag]
		print("??? WHAT", implementations)
		if implementations then
			for _, implementation in implementations do
				print(implementation, "???")
				local instanceConfiguration = instance
				if instance.ClassName == "Configuration" then
					instanceConfiguration, instance = instance, instance.Parent :: Instance
				end

				if implementation.instanceType then
					local instanceType = gt.build(implementation.instanceType)
					local isValid, reason = instanceType:matches(instance)
					if not isValid then
						warn("Failed to validate Mechanic instance because:", reason:formatErr())
						continue
					end
				end

				local mechanicLife = self.life:inner()
				mechanicLife:add(instance)

				print("GOT MECHANIC", instance)

				local mechanic = {
					id = HttpService:GenerateGUID(false),
					implementation = implementation,
					instance = instance,
					instanceConfiguration = instanceConfiguration,
					life = mechanicLife,
					level = self,
				}

				setmetatable(mechanic, implementation)
				table.insert(self.mechanics :: any, mechanic)
				self.mechanicsByImplementations[implementation] = self.mechanicsByImplementations[implementation] or {}
				table.insert(self.mechanicsByImplementations[implementation] :: any, mechanic)

				if implementation.onActivate then
					activation.onActivated(
						mechanicLife,
						mechanic.instance,
						mechanic.instanceConfiguration or mechanic.instance,
						function()
							implementation.onActivate(mechanic, self)
						end
					)
				end
			end
		end
	end
end

function Level.getLifetime(self: Level)
	return os.clock() - self.startTimestamp
end

function Level.getMechanics<Self>(self: Level, implementation: Self): { Mechanic.Mechanic<Self> }
	return self.mechanicsByImplementations[implementation] :: any or {}
end

function Level.start(self: Level)
	self.startTimestamp = os.clock()

	self.life:add(self.instance)
	self.life:tie(self.instance.Destroying)

	local levelInstance = self.instance :: Instance
	local levelScripts = levelInstance:FindFirstChild("Scripts")
	if levelScripts then
		Level.collectScripts(levelScripts, self.scripts, self.mechanicImplementationsByTag)
	end

	for _, instance in self.instance:WaitForChild("Mechanics"):GetDescendants() do
		self:loadMechanicsFromInstance(instance)
	end

	local initThreads: { Promise.Promise } = {}
	for _, implementation in self.mechanicImplementations do
		if implementation.onInit then
			table.insert(
				initThreads,
				Promise.try(implementation.onInit :: any, implementation, self) :: Promise.Promise
			)
		end
	end

	Promise.all(initThreads)
		:catch(function(e)
			warn("Mechanic failed to initialize:", e)
		end)
		:await()

	for _, mechanic in self.mechanics do
		if mechanic.implementation.onStart then
			self.life:add(task.spawn(mechanic.implementation.onStart, mechanic.implementation, mechanic, self))
		end
	end
end

return table.freeze(Level)
