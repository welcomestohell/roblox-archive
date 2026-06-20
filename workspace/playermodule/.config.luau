return {
	luau = {
		languagemode = "nocheck",
		lint = { ["*"] = false },
	},
	rose = {
		placeMixin = {
			mapping = {
				{ name = "StarterPlayer" },
				{ name = "StarterPlayerScripts" },
			},
		},
	},
}
