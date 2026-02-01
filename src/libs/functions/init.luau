local gt = require("@libs/gt")

export type Identity<T...> = (T...) -> T...

local function identity(...: any): ...any
	return ...
end

local function literal<T>(x: T | ""): T
	return x
end

-- selene: allow(unused_variable)
local function noop(...: any) end

local function never(x: never): never
	error(`Expected to be unreachable, but got {x}`)
end

return table.freeze {
	identity = identity,
	literal = literal,
	noop = noop,
	never = never,
}
