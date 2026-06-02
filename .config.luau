-- Aliases are generated with the `lute aliases` script. Don't edit this region!
-- #region aliases
local aliases = {
	chapter = "chapter",
	chapter1 = "chapter1",
	chapter2 = "chapter2",
	chapter3 = "chapter3",
	chapter4 = "chapter4",
	chapter5 = "chapter5",
	chapter6 = "chapter6",
	chapter7 = "chapter7",
	core = "core",
	libs = "libs",
	prvdmwrong = "prvdmwrong",
	roblox_packages = "roblox_packages",
	title = "title",
	universe = "universe",
}
-- #endregion

return {
	luau = {
		languagemode = "strict",
		lint = { ["*"] = true, LocalShadow = false },
		aliases = aliases,
	},
	wth = {
		paths = {
			output = ".output",
			outputProject = "default.project.json",
			sourcemapProject = "sourcemap.project.json",
			sourcemap = "sourcemap.json",
		},
		rojo = {
			mappings = {
				client = {
					{ name = "ReplicatedStorage" },
					{ name = "Internal", className = "Folder" },
					{ name = "Client", className = "Folder" },
				},
				server = {
					{ name = "ServerScriptService" },
					{ name = "Internal", className = "Folder" },
					{ name = "Server", className = "Folder" },
				},
				shared = {
					{ name = "ReplicatedStorage" },
					{ name = "Internal", className = "Folder" },
					{ name = "Shared", className = "Folder" },
				},
				ui = {
					{ name = "ReplicatedStorage" },
					{ name = "Internal", className = "Folder" },
					{ name = "UI", className = "Folder" },
				},
				tower = {
					{ name = "ReplicatedStorage" },
					{ name = "TowerScripts", className = "Folder" },
				},
				assets = {
					{ name = "ReplicatedStorage" },
					{ name = "Internal", className = "Folder" },
					{ name = "Assets", className = "Folder" },
				},
			},
		},
	},
}
