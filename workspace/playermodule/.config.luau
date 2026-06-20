return {
	luau = {
		languagemode = "nocheck",
		lint = { ["*"] = false },
	},
	wth = {
		placeMixin = {
			transpile = true,
			folderName = "PlayerModule",
			rojo = {
				{ name = "StarterPlayer" },
				{ name = "StarterPlayerScripts" },
			},
		},
	},
}
