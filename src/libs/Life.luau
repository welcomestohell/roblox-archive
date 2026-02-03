local destroy = require("./destroy")

local Life = {}
Life.__index = Life
Life.type = "Life"

export type Life = setmetatable<{ read destroyables: { destroy.Destroyable } }, typeof(Life)>

function Life.new(): Life
	return table.freeze(setmetatable({ destroyables = {} }, Life))
end

function Life.isLife(x: any)
	return typeof(x) == "table" and getmetatable(x) == Life
end

function Life.add<T>(self: Life, bound: T): T
	table.insert(self.destroyables, bound)
	return bound
end

function Life.spawn(self: Life, bound: thread): thread
	table.insert(self.destroyables, task.spawn(bound))
	return bound
end

function Life.addMany<T...>(self: Life, ...: T...)
	for index = 1, select("#", ...) do
		table.insert(self.destroyables, select(index, ...) :: destroy.Destroyable)
	end
	return ...
end

function Life.remove<T>(self: Life, bound: T): T
	table.remove(self.destroyables, table.find(self.destroyables, bound))
	return bound
end

function Life.removeMany<T...>(self: Life, ...: T...): T...
	for index = 1, select("#", ...) do
		table.remove(self.destroyables, table.find(self.destroyables, select(index, ...) :: destroy.Destroyable))
	end
	return ...
end

function Life.removeAll(self: Life)
	table.clear(self.destroyables)
end

function Life.tie(self: Life, signal: RBXScriptSignal): RBXScriptConnection
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
	return #self.destroyables == 0
end

-- TODO: implement life pooling so this method isnt useless
-- TODO: poison class
function Life.destroy(self: Life)
	for index = #self.destroyables, 1, -1 do
		destroy(self.destroyables[index])
	end
	table.clear(self.destroyables)
	-- setmetatable(self :: any, {})
end

function Life.__tostring(_: Life)
	return "Life"
end

function Life.__len(self: Life)
	return #self.destroyables
end

return table.freeze(Life)
