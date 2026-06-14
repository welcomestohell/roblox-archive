-- most of the work is done by Roblox's built in physics.

const std = require "@libs/std"

const FallingPlatform = std.Mechanic {
	emoji = "⬇️",
	name = "FallingPlatform",
	description = "Description",
	instanceType = std.gt.instanceTree {
		Platform = std.gt.instanceTree(std.isA.BasePart(), {
			AlignPosition = std.isA.AlignPosition(),
		}),
		End = std.isA.BasePart(),
	},
}

export type FallingPlatformMechanic = std.Mechanic<typeof(FallingPlatform)>

function FallingPlatform.onStart(
	self: typeof(FallingPlatform),
	fallingPlatform: FallingPlatformMechanic,
	level: std.Level
)
	const platform = fallingPlatform.instance.Platform
	const basePos = platform.Position
	const baseForceY = platform.AlignPosition.MaxAxesForce.Y
	platform.AlignPosition.Position = basePos

	fallingPlatform.instance.End.Touched:Connect(function(a)
		if a == platform then
			platform.CanCollide = false
			platform.Transparency = 0.5
			platform.AlignPosition.MaxAxesForce = Vector3.new(0, baseForceY * 1.5, 0)
			repeat
				task.wait(0.01)
			until (platform.Position - basePos).Magnitude < 0.05
			platform.CanCollide = true
			platform.Transparency = 0
			platform.AlignPosition.MaxAxesForce = Vector3.new(0, baseForceY, 0)
		end
	end)
end

return FallingPlatform
