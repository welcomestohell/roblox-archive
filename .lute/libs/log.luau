local pp = require("@batteries/pp")
local richterm = require("@batteries/richterm")
local process = require("@std/process")

local function stringify(formatter: richterm.Formatter, ...: unknown)
	local len = select("#", ...)
	local prettified = table.create(len)
	for index = 1, len do
		local value = select(index, ...)
		prettified[index] = formatter(if type(value) == "string" then value else pp(value))
	end
	return table.concat(prettified, " ")
end

local function createLogger(formatter: richterm.Formatter)
	return function(...: unknown)
		print(stringify(formatter, ...))
	end
end

local function throw(...: unknown): never
	print(stringify(richterm.red, ...))
	return process.exit(1)
end

return table.freeze({
	verbose = createLogger(richterm.dim),
	info = createLogger(richterm.combine()),
	warn = createLogger(richterm.yellow),
	error = createLogger(richterm.red),
	throw = throw,
})
