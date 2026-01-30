local HttpService = game:GetService "HttpService"

local Life = require "../memory/Life"
local Mechanic = require "./Mechanic"
local Promise = require "@pkgs/Promise"
local gt = require "@pkgs/gt"
local types = require "../types"

local Level = {} :: types.LevelMetatable
Level.__index = Level

Level.baseScripts = {}
Level.baseMechanicImplementations = {}

function Level.collectScripts(
	parent: Instance,
	scripts: { [ModuleScript]: any },
	mechanicImplementations: { [string]: any }
)
	for _, instance in parent:GetDescendants() do
		if not instance:IsA "ModuleScript" then
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
			mechanicImplementations[required.instanceTag] = required
		end
	end
end

function Level.new(life: Life.Life, name: string, instance: types.LevelInstance): types.Level
	return setmetatable({
		life = life,
		name = name,
		instance = instance,
		scripts = table.clone(Level.baseScripts),
		mechanics = {},
		mechanicImplementations = table.clone(Level.baseMechanicImplementations),
	}, Level)
end

function Level.loadMechanicsFromInstance(self: types.Level, instance: Instance)
	for _, tag: string in instance:GetTags() do
		local implementation = self.mechanicImplementations[tag]
		if not implementation then
			continue
		end

		if implementation.instanceType then
			local checkInstance = gt.typecast(implementation.instanceType)
			local isValid, reason = checkInstance:matches(instance)
			if not isValid then
				warn(reason:formatErr())
				continue
			end
		end

		local mechanicLife = self.life:inner()
		mechanicLife:add(instance)

		local mechanic: types.MechanicSelf<any> = {
			id = HttpService:GenerateGUID(),
			instance = instance,
			life = mechanicLife,
		}

		setmetatable(mechanic, implementation)
		table.insert(self.mechanics, mechanic)
	end
end

function Level.bootstrap(self: types.Level)
	self.life:add(self.instance)
	self.life:tie(self.instance.Destroying)

	local levelScripts = self.instance:FindFirstChild "Scripts"
	if levelScripts then
		Level.collectScripts(levelScripts, self.scripts, self.mechanicImplementations)
	end

	for _, instance in self.instance:WaitForChild("Mechanics"):GetDescendants() do
		self:loadMechanicsFromInstance(instance)
	end

	local initThreads: { Promise.Promise } = {}
	for _, implementation in self.mechanicImplementations do
		if implementation.onInit then
			table.insert(initThreads, Promise.try(implementation.onInit, implementation :: any) :: Promise.Promise)
		end
	end

	Promise.all(initThreads)
		:catch(function(e)
			warn("Mechanic failed to initialize:", e)
		end)
		:await()

	for _, mechanic in self.mechanics do
		print(mechanic)
		if mechanic.onStart then
			self.life:add(task.spawn(mechanic.onStart :: any, mechanic))
		end
	end
end

table.freeze(Level)
return Level
