local cst = require "@std/syntax"
local fs = require "@std/fs"
local json = require "@std/json"
local log = require "@libs/log"
local luau = require "@std/luau"
local path = require "@std/path"
local query = require "@std/syntax/query"
local useRepositoryConfig = require "@libs/useRepositoryConfig"
local utils = require "@std/syntax/utils"

type Context<Options = { [any]: any }> = {
	path: string,
	source: string,
	parseresult: cst.ParseResult,
	options: Options,
}

local function transformQuery(ctx: Context)
	local repository = useRepositoryConfig()
	local sourcemap = json.deserialize(fs.readFileToString(repository.wth.paths.sourcemap))

	return query
		.findAllFromRoot(ctx.parseresult, utils.isExprCall)
		:filter(function(call: cst.AstExprCall)
			return call.func.tag == "global" and call.func.name.text == "require"
		end)
		:replace(function(fn: cst.AstExprCall)
			local pathArgument = fn.arguments[1]
			if not pathArgument or pathArgument.node.tag ~= "string" then
				return nil
			end

			print(
				"RESOLVING",
				pathArgument.node.token.text,
				"TO",
				luau.resolveModule(pathArgument.node.token.text, ctx.path)
			)

			-- log.info(fn.func)
			return nil
		end)
end

return transformQuery
