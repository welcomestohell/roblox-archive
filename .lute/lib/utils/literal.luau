local function literal<T>(x: T | ""): T
	return x
end

return literal
