local Fluid = require "@roblox_packages/Fluid"
local tables = require "@libs/collections/tables"
local useDissolved = require "@core/shared/fluid/useDissolved"

local function mapRange<T>(
	map: (index: number) -> T,
	startingIndex: Fluid.UsedAs<number>,
	endingIndex: Fluid.UsedAs<number>,
	step: Fluid.UsedAs<number>?
): Fluid.UsedAs<{ T }>
	return useDissolved(function()
		local startingIndex = Fluid.read(startingIndex)
		local endingIndex = Fluid.read(endingIndex)
		local step = Fluid.read(step or 1)

		local result = tables.create(endingIndex - startingIndex)
		for index = startingIndex, endingIndex, step do
			result[index] = map(index)
		end

		return result
	end)
end

return mapRange
