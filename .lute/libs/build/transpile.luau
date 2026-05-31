local log = require("@libs/log")
local path = require("@std/path")
local printer = require("@std/syntax/printer")
local resolveRequires = require("@libs/build/transformers/resolveRequires")
local syntax = require("@std/syntax")
local types = require("@libs/types")

local transformers: { types.Transformer } = {
	resolveRequires,
}

local function transpile(ctx: types.BuildContext, filepath: path.Pathlike, source: string)
	for _, transformer in transformers do
		local parseSuccess, treeOrError = pcall(syntax.parse, source)
		if not parseSuccess then
			log.warn("Failed to parse", filepath)
			log.warn(treeOrError)
			return source
		end

		local transformerCtx: types.TransfomerContext = {
			build = ctx,
			filepath = filepath,
			source = source,
			tree = treeOrError,
		}

		source = printer.printFile(treeOrError, transformer(transformerCtx))
	end

	return source
end

return transpile
