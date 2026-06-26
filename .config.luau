return {
	rose = {
		workspace = {
			name = "Welcome To Hell",
			members = { "./workspace/*" },

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
					folderCasing = "pascal",
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
			chapter = "workspace/chapter",
			chapter1 = "workspace/chapter1",
			chapter2 = "workspace/chapter2",
			chapter3 = "workspace/chapter3",
			chapter4 = "workspace/chapter4",
			chapter5 = "workspace/chapter5",
			chapter6 = "workspace/chapter6",
			chapter7 = "workspace/chapter7",
			core = "workspace/core",
			kit = "workspace/kit",
			libs = "workspace/libs",
			title = "workspace/title",
			universe = "workspace/universe",
			pkgs = "roblox_packages",
			serverpkgs = "roblox_server_packages",
		},
	},
}
