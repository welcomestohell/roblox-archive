return {
	rose = {
		workspace = {
			name = "Welcome To Hell",
			members = { "./workspace/*", "./workplace/*" },

			build = {
				globals = {
					WTH_CHAPTER_TITLE = {},
				},
				idl = {
					program = "blink",
					filename = ".blink",
					initArguments = {},
					watchArguments = { "--watch" },
				},
				scripts = {
					preInit = "asphalt sync studio",
				},
				place = {
					baseProject = {
						globIgnorePaths = { "**/.config.luau" },
						emitLegacyScripts = false,
						tree = {
							["$className"] = "DataModel",
							Workspace = {
								["$properties"] = {
									LuauTypeCheckMode = "Strict",
									UseNewLuauTypeSolver = "Enabled",
								},
							},
							Lighting = {
								["$properties"] = {
									PrioritizeLightingQuality = true,
									LightingStyle = "Realistic",
								},
							},
							ReplicatedStorage = {
								Packages = { ["$path"] = { optional = "./roblox_packages" } },
							},
							ServerScriptService = {
								Packages = { ["$path"] = { optional = "./roblox_server_packages" } },
							},
						},
					},
					dirMappings = {
						client = {
							{ name = "ReplicatedStorage" },
							{ name = "Internal", className = "Folder" },
							{ name = "Client", className = "Folder" },
						},
						shared = {
							{ name = "ReplicatedStorage" },
							{ name = "Internal", className = "Folder" },
							{ name = "Shared", className = "Folder" },
						},
						server = {
							{ name = "ServerScriptService" },
							{ name = "Internal", className = "Folder" },
							{ name = "Server", className = "Folder" },
						},
						ui = {
							{ name = "ReplicatedStorage" },
							{ name = "Internal", className = "Folder" },
							{ name = "UI", className = "Folder" },
						},
						assets = {
							{ name = "ReplicatedStorage" },
							{ name = "Assets", className = "Folder" },
						},
						tower = {
							{ name = "ReplicatedStorage" },
							{ name = "TowerScripts", className = "Folder" },
						},
					},
				},
			},

			profiles = {
				godmothersfire = {},
			},
		},
	},
	luau = {
		languagemode = "strict",
		lint = { ["*"] = true, LocalShadow = false },
		aliases = {
			-- Pesde
			pkgs = "roblox_packages",
			serverpkgs = "roblox_server_packages",
			-- Workplace
			chapter1 = "workplace/chapter1",
			chapter2 = "workplace/chapter2",
			chapter3 = "workplace/chapter3",
			chapter4 = "workplace/chapter4",
			chapter5 = "workplace/chapter5",
			chapter6 = "workplace/chapter6",
			chapter7 = "workplace/chapter7",
			kit = "workplace/kit",
			title = "workplace/title",
			-- Workspace
			chapter = "workspace/chapter",
			core = "workspace/core",
			libs = "workspace/libs",
			universe = "workspace/universe",
			playermodule = "workspace/playermodule",
		},
	},
}
