const typeforge = require "@libs/vendor/typeforge"
export type Map<K = unknown, V = unknown> = { [K]: V }
export type Array<T = unknown> = { T }
export type Set<T = unknown> = { [T]: true }

const tables = {}

const function passthrough(value)
	return value
end

--[=[
	Returns if the `predicate` returns `true` for all values in a table.
	If no `predicate` is provided, defaults to checking Luau truthiness.

	@example Checking Luau truthiness
	```luau
	tables.all { nil, false } --> false
	tables.all { true, 0, "0" } --> true
	```

	@example Checking if all words start with "fire"
	```luau
	const function isFire(value: string)
		return strings.startsWith(value, "fire")
	end

	tables.all({ "naps", "fire", "towers" }, isFire) --> false
	tables.all({ "fire", "fireworks", "fireshock" }, isFire) --> true
	```

	@param input -- Table to iterate
	@param predicate -- Predicate to check entries, defaults to Luau truthiness
]=]
function tables.all<K, V>(input: { [K]: V }, predicate: (K, V) -> boolean?): boolean
	predicate = predicate or passthrough
	for key, value in input do
		if not predicate(value, key) then return false end
	end
	return true
end

function tables.count(input: { [unknown]: unknown }): number
	local count = 0
	for _ in input do
		count += 1
	end
	return count
end

function tables.countPredicate<K, V>(input: { [K]: V }, predicate: (V, K) -> boolean?): number
	predicate = predicate or passthrough
	local count = 0
	for key, value in input do
		if predicate(value, key) then
			count += 1
		end
	end
	return count
end

function tables.deepCloned<T>(input: T & {}): typeforge.DeepReadWrite<T>
	local clone = table.clone(input)
	for key, value in clone :: { [any]: any } do
		if type(value) == "table" then clone[key] = tables.deepCloned(value :: {}) end
	end
	return clone
end

function tables.deepFreeze<T>(input: T & {}): typeforge.DeepReadOnly<T>
	if not table.isfrozen(input) then table.freeze(input) end
	for key, value in input :: { [any]: any } do
		if type(value) == "table" then tables.deepFreeze(value :: {}) end
	end
	return input
end

function tables.deepEqual(left: unknown, right: unknown): boolean
	if left == right then return true end
	if type(left) ~= "table" or type(right) ~= "table" then return false end

	for key, valueLeft in left do
		const valueRight = (right :: Map)[key]
		if
			(type(valueLeft) == "table" and type(valueRight) == "table" and not tables.deepEqual(valueLeft, valueRight))
			or valueLeft ~= valueRight
		then
			return false
		end
	end

	for key, valueRight in right do
		const valueLeft = (left :: Map)[key]
		if
			(type(valueLeft) == "table" and type(valueRight) == "table" and not tables.deepEqual(valueLeft, valueRight))
			or valueLeft ~= valueLeft
		then
			return false
		end
	end

	return true
end

function tables.isEmpty(input: { [unknown]: unknown }): boolean
	for _ in input do
		return false
	end
	return true
end

function tables.filtered<K, V>(input: { [K]: V }, predicate: (K, V) -> boolean): { [K]: V }
	const result = {}
	for key, value in input do
		if predicate(key, value) then result[key] = value end
	end
	return result
end

function tables.keysOf<K>(input: { [K]: unknown }): { K }
	const result = {}
	for key in input do
		table.insert(result, key)
	end
	return result
end

function tables.keysMapped<KI, KO, V>(input: { [KI]: V }, transform: (KI) -> KO): { [KO]: V }
	const result = {}
	for key, value in input do
		result[transform(key)] = value
	end
	return result
end

function tables.pairsMapped<KI, VI, KO, VO>(input: { [KI]: VO }, transform: (KI, VI) -> (KO, VO)): { [KO]: VO }
	const result = {}
	for keyIn, valueIn in input do
		const keyOut, valueOut = transform(keyIn, valueIn)
		result[keyOut] = valueOut
	end
	return result
end

function tables.shallowEqual(left: unknown, right: unknown): boolean
	if left == right then return true end
	if type(left) ~= "table" or type(right) ~= "table" then return false end

	for key, value in left do
		if (right :: Map)[key] ~= value then return false end
	end

	for key, value in right do
		if (left :: Map)[key] ~= value then return false end
	end

	return true
end

function tables.some<K, V>(input: { [K]: V }, predicate: (V, K) -> boolean?): boolean
	predicate = predicate or passthrough
	for key, value in input do
		if predicate(value, key) then return true end
	end
	return false
end

function tables.valuesOf<V>(input: { [unknown]: V }): { V }
	const result = {}
	for _, value in input do
		table.insert(result, value)
	end
	return result
end

return table.freeze(tables)
