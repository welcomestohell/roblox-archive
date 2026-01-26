local cli = require "@batteries/cli"
local configure = require "@monorepo/configure"
local fs = require "@std/fs"
local log = require "@lib/utils/log"
local path = require "@std/path"
local pp = require "@batteries/pp"
local process = require "@lute/process"
local repoconfig = require "@monorepo/repoconfig"

type Project = {
	name: string,
	instanceName: string,
	configuration: configure.ProjectConfiguration,
	configurationPath: path.path,
	dirPath: path.path,
}

local args = cli.parser()
args:add("script", "positional", { help = "This script", required = true })
args:add("subcommand", "positional", { help = "One of: [help|list|build|watch|serve]", required = true })
args:add("help", "flag", { help = "Shows help for the (sub)command", aliases = { "h" } })
args:add("log-level", "option", { help = "Log level" })
args:add("rojo-port", "option", { help = "Port to serve to Rojo" })

args:parse { ... }
log.level = tonumber(args:get "log-level") or 3

local function exit(code: number)
	process.exit(code)
end

local function requireUnsafe(modulePath: string)
	return (require)(modulePath)
end

local function toPascalCase(str: string)
	local segments = string.split(str, "-")
	for index, substring in segments do
		segments[index] = string.upper(string.sub(substring, 1, 1)) .. string.sub(substring, 2, -1)
	end
	return table.concat(segments)
end

local function collectProjects()
	log.trace "Collecting projects"

	local projects: { Project } = {}
	local projectNames: { string } = {}
	local projectsByName: { [string]: Project } = {}

	for _, entry in fs.listdirectory(repoconfig.build.inputDir) do
		local projectPath = path.join(repoconfig.build.inputDir, entry.name)
		local configurationRequirePath = path.join(projectPath, repoconfig.build.configurationBasename)
		local configurationPath = path.join(projectPath, repoconfig.build.configurationBasename .. ".luau")

		if not fs.exists(configurationPath) then
			continue
		end

		log.trace("Checking project named", entry.name)

		local requireSuccess, configurationOrError =
			pcall(requireUnsafe, path.format(path.join("..", configurationRequirePath)))

		if not requireSuccess then
			log.warn(`Failed to require configuration for project {entry.name}:`)
			log.warn(configurationOrError)
			continue
		end

		local configurationResult = configure.validators.ProjectConfiguration:match(configurationOrError)
		if configurationResult.ok then
			local self: Project = {
				name = entry.name,
				instanceName = toPascalCase(entry.name),
				configuration = configurationOrError :: any,
				configurationPath = configurationPath,
				dirPath = projectPath,
			}

			table.insert(projects, self)
			table.insert(projectNames, entry.name :: string)
			projectsByName[entry.name] = self
			log.debug("Collected project", entry.name)
		else
			log.warn(`Invalid configuration for project {entry.name}:`)
			log.warn(configurationResult:format())
			continue
		end
	end

	log.info "Finished collecting projects"
	return projects, projectNames, projectsByName
end

local subcommand = args:get "subcommand"
if subcommand == "help" then
	print "Welcome To Hell's build orchestrator"
	print ""
	print "List all projects:"
	print "\tlute wthelly list"
	print ""
	print "Build the given project:"
	print "\tlute wthelly build chapter-1"
	print ""
	print "Watch for changes and serve to Rojo:"
	print "\tlute wthelly watch chapter-1"
	print "\tlute wthelly serve kit"
	print ""

	args:help()

	return exit(0)
end

local projects, projectNames, projectsByName = collectProjects()

local targetProjects: { Project } = {}
local forwardedProjectNames = args:forwarded()
if forwardedProjectNames and #forwardedProjectNames > 0 then
	log.info "Using forwarded projects"
	for index, forwarded in forwardedProjectNames do
		local project = projectsByName[forwarded]
		if not project then
			log.error("Unknown project named", forwarded)
			log.error("Valid projects:", table.concat(projectNames, ", "))
			return exit(1)
		end
		targetProjects[index] = project
	end
else
	if args:has "all" then
		log.info "Using all projects"
		table.move(projects, 1, #projects, 1, targetProjects)
	else
		log.error "No projects specified, either specify a project like `kit` or specify `--all`"
		return exit(1)
	end
end
