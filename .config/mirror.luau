return {
	remote = "https://github.com/welcomestohell/kit.git",
	branch = "main",

	directory = "mirror",
	targets = {
		"src/core",
		"src/libs",

		".darklua.json",
		"pesde.toml",
		"rokit.toml",
		"selene.toml",
		"selene-std.yaml",

		".lute/mirror.luau",
		".lute/watch.luau",

		"patches",
		".zed",
		".vscode",
	},
}
