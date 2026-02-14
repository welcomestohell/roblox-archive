local WEAK_METATABLES = {
	k = table.freeze { __mode = "k" },
	v = table.freeze { __mode = "v" },
	kv = table.freeze { __mode = "kv" },
}

local function keys<K>(target: { [K]: any }): { K }
	local result = {}
	for key in target do
		table.insert(result, key)
	end
	return result
end

local function values<V>(target: { [any]: V }): { V }
	local result = {}
	for _, value in target do
		table.insert(result, value)
	end
	return result
end

local function weak(mode: keyof<typeof(WEAK_METATABLES)>): { [any]: any }
	return setmetatable({}, WEAK_METATABLES[mode])
end

local function deepCopy<T>(target: T & {})
	local clone = table.clone(target)
	for key, value in clone :: { [any]: any } do
		if type(value) == "table" then
			clone[key] = deepCopy(value)
		end
	end
	return clone
end

local function findAndRemove<T>(haystack: { T }, needle: T)
	local index = table.find(haystack, needle)
	if index then
		table.remove(haystack, index)
	end
end

return table.freeze {
	keys = keys,
	values = values,
	weak = weak,
	deepCopy = deepCopy,
	findAndRemove = findAndRemove,

	create = table.create :: ((count: number) -> { any }) & (<V>(count: number, value: V) -> { V }),
}
