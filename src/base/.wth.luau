local configure = require "@monorepo/configure"

return configure.project {
	kind = "abstract-place",
	placeDependencies = {
		"lib",
	},
}
