local process = require "@lute/process"

local function exit(code: number)
	process.exit(code)
end

return exit
