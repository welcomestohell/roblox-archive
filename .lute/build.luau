local cli = require "@batteries/cli"
local collectProjects = require "@monorepo/collectProjects"
local copyInto = require "@lib/utils/copyInto"
local exit = require "@lib/utils/exit"
local fs = require "@std/fs"
local json = require "@std/json"
local path = require "@std/path"
local process = require "@lute/process"
local repoconfig = require "@monorepo/repoconfig"
local stringext = require "@std/stringext"
local types = require "@monorepo/types"

type Globals = { [string]: json.value }

local BASE_DARKLUA = {
	generator = "retain_lines",
	rules = {
		{
			rule = "convert_require",
			current = {
				name = "luau",
				sources = {
					["@src"] = "src",
					["@pkgs"] = "roblox_packages",
				},
			},
			target = {
				name = "roblox",
				rojo_sourcemap = "sourcemap.json",
				indexing_style = "wait_for_child",
			},
		},
		"compute_expression",
		"remove_unused_if_branch",
		"remove_unused_while",
		"filter_after_early_return",
		"remove_empty_do",
		"remove_unused_variable",
		"remove_method_definition",
		"rename_variables",
	},
}

local args = cli.parser()
args:add("script", "positional", { help = "This script" })
args:add("project", "positional", { help = "The project to build" })
args:add("help", "flag", { help = "Shows this message", aliases = { "h" } })
args:add("indev", "flag", { help = "Whether this is an in-development build", aliases = { "dev" } })
args:add("watch", "flag", { help = "Rebuilds the given project on file change" })
args:add("serve", "flag", { help = "Watches for changes and serves the project with Rojo" })
args:add("rojo-port", "option", { help = "Port to serve Rojo to" })

args:parse { ... }

local projects, projectNames, projectByName = collectProjects()

local baseGlobals: Globals = {
	GIT_COMMIT = stringext.trim(process.run({ "git", "rev-parse", "--short", "HEAD" }).stdout),
	GIT_COMMIT_HASH = stringext.trim(process.run({ "git", "rev-parse", "HEAD" }).stdout),
	GIT_BRANCH = stringext.trim(process.run({ "git", "rev-parse", "--abbrev-ref", "HEAD" }).stdout),
	GIT_ORIGIN = stringext.trim(process.run({ "git", "config", "--get", "remote.origin.url" }).stdout),
}

local function resolveProjectDependencies(project: types.Project): { [types.Project]: true }
	local configuration = project.configuration
	if configuration.kind == "library" then
		return {}
	end

	local projectDependencies = {}

	if configuration.placeDependencies then
		for _, used in configuration.placeDependencies do
			local projectDependency = projectByName[used]
			if projectDependencies[projectDependency] then
				continue
			end

			projectDependencies[projectDependency] = true
			for peerDependency in resolveProjectDependencies(projectDependency) do
				projectDependencies[peerDependency] = true
			end
		end
	end

	return projectDependencies
end

local function useDarkluaGlobals(project: types.Project)
	local globals = table.clone(baseGlobals)

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

local function build(project: types.Project, projectDependencies: { [types.Project]: true })
	local projectsToBuild = table.clone(projectDependencies)
	projectsToBuild[project] = true

	local darkluaConfiguration = table.clone(BASE_DARKLUA)
	local globalsTypedefs = {}

	for identifier, value in useDarkluaGlobals(project) do
		table.insert(globalsTypedefs, `\t{identifier}: {typeof(value)},`)
		table.insert(darkluaConfiguration.rules :: any, 1, {
			rule = "inject_global_value",
			identifier = identifier,
			value = value,
		})
	end

	table.sort(globalsTypedefs)
	table.insert(globalsTypedefs, 1, "declare _G: {")
	table.insert(globalsTypedefs, "}")
	fs.writestringtofile(repoconfig.build.darkluaFilename, json.serialize(darkluaConfiguration))
	fs.writestringtofile(path.join(repoconfig.build.typesDir, "globals.d.luau"), table.concat(globalsTypedefs, "\n"))

	for buildProject in projectsToBuild do
		local projectOutputDir = path.join(repoconfig.build.outputDir, buildProject.name)
		pcall(fs.removedirectory, projectOutputDir, { recursive = true })
		copyInto(buildProject.dirPath, projectOutputDir)
		local result = process.run {
			"darklua",
			"process",
			"-c",
			".darklua.json",
			path.format(buildProject.dirPath),
			path.format(projectOutputDir),
		}

		print(result.stdout, result.stderr)
	end

	local outputProject = {
		name = "Welcome To Hell",
		emitLegacyScripts = false,
		tree = {
			["$path"] = "DataModel",
			ReplicatedStorage = {},
			ServerScriptService = {},
		},
	}
end

local targetProjectName = args:get "project"
if targetProjectName == nil or targetProjectName == "help" or args:has "help" then
	args:help()
	return exit(0)
end

local targetProject: types.Project = projectByName[targetProjectName]
if not targetProject then
	print(`Invalid project named {targetProjectName}`)
	print(`Expected one of: {table.concat(projectNames, ", ")}`)
	exit(1)
end

pcall(fs.createdirectory, repoconfig.build.typesDir, { makeparents = true })
pcall(fs.removedirectory, repoconfig.build.outputDir, { recursive = true })
fs.createdirectory(repoconfig.build.outputDir)

local projectDependencies = resolveProjectDependencies(targetProject)
build(targetProject, projectDependencies)
