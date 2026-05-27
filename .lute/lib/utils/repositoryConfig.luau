local fs = require("@std/fs")
local luau = require("@std/luau")
local path = require("@std/path")
local process = require("@std/process")

-- RFC prevents .config.luau files from being required????
local function repositoryConfig(): typeof(require("@lib/../../.config"))
	local contents = fs.readFileToString(path.join(process.cwd(), ".config.luau"))
	return luau.load(luau.compile(contents))()
end

return repositoryConfig
