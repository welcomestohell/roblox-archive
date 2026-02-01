local HttpService = game:GetService("HttpService")

local Life = require("./Life")
local Mechanic = require("./Mechanic")
local MechanicTypes = require("./MechanicTypes")
local Promise = require("@pkgs/Promise")
local gt = require("@pkgs/gt")

local Level = {} :: MechanicTypes.LevelMetatable
Level.__index = Level

Level.baseScripts = {}
Level.baseMechanicImplementations = {}

function Level.new(life: Life.Life, name: string, instance: MechanicTypes.LevelInstance): MechanicTypes.Level
	return setmetatable({
		life = life,
		name = name,
		instance = instance,
		scripts = table.clone(Level.baseScripts),
		mechanicImplementations = table.clone(Level.baseMechanicImplementations),
		mechanics = {},
		mechanicsByImplementations = {},
		inheritedLevels = {},
	}, Level)
end

function Level.inherit(
	parent: MechanicTypes.Level,
	name: string,
	instance: MechanicTypes.LevelInstance
): MechanicTypes.Level
	local inherited: MechanicTypes.Level = setmetatable({
		life = parent.life:inner(),
		name = name,
		instance = instance,
		scripts = table.clone(parent.baseScripts),
		mechanicImplementations = table.clone(parent.baseMechanicImplementations),
		mechanics = {},
		mechanicsByImplementations = {},
		inheritedLevels = {},
	}, Level)

	table.insert(parent.inheritedLevels, inherited)

	inherited.life:add(function()
		table.remove(parent.inheritedLevels, table.find(parent.inheritedLevels, inherited))
	end)

	return inherited
end

function Level.collectScripts(
	parent: Instance,
	scripts: { [ModuleScript]: any },
	mechanicImplementations: { [string]: any }
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
			mechanicImplementations[required.instanceTag] = required
		end
	end
end

function Level.loadMechanicsFromInstance(self: MechanicTypes.Level, instance: Instance)
	for _, tag: string in instance:GetTags() do
		local implementation = self.mechanicImplementations[tag]
		if not implementation then
			continue
		end

		if implementation.parentCheck then
			local parentCheck = gt.typecast(implementation.parentCheck)
			local isValid, reason = parentCheck:matches(instance.Parent)
			if not isValid then
				warn("Failed to validate Mechanic parent", reason:formatErr())
				continue
			end
		end

		local mechanicLife = self.life:inner()
		mechanicLife:add(instance)

		local mechanic: MechanicTypes.MechanicSelf<any> = {
			id = HttpService:GenerateGUID(false),
			implementation = implementation,
			instance = instance,
			parent = instance.Parent,
			life = mechanicLife,
			level = self,
		}

		setmetatable(mechanic, implementation)
		table.insert(self.mechanics :: any, mechanic)
		self.mechanicsByImplementations[implementation] = self.mechanicsByImplementations[implementation] or {}
		table.insert(self.mechanicsByImplementations[implementation] :: any, mechanic)
	end
end

function Level.start(self: MechanicTypes.Level)
	self.life:add(self.instance)
	self.life:tie(self.instance.Destroying)

	local levelScripts = self.instance:FindFirstChild("Scripts")
	if levelScripts then
		Level.collectScripts(levelScripts, self.scripts, self.mechanicImplementations)
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
		if mechanic.onStart then
			self.life:add(task.spawn(mechanic.onStart :: any, mechanic))
		end
	end
end

return table.freeze(Level)
