local tables = require "@libs/primitives/tables"

local currentOrder = 0
local attributeToOrder = tables.createWeakened<<unknown, number>> "k"
local orderToAttribute = tables.createWeakened<<number, unknown>> "v"

const function nextOrder()
	currentOrder += 1
	return currentOrder
end

const function track<T>(attribute: T): T
	local order = nextOrder()
	attributeToOrder[attribute] = order
	orderToAttribute[order] = attribute
	return attribute
end

const function orderOf<T>(attribute: T)
	return attributeToOrder[attribute]
end

return table.freeze {
	attributeToOrder = attributeToOrder,
	orderToAttribute = orderToAttribute,

	currentOrder = function()
		return currentOrder
	end,

	nextOrder = nextOrder,
	track = track,
	orderOf = orderOf,
}
