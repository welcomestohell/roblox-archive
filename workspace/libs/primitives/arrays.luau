local functions = require "@libs/primitives/functions"

local arrays = {}

function arrays.all<V>(input: { V }, predicate: ((V, number) -> boolean)?): boolean
	predicate = predicate or functions.passthrough
	for index = 1, #input do
		if not predicate(input[index], index) then return false end
	end
	return true
end

function arrays.concatenated<V>(...: { V }?)
	local concatenated = {}
	for index = 1, select("#", ...) do
		local value = select(index, concatenated)
		if value then table.move(value, 1, #value, #concatenated + 1, concatenated) end
	end
	return concatenated
end

function arrays.differenced<T>(left: { T }, right: { T }): ({ T }, { T }, { T })
	local onlyInLeft, onlyInRight, both = {}, {}, {}

	local mappedLeft: { number } = {}
	for _, itemLeft in left do
		mappedLeft[itemLeft] = (mappedLeft[itemLeft] or 0) + 1
	end

	for _, itemRight in right do
		local count = mappedLeft[itemRight]
		if count == nil or count == 0 then
			table.insert(onlyInRight, itemRight)
		else
			mappedLeft[itemRight] -= 1
			table.insert(both, itemRight)
		end
	end

	for itemLeft, countLeft in mappedLeft do
		for _ = 1, countLeft do
			table.insert(onlyInLeft, itemLeft)
		end
	end

	return onlyInLeft, onlyInRight, both
end

function arrays.filtered<V>(input: { V }, predicate: (V, number) -> boolean): { V }
	local result = {}
	for index = 1, #input do
		local value = input[index]
		if predicate(value, index) then table.insert(result, value) end
	end
	return result
end

function arrays.filterMapped<VI, VO>(input: { VI }, transform: (VI, number) -> VO?): { VO }
	local result = {}
	for index = 1, #input do
		local transformed = transform(input[index], index)
		if transformed ~= nil then table.insert(result, transformed) end
	end
	return result
end

function arrays.filteredThenMapped<VI, VO>(
	input: { VI },
	predicate: ((VI, number) -> boolean)?,
	transform: (VI, number) -> VO
): { VO }
	predicate = predicate or functions.passthrough
	local result = {}
	for index = 1, #input do
		local value = input[index]
		if predicate(value, index) then table.insert(result, transform(value, index)) end
	end
	return result
end

function arrays.findAndRemove<T>(input: { T }, target: T)
	local index = table.find(input, target)
	if index then table.remove(input, index) end
end

function arrays.first<V>(input: { V }, predicate: ((V, number) -> boolean)?): V?
	predicate = predicate or functions.passthrough
	for index = 1, #input do
		local value = input[index]
		if predicate(value, index) then return value end
	end
	return nil
end

function arrays.flattened<T>(input: { { T } }): { T }
	local result: { T } = {}
	for index = 1, #input do
		local array = input[index]
		table.move(array, 1, #array, #result + 1, result)
	end
	return result
end

function arrays.frequenced<V>(input: { V }): { [V]: number }
	local result = {}
	for index = 1, #input do
		local value = input[index]
		result[value] = result[value] or 0
		result[value] += 1
	end
	return result
end

function arrays.last<V>(input: { V }, predicate: ((V, number) -> boolean)?): V?
	predicate = predicate or functions.passthrough
	for index = #input, 1, -1 do
		local value = input[index]
		if predicate(value, index) then return value end
	end
	return nil
end

function arrays.mapped<VI, VO>(input: { VI }, transform: (VI) -> VO): { VO }
	local result = table.create<<VO>>(#input)
	for index = 1, #input do
		result[index] = transform(input[index])
	end
	return result
end

function arrays.reduce<T, U>(
	array: { T },
	reducer: (accumulator: U, value: T, index: number, array: { T }) -> U,
	initReduction: U?
): U
	local result = initReduction
	local start = 1

	if result == nil then
		result = array[1]
		start = 2
	end

	for index = start, #array do
		result = reducer(result, array[index], index, array)
	end

	return result
end

function arrays.reduceRight<T, U>(
	array: { T },
	reducer: (accumulator: U, value: T, index: number, array: { T }) -> U,
	initReduction: U?
): U
	local result = initReduction
	local start = #array

	if result == nil then
		result = array[start]
		start -= 1
	end

	for index = start, 1, -1 do
		result = reducer(result, array[index], index, array)
	end

	return result
end

function arrays.reversed<T>(input: { T }): { T }
	local result: { T } = table.create<<T>>(#input)
	local len = #input
	for index = #input, 1, -1 do
		result[len - index + 1] = input[index]
	end
	return result
end

function arrays.some<V>(input: { V }, predicate: ((V, number) -> boolean)?): boolean
	predicate = predicate or functions.passthrough
	for index, value in input do
		if predicate(value, index) then return true end
	end
	return false
end

return table.freeze(arrays)
