local pp = require "@batteries/pp"
local richterm = require "@batteries/richterm"

local log = {}
log.level = 5

local function createLogger(minimumLevel: number, label: string, formatter: richterm.Formatter)
	local formattedLabel = richterm.dim(`[{label}] `)

	local function output(...: any)
		if log.level < minimumLevel then
			return
		end

		local len = select("#", ...)
		local segments = table.create(len) :: { string }
		for index = 1, len do
			local value = select(index, ...)
			segments[index] = if typeof(value) == "string" then value else richterm.bold(pp(value))
		end

		print(formatter(formattedLabel .. table.concat(segments, " ")))
	end

	return output
end

log.trace = createLogger(5, "trc", richterm.black)
log.debug = createLogger(4, "dbg", richterm.magenta)
log.info = createLogger(3, "inf", richterm.cyan)
log.warn = createLogger(2, "wrn", richterm.yellow)
log.error = createLogger(1, "err", richterm.red)

return log
