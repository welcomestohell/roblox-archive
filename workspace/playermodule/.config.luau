return {
	luau = {
		languagemode = "nocheck",
		lint = { ["*"] = false },
	},
	rose = {
		placeMixin = {
			folderName = "PlayerModule",
			transpile = true,
			mapping = {
				{ name = "StarterPlayer" },
				{ name = "StarterPlayerScripts" },
			},
		},
	},
}
