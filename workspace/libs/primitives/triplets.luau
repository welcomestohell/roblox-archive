-- Tung Tung Tung Sahur library
-- AKA Triple T

const arrays = require "@libs/primitives/arrays"
const tables = require "@libs/primitives/tables"

export type Triplet<T1, T2, T3> = { [T1]: { [T2]: T3 } }

const triplets = {}

function triplets.get<T1, T2, T3>(input: Triplet<T1, T2, T3>, t1: T1, mt: keyof<typeof(tables.WEAK_METATABLES)>?): { [T2]: T3 }
	local result = input[t1]
	if result then return result end
	result = if mt then tables.createWeakened(mt) else {}
	input[t1] = result
	return result
end

-- Map-like primitives

function triplets.mapSet<T1, T2, T3>(input: Triplet<T1, T2, T3>, t1: T1, t2: T2, t3: T3)
	triplets.get(input, t1)[t2] = t3
end

function triplets.mapRemove<T1, T2, T3>(input: Triplet<T1, T2, T3>, t1: T1, t2: T2)
	triplets.get(input, t1)[t2] = nil
end

-- Array-like primitives

function triplets.arrayPush<T1, T3>(input: Triplet<T1, number, T3>, t1: T1, t3: T3)
	table.insert(triplets.get(input, t1), t3)
end

function triplets.arrayPop<T1, T3>(input: Triplet<T1, number, T3>, t1: T1): T3?
	return table.remove(triplets.get(input, t1))
end

function triplets.arrayFindAndRemove<T1, T3>(input: Triplet<T1, number, T3>, t1: T1, t3: T3)
	arrays.findAndRemove(triplets.get(input, t1), t3)
end

-- Set-like primitives

function triplets.setAdd<T1, T2>(input: Triplet<T1, T2, true>, t1: T1, t2: T2)
	triplets.get(input, t1)[t2] = true
end

function triplets.setRemove<T1, T2>(input: Triplet<T1, T2, true>, t1: T1, t2: T2)
	triplets.get(input, t1)[t2] = nil
end

return table.freeze(triplets)
