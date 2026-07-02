const RunService = game:GetService "RunService"

const Level = require "@libs/core/Level"
const arrays = require "@libs/primitives/arrays"
const threadpool = require "@libs/threadpool"
const Promise = require "@pkgs/Promise"

const function startLevel(self: Level.Level)
	local self = self
	assert(not self.started, `Level {self.name} has already started`)
	self.started = true
	self.startedTimestamp = os.clock()

	local instancePromises, loadPromises = self:loadDescendantInstancesAsync(self.instance.Mechanics)
	Promise.all(instancePromises):await()
	Promise.all(loadPromises):await()

	for _, implementation in self.scripts.mechanicImplementations do
		self:registerLifecyclesForImplementation(implementation)
	end

	self.implementationLifecycles.onInit:fire(self)

	self.life:add(self.instance)
	self.life:destroyOn(self.instance.Destroying)

	-- const toggled = {}
	-- for group, instances in self.instanceByGroups do
	-- 	for _, instance in instances do
	-- 		if not toggled[instance] then
	-- 			toggled[instance] = true
	-- 			toggle.toggleInstance(false, instance)
	-- 		end
	-- 	end
	-- end
	-- table.clear(toggled)

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
				local onStart = self:getListenerForMechanic(self.mechanicLifecycles.onStart, mechanic)
				if onStart then threadpool.spawn(onStart, self) end
			end
		end)
	)

	-- LUAU FIXME: this should typecheck fine?
	table.insert(Level.activeLevels :: { any }, self)
	self.life:add(function()
		arrays.findAndRemove<<Level>>(Level.activeLevels, self)
	end)
end

return startLevel
