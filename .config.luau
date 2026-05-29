return {
	luau = {
		languagemode = "strict",
		lint = { ["*"] = true },
	},
	wth = {
		paths = {
			output = ".output",
			outputCache = ".output/cache.json",

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
			},
		},
	},
}
