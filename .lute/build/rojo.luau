local path = require "@std/path"
local repoconfig = require "@monorepo/repoconfig"
local types = require "@monorepo/types"

local BASE_PLACE_PROJECT = {
	name = "Welcome To Hell",
	emitLegacyScripts = false,
	tree = {
		["$className"] = "DataModel",
		ReplicatedStorage = {
			WTHClient = { ["$className"] = "Folder" },
			WTHShared = { ["$className"] = "Folder" },
			WTHUI = { ["$className"] = "Folder" },
			Packages = { ["$path"] = "roblox_packages" },
			TowerScripts = { ["$className"] = "Folder" },
		},
		ServerScriptService = {
			Packages = { ["$path"] = "roblox_server_packages" },
			WTHServer = { ["$className"] = "Folder" },
		},
	},
}

local function addProjectDirectory(serveParent, sourcemapParent, project: types.Project, dirName: string)
	sourcemapParent[project.instanceName] = {
		["$path"] = { optional = path.join(project.dirPath, dirName) },
	}

	serveParent[project.instanceName] = {
		["$path"] = { optional = path.join(repoconfig.build.outputDir, project.name, dirName) },
	}
end

local function createProjects(projects: { types.Project })
	local serveProject = table.clone(BASE_PLACE_PROJECT)
	local serveReplicated = serveProject.tree.ReplicatedStorage
	local serveServer = serveProject.tree.ServerScriptService

	local sourcemapProject = table.clone(BASE_PLACE_PROJECT)
	local sourcemapReplicated = sourcemapProject.tree.ReplicatedStorage
	local sourcemapServer = sourcemapProject.tree.ServerScriptService

	for _, project in projects do
		if project.configuration.kind == "library" then
			serveReplicated[project.instanceName] = {
				["$path"] = { optional = path.join(repoconfig.build.outputDir, project.name) },
			}

			sourcemapReplicated[project.instanceName] = {
				["$path"] = { optional = path.join(repoconfig.build.inputDir, project.name) },
			}
		else
			addProjectDirectory(serveReplicated.WTHClient, sourcemapReplicated.WTHClient, project, "client")
			addProjectDirectory(serveReplicated.WTHShared, sourcemapReplicated.WTHShared, project, "shared")
			addProjectDirectory(serveServer.WTHServer, sourcemapServer.WTHServer, project, "server")
			addProjectDirectory(serveReplicated.WTHUI, sourcemapReplicated.WTHUI, project, "ui")
			addProjectDirectory(serveReplicated.TowerScripts, sourcemapReplicated.TowerScripts, project, "towerscripts")
		end
	end

	return serveProject, sourcemapProject
end

return table.freeze {
	createProjects = createProjects,
}
