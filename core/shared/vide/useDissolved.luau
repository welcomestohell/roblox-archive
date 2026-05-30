local Vide = require("@roblox_packages/Vide")

--[=[
    Dissolves a source into a constant value if it has no `read` dependencies.
]=]
local function useDissolved<T>(source: (read: <T>(value: Vide.As<T>) -> T) -> T): Vide.As<T>
	local isDependencyRead = false

	local function mockRead(value: unknown)
		if typeof(value) == "function" then
			isDependencyRead = true
			error("used dependency")
		end
		return value
	end

	local initialSuccess, dissolvedOrError = pcall(source, mockRead :: never)

	return if initialSuccess
		then dissolvedOrError
		elseif isDependencyRead then function()
			return source(Vide.read :: never)
		end
		else error(`Dissolving source threw an error: {dissolvedOrError}`)
end

return useDissolved
