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

return table.freeze {
	create = table.create :: ((count: number) -> { any }) & (<V>(count: number, value: V) -> { V }),

	keys = keys,

	weak = weak,
	deepCopy = deepCopy,
}
