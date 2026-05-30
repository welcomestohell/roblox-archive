local luau = require("@std/luau")
local path = require("@std/path")
local printer = require("@std/syntax/printer")
local query = require("@std/syntax/query")
local resolveRequires = require("@libs/build/transformers/resolveRequires")
local syntax = require("@std/syntax")
local types = require("@libs/types")
local utils = require("@std/syntax/utils")

local transformers: { types.Transformer } = {
	resolveRequires,
}

local function transpile(ctx: types.BuildContext, filepath: path.Pathlike, source: string)
	for _, transformer in transformers do
		local tree = syntax.parse(source)
		local transformerCtx: types.TransfomerContext = {
			build = ctx,
			filepath = filepath,
			source = source,
			tree = tree,
		}

		source = printer.printFile(tree, transformer(transformerCtx))
	end

	return source
end

return transpile
