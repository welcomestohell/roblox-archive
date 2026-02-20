local destroy = require("./destroy")
local tables = require("./tables")
local threadpool = require("@libs/threadpool")

local Life = {}
Life.__index = Life
Life.type = "Life"

export type Life = setmetatable<{ destroyed: boolean, destroyables: { destroy.Destroyable } }, typeof(Life)>

function Life.new(): Life
	return setmetatable({
		destroyed = false,
		destroyables = {} :: { destroy.Destroyable },
	}, Life)
end

function Life.isLife(x: any)
	return typeof(x) == "table" and getmetatable(x) == Life
end

function Life.isDestroyed(self: Life)
	return self.destroyed
end

function Life.isAlive(self: Life)
	return not self.destroyed
end

function Life.add<T>(self: Life, bound: T): T
	if self.destroyed then
		return bound
	end
	table.insert(self.destroyables, bound)
	return bound
end

function Life.spawn<T>(self: Life, bound: (...any) -> ...any): thread | (...any) -> ...any
	if self.destroyed then
		return bound
	end
	local thread = threadpool.spawn(bound)
	table.insert(self.destroyables, function()
		task.cancel(thread)
	end)
	return thread
end

function Life.addMany<T...>(self: Life, ...: T...)
	if self.destroyed then
		return ...
	end
	for index = 1, select("#", ...) do
		table.insert(self.destroyables, select(index, ...) :: destroy.Destroyable)
	end
	return ...
end

function Life.remove<T>(self: Life, bound: T): T
	if self.destroyed then
		return bound
	end
	tables.findAndRemove(self.destroyables, bound)
	return bound
end

function Life.removeMany<T...>(self: Life, ...: T...): T...
	if self.destroyed then
		return ...
	end
	for index = 1, select("#", ...) do
		tables.findAndRemove(self.destroyables, select(index, ...))
	end
	return ...
end

function Life.removeAll(self: Life)
	table.clear(self.destroyables)
end

function Life.delay(self: Life, fn: () -> (), time: number)
	if self.destroyed then
		return
	end
	local thread = task.delay(time, function()
		if self:isAlive() then
			fn()
		end
	end)
	self:add(function()
		task.cancel(thread)
	end)
end

function Life.connect(self: Life, signal: RBXScriptSignal, fn: (...any) -> ...any): RBXScriptConnection?
	if self.destroyed then
		return nil
	end
	return Life.add(self, signal:Connect(fn))
end

function Life.tie(self: Life, signal: RBXScriptSignal): RBXScriptConnection?
	if self.destroyed then
		return nil
	end
	return Life.add(
		self,
		signal:Connect(function()
			Life.destroy(self)
		end)
	)
end

function Life.inner(self: Life)
	local inner = Life.new()
	self:add(inner)
	inner:add(function()
		self:remove(inner)
	end)
	return inner
end

function Life.isEmpty(self: Life)
	if self.destroyed then
		return true
	end
	return #self.destroyables == 0
end

function Life.destroy(self: Life)
	if self.destroyed then
		return
	end

	self.destroyed = true

	for index = #self.destroyables, 1, -1 do
		destroy(self.destroyables[index])
	end

	table.clear(self.destroyables)
end

function Life.__tostring(_: Life)
	return "Life"
end

function Life.__len(self: Life)
	return #self.destroyables
end

return table.freeze(Life)
