-- LUAU: this file seemingly lost all typechecking??

local RunService = game:GetService "RunService"

local Life = require "@libs/memory/Life"
local Mechanic = require "@libs/core/Mechanic"
local Promise = require "@roblox_packages/Promise"
local Result = require "@libs/Result"
local ScriptCollector = require "@libs/core/ScriptCollector"
local activation = require "@libs/activation"
local gt = require "@libs/gt"
local marrays = require "@libs/collections/marrays"
local mechanize = require "@libs/core/mechanize"
local mmaps = require "@libs/collections/mmaps"
local prvd = require "@prvdmwrong/prvdmwrong"
local tables = require "@libs/collections/tables"
local threadpool = require "@libs/threadpool"

type AnyImplementation = Mechanic.AnyMechanicImplementation
type MechanicImplementation = Mechanic.MechanicImplementation
type Mechanic<Implementation = any, Mixin = {}> = Mechanic.Mechanic<Implementation, Mixin>

const MECHANIC_TAG_PATTERN = "Mechanic:%s?([%w_%-]+)"

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

	instanceByGroups: { [string]: { Instance } },

	mechanics: { Mechanic<any> },
	mechanicsByImplementations: { [AnyImplementation]: { Mechanic } },
	mechanicsByInstance: { [Instance]: { Mechanic } },

	implementationLifecycleListeners: { [prvd.Lifecycle]: { [AnyImplementation]: (...unknown) -> () } },
	implementationLifecycles: { [string]: prvd.Lifecycle },
	mechanicLifecycleListeners: { [prvd.Lifecycle]: { [Mechanic]: (...unknown) -> () } },
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

		instanceByGroups = {},

		mechanics = {},
		mechanicsByImplementations = {},
		mechanicsByInstance = tables.weak "k",

		-- HEAR ME OUT

		implementationLifecycleListeners = {},
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

			onPreRender = prvd.lifecycle<<(number, Level)>>("onPreRender", prvd.fireConcurrent),
			onPreAnimation = prvd.lifecycle<<(number, Level)>>("onPreAnimation", prvd.fireConcurrent),
			onPreSimulation = prvd.lifecycle<<(number, Level)>>("onPreSimulation", prvd.fireConcurrent),
			onPostSimulation = prvd.lifecycle<<(number, Level)>>("onPostSimulation", prvd.fireConcurrent),
		},

		mechanicLifecycleListeners = {},
		mechanicLifecycles = {
			onStart = prvd.lifecycle<<(Mechanic, Level)>>("onStart", prvd.fireConcurrent),
			onActivate = prvd.lifecycle<<(Mechanic, Level, {})>>("onActivate", prvd.fireConcurrent),
			bindActivation = prvd.lifecycle<<(Mechanic, Level)>>("bindActivation", prvd.fireConcurrent),
			getActivationInstance = prvd.lifecycle<<(Mechanic, Level)>>("getActivationInstance", prvd.fireConcurrent),
		},
	}, Level)

	self.life:add(function()
		for _, implementations in self.implementationLifecycleListeners do
			table.clear(implementations)
		end

		for _, mechanics in self.mechanicLifecycleListeners do
			table.clear(mechanics)
		end

		table.clear(self.implementationLifecycles)
		table.clear(self.implementationLifecycleListeners)
		table.clear(self.implementationLifecycles)
		table.clear(self.mechanicLifecycleListeners)
	end)

	return Result.Ok(self)
end

function Level.getLifetime(self: Level)
	assert(self.started, "Level hasn't started yet")
	return os.clock() - self.startedTimestamp
end

function Level.getMechanics<Self>(self: Level, implementation: Self): { Mechanic<Self> }
	return self.mechanicsByImplementations[implementation] :: any or {}
end

function Level.getGroupedInstances<Args...>(self: Level, group: string): { Instance }
	return marrays.get(self.instanceByGroups, group)
end

function Level.getListenerForMechanic<Args...>(
	self: Level,
	lifecycle: prvd.Lifecycle<Args...>,
	mechanic: Mechanic
): ((Args...) -> ())?
	return mmaps.get(self.mechanicLifecycleListeners, lifecycle)[mechanic]
end

function Level.getListenerForImplementation<Args...>(
	self: Level,
	lifecycle: prvd.Lifecycle<Args...>,
	implementation: AnyImplementation
): ((Args...) -> ())?
	return mmaps.get(self.implementationLifecycleListeners, lifecycle)[implementation]
end

function Level.registerLifecyclesForImplementation(self: Level, implementation: AnyImplementation)
	for _, lifecycle in self.implementationLifecycles do
		local method: (AnyImplementation, ...any) -> () = (implementation :: any)[lifecycle.method]
		if type(method) == "function" then
			local function listener(...)
				return method(implementation, ...)
			end
			mmaps.set(self.implementationLifecycleListeners, lifecycle, implementation, listener)
			lifecycle:register(listener)
		end
	end
end

function Level.registerLifecyclesForMechanic(self: Level, mechanic: Mechanic)
	for _, lifecycle in self.mechanicLifecycles do
		local implementation = mechanic.implementation
		local method: (AnyImplementation, Mechanic, ...any) -> () = (implementation :: any)[lifecycle.method]
		if type(method) == "function" then
			local function listener(...)
				return method(implementation, mechanic, ...)
			end
			mmaps.set(self.mechanicLifecycleListeners, lifecycle, mechanic, listener)
			lifecycle:register(listener)
		end
	end
end

function Level.bindActivation(self: Level, mechanic: Mechanic)
	local bindActivation = self:getListenerForMechanic<<(Level)>>(self.mechanicLifecycles.bindActivation, mechanic)
	if bindActivation then
		bindActivation(self)
		return
	end

	-- stylua: ignore
	local onActivate = self:getListenerForMechanic<<(Level, activation.ActivationEvent)>>(self.mechanicLifecycles.onActivate, mechanic)
	if not onActivate then
		return
	end

	-- stylua: ignore
	local getActivationInstance = self:getListenerForMechanic<<(Level)>>(self.mechanicLifecycles.getActivationInstance, mechanic)
	local instance = getActivationInstance and getActivationInstance(self) or mechanic.instance

	local implementation: any = mechanic.implementation
	local activationAttributes = implementation.Activation :: activation.ActivationAttributes
	if not activationAttributes then
		Mechanic.attributeSection(implementation, "Activation")
		activationAttributes = activation.useAttributes(implementation)
		implementation.Activation = activationAttributes
	end

	activation.bindActivation {
		attributes = activationAttributes,
		activationLife = mechanic.life,
		instanceLife = mechanic.life,
		instance = instance,
		instanceConfiguration = mechanic.instanceConfiguration,
		onActivate = function(context: activation.ActivationContext, event: activation.ActivationEvent)
			onActivate(self, event)
		end,
	}
end

function Level.loadInstance(self: Level, instance: Instance): { Mechanic }
	local mechanics = {}
	for _, tag in instance:GetTags() do
		local mechanicName = string.match(tag, "Mechanic:%s?([%w_%-]+)")
		if mechanicName then
			local implementation = Mechanic.downcast(self.scripts.mechanicImplementationByName[mechanicName])
			if not implementation then
				continue
			end

			local mechanizeResult = mechanize(implementation, self.life, instance)
			if mechanizeResult:isErr() then
				continue
			end

			local mechanic: Mechanic = mechanizeResult:unwrap() :: any
			table.insert(self.mechanics, mechanic)
			table.insert(mechanics, mechanic)
			marrays.push(self.mechanicsByImplementations, implementation, mechanic)
			marrays.push(self.mechanicsByInstance, instance, mechanic)
			self:registerLifecyclesForMechanic(mechanic)
		end

		local groupName = string.match(tag, "Group:%s?([%w_%-]+)")
		if groupName then
			marrays.push(self.instanceByGroups, groupName, instance)
			self.life:add(instance.Destroying:Once(function()
				marrays.remove(self.instanceByGroups, groupName, instance)
			end))
		end
	end
	return mechanics
end

function Level.start(self: Level)
	local self = self
	assert(not self.started, `Level {self.name} has already started`)
	self.started = true
	self.startedTimestamp = os.clock()

	self.life:add(self.instance)
	self.life:destroyOn(self.instance.Destroying)

	local instancePromises: { Promise.Promise } = {}
	for index, instance in self.instance.Mechanics:GetDescendants() do
		instancePromises[index] = Promise.try(Level.loadInstance, self, instance) :: Promise.Promise
	end
	Promise.all(instancePromises):await()

	for _, implementation in self.scripts.mechanicImplementations do
		self:registerLifecyclesForImplementation(implementation)
	end

	self.implementationLifecycles.onInit:fire(self)

	for _, mechanic in self.mechanics do
		self.life:add(threadpool.spawn(Level.bindActivation, self, mechanic))
	end

	self.mechanicLifecycles.onStart:fire(self)

	self.life:addMany(
		RunService.PreSimulation:Connect(function(dt)
			self.implementationLifecycles.onPreSimulation:fire(dt, self)
		end),
		RunService.PostSimulation:Connect(function(dt)
			self.implementationLifecycles.onPostSimulation:fire(dt, self)
		end),
		RunService.PreRender:Connect(function(dt)
			self.implementationLifecycles.onPreRender:fire(dt, self)
		end),
		RunService.PreAnimation:Connect(function(dt)
			self.implementationLifecycles.onPreAnimation:fire(dt, self)
		end),
		self.instance.DescendantAdded:Connect(function(instance)
			for _, mechanic in self:loadInstance(instance) do
				self.life:add(threadpool.spawn(Level.bindActivation, self, mechanic))
				local onStart = self:getListenerForMechanic<<Level>>(self.mechanicLifecycles.onStart, mechanic)
				if onStart then
					threadpool.spawn(onStart, self)
				end
			end
		end)
	)

	table.insert(Level.activeLevels, self)
	self.life:add(function()
		tables.findAndRemove(Level.activeLevels, self)
	end)
end

-- function Level.__tostring(self: Level)
-- 	return `Level({self.name})`
-- end

return table.freeze(Level)
