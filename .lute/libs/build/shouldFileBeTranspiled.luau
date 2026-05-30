local getMemberFromPath = require("@libs/getMemberFromPath")
local types = require("@libs/types")
local path = require("@std/path")
local process = require("@std/process")

local function shouldFileBeTranspiled(monorepo: types.Monorepo, absolutePath: path.Pathlike)
	local filepath = path.relative(process.cwd(), absolutePath)
	local member = getMemberFromPath(monorepo, filepath)

	return not member.placeMixin or member.placeMixin.transpile
end

return shouldFileBeTranspiled
