const std = require "@libs/std"

const FallingPlatform = std.Mechanic {
	emoji = "⬇️",
	name = "FallingPlatform",
	description = "Description",
	instanceType = std.gt.instanceTree {
		Platform = std.gt.instanceTree(std.isA.BasePart(), {
			AlignPosition = std.isA.AlignPosition(),
			PrismaticConstraint = std.isA.PrismaticConstraint(),
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
	const alignPosition = platform.AlignPosition
	const basePos = platform.Position
	const baseForce = alignPosition.MaxAxesForce
	local falling = false

	alignPosition.Position = basePos
	platform.PrismaticConstraint.UpperLimit = (fallingPlatform.instance.End.Position - basePos).Magnitude + 1

	fallingPlatform.life:add(fallingPlatform.instance.End.Touched:Connect(function(hit)
		if hit ~= platform or falling then return end
		falling = true

		platform.CanCollide = false
		platform.Transparency = 0.5
		alignPosition.MaxAxesForce = Vector3.new(0, baseForce.Y * 1.5, 0)

		local RunService = game:GetService "RunService"
		repeat
			RunService.PreSimulation:Wait()
		until (platform.Position - basePos).Magnitude < 0.05

		platform.CanCollide = true
		platform.Transparency = 0
		alignPosition.MaxAxesForce = baseForce
		falling = false
	end))
end

return FallingPlatform
