return {
	luau = {
		languageMode = "strict",
		lint = { ["*"] = true },
		aliases = {
			src = "./src",
			pkgs = "./Packages",
		},
	},
	wth = {
		dirs = {
			source = "src",
			output = "out",
			patches = "patches",
			packages = "Packages",
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
			sourceTree = {
				["$className"] = "DataModel",
				ReplicatedStorage = {
					Packages = { ["$path"] = { optional = "Packages" } },
					DevPackages = { ["$path"] = { optional = "DevPackages" } },
					Libs = { ["$path"] = { optional = "src/libs" } },
				},
				ServerScriptService = {
					Packages = { ["$path"] = { optional = "ServerPackages" } },
				},
			},
			outputTree = {
				["$className"] = "DataModel",
				ReplicatedStorage = {
					Packages = { ["$path"] = { optional = "Packages" } },
					DevPackages = { ["$path"] = { optional = "DevPackages" } },
					Libs = { ["$path"] = { optional = "out/libs" } },
				},
				ServerScriptService = {
					Packages = { ["$path"] = { optional = "ServerPackages" } },
				},
			},
		},
	},
}
