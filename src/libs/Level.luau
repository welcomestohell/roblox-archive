local HttpService = game:GetService("HttpService")

local Life = require("@libs/Life")
local Promise = require("@pkgs/Promise")
local Result = require("@libs/Result")
local activation = require("./activation")
local functions = require("./functions")
local gt = require("@libs/gt")
local mechanics = require("./mechanics")

local LevelInstance = gt.build(gt.instanceTree({
	Mechanics = gt.Instance(),
	Scripts = gt.Instance(),
	SpawnCharacter = gt.isA.BasePart(),
	SpawnCamera = gt.optional(gt.isA.BasePart()),
}))

export type LevelInstance = typeof(LevelInstance:type())

export type NewLevelError = { id: "invalidInstance", cause: gt.Cause }

local Level = {}
Level.__index = Level
Level.baseScripts = {}
Level.baseMechanicImplementations = {}

export type Level = setmetatable<{
	life: Life.Life,
	inheritedLevels: { Level },

	name: string,
	instance: LevelInstance,
	scripts: { [ModuleScript]: unknown },
	startTimestamp: number,

	mechanics: { mechanics.Mechanic },
	mechanicImplementations: { mechanics.MechanicImplementation },
	mechanicImplementationsByTags: { [string]: { mechanics.MechanicImplementation } },
	mechanicsByImplementations: { [mechanics.MechanicImplementation]: { mechanics.Mechanic } },
}, typeof(Level)>

function Level.new(outerLife: Life.Life, name: string, instance: Instance): Result.Result<Level, NewLevelError>
	local instanceCause: gt.Cause = LevelInstance:_matches(instance)

	if instanceCause.ok then
		local self: Level = setmetatable({
			life = outerLife:inner(),
			inheritedLevels = {},

			name = name,
			instance = instance :: LevelInstance,
			scripts = table.clone(Level.baseScripts),
			startTimestamp = os.clock(),

			mechanics = {},
			mechanicImplementations = table.clone(Level.baseMechanicImplementations),
			mechanicImplementationsByTags = {},
			mechanicsByImplementations = {},
		}, Level)

		return Result.Ok(self)
	end

	return Result.Err({ id = functions.literal "invalidInstance", cause = instanceCause } :: NewLevelError)
end

function Level.inherit(outerLevel: Level, name: string, instance: Instance): Result.Result<Level, NewLevelError>
	local instanceCause: gt.Cause = LevelInstance:_matches(instance)

	if instanceCause.ok then
		local self: Level = setmetatable({
			life = outerLevel.life:inner(),
			inheritedLevels = {},

			name = name,
			instance = instance :: LevelInstance,
			scripts = table.clone(Level.baseScripts),
			startTimestamp = os.clock(),

			mechanics = {},
			mechanicImplementations = table.clone(Level.baseMechanicImplementations),
			mechanicImplementationsByTags = {},
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
	mechanicImplementationsByTags: { [string]: { mechanics.MechanicImplementation } }
)
	for _, instance in parent:GetDescendants() do
		if not instance:IsA("ModuleScript") then
			continue
		end

		local requireSuccess, required = pcall(require, instance)
		if not requireSuccess then
			continue
		end

		local isMechanicImplementation = mechanics.isMechanicImplementation(required)
		local isScript = isMechanicImplementation

		if isScript then
			scripts[instance] = required
		end

		if isMechanicImplementation then
			mechanicImplementationsByTags[required.instanceTag] = mechanicImplementationsByTags[required.instanceTag]
				or {}

			table.insert(mechanicImplementationsByTags[required.instanceTag], required)
		end
	end
end

function Level.loadMechanicsFromInstance(self: Level, instance: Instance)
	for _, tag: string in instance:GetTags() do
		local implementations = self.mechanicImplementationsByTags[tag]
		if implementations then
			for _, implementation in implementations do
				local instanceConfiguration = instance
				if instance.ClassName == "Configuration" then
					instanceConfiguration, instance = instance, instance.Parent :: Instance
				end

				if implementation.instanceCheck then
					local instanceCheck = gt.build(implementation.instanceCheck)
					local isValid, reason = instanceCheck:matches(instance)
					if not isValid then
						warn("Failed to validate Mechanic instance because:", reason:formatErr())
						continue
					end
				end

				local mechanicLife = self.life:inner()
				mechanicLife:add(instance)

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

function Level.getMechanics<Instance>(
	self: Level,
	implementation: mechanics.MechanicImplementation<any, Instance>
): { mechanics.Mechanic<Instance> }
	return self.mechanicsByImplementations[implementation] or {}
end

function Level.start(self: Level)
	self.startTimestamp = os.clock()

	self.life:add(self.instance)
	self.life:tie(self.instance.Destroying)

	local levelInstance = self.instance :: Instance
	local levelScripts = levelInstance:FindFirstChild("Scripts")
	if levelScripts then
		Level.collectScripts(levelScripts, self.scripts, self.mechanicImplementationsByTags)
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
		if mechanic.implementation.onMechanize then
			self.life:add(task.spawn(mechanic.implementation.onMechanize, mechanic.implementation, mechanic, self))
		end
	end
end

return table.freeze(Level)
