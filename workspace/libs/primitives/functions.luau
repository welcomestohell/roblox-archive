export type Identity<T...> = (T...) -> T...

const functions = {}

function functions.identity<T...>(...: T...): T...
	return ...
end

function functions.isCallable<T>(value: T): boolean
	return type(value) == "function"
		or type(value) == "table" and getmetatable(value) and getmetatable(value :: any).__call ~= nil
end

function functions.literal<T>(x: T | ""): T
	return x
end

-- selene: allow(unused_variable)
function functions.noop(...: any) end

function functions.never(x: never): never
	error(`Expected to be unreachable, but got {x}`)
end

function functions.passthrough(x)
	return x
end

return table.freeze(functions)
