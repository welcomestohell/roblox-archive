local RunService = game:GetService "RunService"

local Life = require "@libs/memory/Life"
local MechanicImplementation = require "@libs/core/MechanicImplementation"
local Promise = require "@roblox_packages/Promise"
local Result = require "@libs/Result"
local ScriptCollector = require "@libs/ScriptCollector"
local gt = require "@libs/gt"
local prvd = require "@prvdmwrong/prvdmwrong"
local tables = require "@libs/collections/tables"

type AnyImplementation = MechanicImplementation.AnyMechanicImplementation
type MechanicImplementation = MechanicImplementation.MechanicImplementation
type Mechanic<Implementation = any, Mixin = {}> = MechanicImplementation.Mechanic<Implementation, Mixin>

local Level = {}
Level.__index = Level
Level.baseScripts = ScriptCollector.new()
Level.activeLevels = {} :: { Level }
Level.LevelInstance = gt.build(gt.instanceTree {
	Mechanics = gt.Instance(),
	Spawn = gt.isA.BasePart(),
})

export type LevelInstance = typeof(Level.LevelInstance:type())

export type Level = setmetatable<{
	life: Life.Life,
	name: string,
	instance: LevelInstance,
	createdTimestamp: number,

	started: boolean,
	startedTimestamp: number,

	scripts: ScriptCollector.ScriptCollector,

	mechanics: { Mechanic<any> },
	mechanicsByImplementations: { [AnyImplementation]: { Mechanic<any> } },
	mechanicsByInstance: { [Instance]: { Mechanic<any> } },

	implementationLifecycles: { [string]: prvd.Lifecycle },
	mechanicLifecycles: { [string]: prvd.Lifecycle },
}, typeof(Level)>

function Level.new(outerLife: Life.Life, name: string, instance: Instance)
	local isInstanceValid, instanceCause = Level.LevelInstance:matches(instance)

	if not isInstanceValid then
		return Result.Err(`Invalid instance: {instanceCause:formatErr()}`)
	end

	local self: Level = setmetatable({
		life = outerLife:extend(),
		name = name,
		instance = instance :: LevelInstance,

		started = false,
		startedTimestamp = os.clock(),

		scripts = Level.baseScripts:clone(),

		mechanics = {},
		mechanicsByImplementations = {},
		mechanicsByInstance = tables.weak "k",

		implementationLifecycles = {
			onInit = prvd.lifecycle("onInit", function(lifecycle: prvd.Lifecycle<Level>, level: any)
				local promises: { Promise.Promise } = {}
				for index, listener in lifecycle.callbacks do
					promises[index] = Promise.try(listener, level):catch(function(e)
						warn(`Failed to initialize mechanic implementation: {e}`)
					end)
				end
				Promise.all(promises):await()
			end),

			onPreRender = prvd.lifecycle<<(number, any)>>("onPreRender", prvd.fireConcurrent),
			onPreAnimation = prvd.lifecycle<<(number, any)>>("onPreAnimation", prvd.fireConcurrent),
			onPreSimulation = prvd.lifecycle<<(number, any)>>("onPreSimulation", prvd.fireConcurrent),
			onPostSimulation = prvd.lifecycle<<(number, any)>>("onPostSimulation", prvd.fireConcurrent),
		},

		mechanicLifecycles = {
			onStart = prvd.lifecycle<<(Mechanic, any)>>("onStart", prvd.fireConcurrent),
			onActivate = prvd.lifecycle<<(Mechanic, any, {})>>("onActivate", prvd.fireConcurrent),
			onBindActivation = prvd.lifecycle<<(Mechanic, any)>>("bindActivation", prvd.fireConcurrent),
			getActivationInstance = prvd.lifecycle<<(Mechanic, any)>>("getActivationInstance", prvd.fireConcurrent),
		},
	}, Level)

	return Result.Ok(self)
end

function Level.getLifetime(self: Level)
	assert(self.started, "Level hasn't started yet")
	return os.clock() - self.startTimestamp
end

function Level.getMechanics<Self>(self: Level, implementation: Self): { Mechanic<Self> }
	return self.mechanicsByImplementations[implementation] or {}
end

function Level.registerImplementationLifecycles(self: Level, implementation: AnyImplementation)
	for _, lifecycle in self.implementationLifecycles do
		local method: (AnyImplementation, ...any) -> () = (implementation :: any)[lifecycle.method]
		if type(method) == "function" then
			lifecycle:register(function(...)
				return method(implementation, ...)
			end)
		end
	end
end

function Level.registerMechanicLifecycles(self: Level, mechanic: Mechanic)
	for _, lifecycle in self.mechanicLifecycles do
		local implementation = mechanic.implementation
		local method: (AnyImplementation, Mechanic, ...any) -> () = (implementation :: any)[lifecycle.method]
		if type(method) == "function" then
			lifecycle:register(function(...)
				return method(implementation, mechanic, ...)
			end)
		end
	end
end

-- TODO: reimplement onActivate alongside bindActivation and getActivationInstance
function Level.startMechanic(self: Level, mechanic: Mechanic)
	self:registerMechanicLifecycles(mechanic)
	self.mechanicLifecycles.onStart:fire(self)
end

function Level.start(self: Level)
	local self = self
	assert(not self.started, `Level {self.name} has already started`)
	self.started = true
	self.startedTimestamp = os.clock()

	self.life:add(self.instance)
	self.life:destroyOn(self.instance)

	self.implementationLifecycles.onInit:fire(self)

	self.life:addMany(
		RunService.PreSimulation:Connect(function(dt)
			self.implementationLifecycles.onPreSimulation:fire(dt, self)
		end),
		RunService.PostSimulation:Connect(function(dt)
			self.implementationLifecycles.onPreSimulation:fire(dt, self)
		end),
		RunService.PreRender:Connect(function(dt)
			self.implementationLifecycles.onPreSimulation:fire(dt, self)
		end),
		RunService.PreAnimation:Connect(function(dt)
			self.implementationLifecycles.onPreSimulation:fire(dt, self)
		end)
	)

	table.insert(Level.activeLevels, self)
	self.life:add(function()
		tables.findAndRemove(Level.activeLevels, self)
	end)
end

function Level.__tostring(self: Level)
	return `Level({self.name})`
end

return table.freeze(Level)
