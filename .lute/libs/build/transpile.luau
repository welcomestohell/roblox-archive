local luau = require("@std/luau")
local path = require("@std/path")
local printer = require("@std/syntax/printer")
local query = require("@std/syntax/query")
local syntax = require("@std/syntax")
local types = require("@libs/types")
local utils = require("@std/syntax/utils")

local function transpile(state: types.BuildState, filepath: path.Pathlike, source: string)
	local tree = syntax.parse(source)

	local replacements = query
		.findAllFromRoot(tree, utils.isExprCall)
		:filter(function(call: syntax.AstExprCall): boolean
			return call.func.tag == "global" and call.func.name.text == "require"
		end)
		:replace(function(call: syntax.AstExprCall)
			local pathArgument = call.arguments[1]
			if not pathArgument or pathArgument.node.tag ~= "string" then
				return nil
			end

			local resolverOk, resolvedPath = pcall(luau.resolveModule, pathArgument.node.token.text, filepath)
			if not resolverOk then
				return nil
			end

			local requirePath = state.sourcemapIndices[path.format(resolvedPath)]

			if requirePath then
				print(requirePath)
				return `require({requirePath})`
			end

			return nil
		end)

	return printer.printFile(tree, replacements)
end

return transpile
