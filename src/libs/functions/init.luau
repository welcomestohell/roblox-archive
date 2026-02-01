export type Identity<T...> = (T...) -> T...

local function identity(...: any): ...any
	return ...
end

local function literal<T>(x: T | ""): T
	return x
end

-- selene: allow(unused_variable)
local function noop(...: any) end

return table.freeze {
	identity = identity,
	literal = literal,
	noop = noop,
}
