const useDissolved = require "@core/shared/fluid/useDissolved"
const tables = require "@libs/collections/tables"
const Fluid = require "@roblox_packages/Fluid"

local function forValues<VI, VO>(values: Fluid.UsedAs<{ VI }>, map: (VI) -> VO): Fluid.UsedAs<{ VO }>
	return useDissolved(function(read: useDissolved.Read)
		local values = read(values) :: { VI }
		local result = tables.create(#values)
		for index, value in values do
			result[index] = map(value)
		end
		return result
	end)
end

return forValues
