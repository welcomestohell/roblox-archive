local cli = require "@batteries/cli"
local json = require "@std/json"
local process = require "@lute/process"
local repoconfig = require "@monorepo/repoconfig"
local stringext = require "@std/stringext"
local types = require "@monorepo/types"

export type Globals = { [string]: json.value }

local function git(...: string)
	return stringext.trim(process.run({ "git", ... }).stdout)
end

local BASE_GLOBALS: Globals = {
	GIT_COMMIT = git("rev-parse", "--short", "HEAD"),
	GIT_COMMIT_HASH = git("rev-parse", "HEAD"),
	GIT_BRANCH = git("rev-parse", "--abbrev-ref", "HEAD"),
	GIT_ORIGIN = git("config", "--get", "remote.origin.url"),
}

local function createGlobals(args: cli.Parser, project: types.Project)
	local globals = table.clone(BASE_GLOBALS)

	globals.__DEV__ = args:has "indev"
	globals.__CI__ = process.env.GITHUB_ACTIONS ~= nil

	globals.BUILD_TIMESTAMP_EPOCH = os.time()

	globals.PROJECT_NAME = project.name
	globals.PROJECT_INSTANCE_NAME = project.instanceName
	globals.PROJECT_KIND = project.configuration.kind

	for identifier, value in repoconfig.build.globals :: Globals do
		globals[identifier] = value
	end

	return globals
end

return table.freeze {
	createGlobals = createGlobals,
}
