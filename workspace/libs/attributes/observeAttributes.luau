local arrays = require "@libs/primitives/arrays"
local tables = require "@libs/primitives/tables"
local threadpool = require "@libs/threadpool"

local CONNECTIONS = tables.createWeakened<<Instance, RBXScriptConnection>> "k"
local LISTENERS = tables.createWeakened<<Instance, { (attribute: string) -> () }>> "k"

local function cleanupObserver(instance: Instance)
	if LISTENERS[instance] then
		table.clear(LISTENERS[instance])
		LISTENERS[instance] = nil
	end

	if CONNECTIONS[instance] then
		CONNECTIONS[instance]:Disconnect()
		CONNECTIONS[instance] = nil
	end
end

-- Investigate: Dedicated AttributeObserver class that would handle change/fetch
local function observeAttributes(instance: Instance, listener: (attribute: string) -> ())
	if not LISTENERS[instance] then
		LISTENERS[instance] = {}
		CONNECTIONS[instance] = instance.AttributeChanged:Connect(function(attribute)
			threadpool.spawnCallbacks(LISTENERS[instance], attribute)
		end)

		instance.Destroying:Once(function()
			cleanupObserver(instance)
		end)
	end

	table.insert(LISTENERS[instance], listener)

	return function()
		if LISTENERS[instance] then
			arrays.findAndRemove(LISTENERS[instance], listener)
			if next(LISTENERS[instance]) == nil then cleanupObserver(instance) end
		end
	end
end

return observeAttributes
