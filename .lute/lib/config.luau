local fs = require("@std/fs")
local luau = require("@std/luau")
local path = require("@std/path")
local process = require("@std/process")

export type Config = {
	wth: {
		patches: {
			dir: string,
			indexes: { string },
		},
	},
}

local CONFIG_FILE_NAME = ".config.luau"

local function read(dir: path.pathlike?): Config
	local dir = dir or process.cwd()
	local filepath = path.join(dir, CONFIG_FILE_NAME)
	local source = fs.readfiletostring(filepath)
	local bytecode = luau.compile(source)
	local load = luau.load(bytecode)
	return load()
end

return table.freeze({ read = read })
