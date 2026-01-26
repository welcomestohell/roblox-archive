local configure = require "@monorepo/configure"

return configure.project {
	kind = "place",
	placeId = "",
	placeDependencies = {
		"base-chapter",
	},
}
