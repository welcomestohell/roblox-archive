return {
	luau = {
		languagemode = "nocheck",
		lint = { ["*"] = false },
	},
	rose = {
		placeMixin = {
			transpile = true,
			mapping = {
				{ name = "StarterPlayer" },
				{ name = "StarterPlayerScripts" },
			},
		},
	},
}
