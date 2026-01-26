local cli = require "@batteries/cli"
local collectProjects = require "@monorepo/collectProjects"
local copyInto = require "@lib/utils/copyInto"
local exit = require "@lib/utils/exit"
local fs = require "@std/fs"
local json = require "@std/json"
local path = require "@std/path"
local repoconfig = require "@monorepo/repoconfig"
local types = require "@monorepo/types"

local BASE_DARKLUA = {
	generator = "retain_lines",
	rules = {
		{
			rule = "convert_require",
			current = {
				sources = {
					src = "../src",
					pkgs = "../roblox_packages",
				},
			},
			target = "roblox",
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
args:add("indev", "flag", { help = "Whether this is an in-development build" })
args:add("watch", "flag", { help = "Rebuilds the given project on file change" })
args:add("serve", "flag", { help = "Watches for changes and serves the project with Rojo" })
args:add("rojo-port", "option", { help = "Port to serve Rojo to" })

args:parse { ... }

local projects, projectNames, projectByName = collectProjects()

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

local function build(project: types.Project, projectDependencies: { [types.Project]: true })
	local projectsToBuild = table.clone(projectDependencies)
	projectsToBuild[project] = true

	for buildProject in projectsToBuild do
		local projectOutputDir = path.join(repoconfig.build.outputDir, buildProject.name)
		pcall(fs.removedirectory, projectOutputDir, { recursive = true })
		copyInto(buildProject.dirPath, projectOutputDir)
	end

	local darkluaConfiguration = table.clone(BASE_DARKLUA)
	local globals = table.clone(repoconfig.build.globals) :: { [string]: json.value }
	globals.BUILD_TIME = ""
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

pcall(fs.removedirectory, repoconfig.build.outputDir, { recursive = true })
fs.createdirectory(repoconfig.build.outputDir)

local projectDependencies = resolveProjectDependencies(targetProject)
build(targetProject, projectDependencies)
