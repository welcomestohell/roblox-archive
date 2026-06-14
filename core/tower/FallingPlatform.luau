const std = require "@libs/std"

const FallingPlatform = std.Mechanic {
	emoji = "⬇️",
	name = "FallingPlatform",
	description = "Description",
	instanceType = std.isA.Instance(),
}

export type FallingPlatformMechanic = std.Mechanic<typeof(FallingPlatform)>

return FallingPlatform
