local casing = require "@lib/utils/casing"
local fs = require "@std/fs"
local log = require "@lib/utils/log"
local path = require "@std/path"
local repoconfig = require "@monorepo/repoconfig"
local requireCwd = require "@lib/utils/requireCwd"
local types = require "./types"
local function collectProjects()
	local projects: { types.Project } = {}
	local projectNames: { string } = {}
	local projectsByName: { [string]: types.Project } = {}

	for _, entry in fs.listdirectory(repoconfig.build.inputDir) do
		local projectPath = path.join(repoconfig.build.inputDir, entry.name)
		local configurationRequirePath = path.join(projectPath, repoconfig.build.configurationBasename)
		local configurationPath = path.join(projectPath, repoconfig.build.configurationBasename .. ".luau")

		if not fs.exists(configurationPath) then
			continue
		end

		local requireSuccess, configurationOrError = pcall(requireCwd, configurationRequirePath)

		if not requireSuccess then
			log.warn(`Failed to require configuration for project {entry.name}:`)
			log.warn(configurationOrError)
			continue
		end

		local configurationResult = types.ProjectConfiguration:match(configurationOrError)
		if configurationResult.ok then
			local self: types.Project = {
				name = entry.name,
				instanceName = casing.toPascalCase(entry.name),
				configuration = configurationOrError :: any,
				configurationPath = configurationPath,
				dirPath = projectPath,
			}

			table.insert(projects, self)
			table.insert(projectNames, entry.name :: string)
			projectsByName[entry.name] = self
		else
			log.warn(`Invalid configuration for project {entry.name}:`)
			log.warn(configurationResult:format())
			continue
		end
	end

	return projects, projectNames, projectsByName
end

return collectProjects
