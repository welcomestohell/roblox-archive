const emission = require "@libs/emission"
const std = require "@libs/std"
const toggle = require "@libs/toggle"

const RELEASE_FORCE = Vector3.one * math.huge
const RELEASE_VELOCITY = math.huge

const FallingPlatform = std.Mechanic {
	emoji = "⬇️",
	name = "FallingPlatform",
	description = "Descends with the weight of other instances to disable itself when it reaches it's End part.",
	instanceType = std.gt.instanceTree {
		Base = std.gt.instanceTree(std.isA.BasePart(), {
			AlignPosition = std.isA.AlignPosition(),
			PrismaticConstraint = std.isA.PrismaticConstraint(),
		}),
		End = std.isA.BasePart(),
	},

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Mass = std.Attribute("Mass", std.gt.positiveNumber, 12.6),

	std.AttributeSection "Toggle",
	ToggleDuration = std.Attribute("ToggleDuration", std.gt.positiveNumber, 1.5),
	ToggleConnectedParts = std.Attribute("ToggleConnectedParts", std.gt.boolean(), true),

	std.AttributeSection "Emission",
	EmitToggledTag = std.Attribute("EmitToggledTag", std.gt.tag, "FallingPlatform: On Toggled"),
	EmitRespawnedTag = std.Attribute("EmitRespawnedTag", std.gt.tag, "FallingPlatform: On Respawned"),
}

export type FallingPlatformMechanic = std.Mechanic<typeof(FallingPlatform)>

function FallingPlatform.onStart(
	self: typeof(FallingPlatform),
	fallingPlatform: FallingPlatformMechanic,
	level: std.Level
)
	const base = fallingPlatform.instance.Base
	const align = base.AlignPosition

	fallingPlatform.life:add(self.Mass:onBind(fallingPlatform, function(mass: number)
		const oldProperties = base.CustomPhysicalProperties
		const densityMultiplier = 1 / (base.Mass * oldProperties.Density)
		base.CustomPhysicalProperties = PhysicalProperties.new(
			densityMultiplier * mass,
			oldProperties.Friction,
			oldProperties.Elasticity,
			oldProperties.FrictionWeight,
			oldProperties.ElasticityWeight
		)
		align.MaxAxesForce = Vector3.yAxis * ((workspace.Gravity * base.Mass) + 58)
	end))

	align.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	align.ForceRelativeTo = Enum.ActuatorRelativeTo.World
	align.Position = base.Position
	base.Anchored = false

	if fallingPlatform:ToggleConnectedParts() then
		for _, connected in base:GetConnectedParts(true) do
			connected.Massless = true
		end
	end

	fallingPlatform.life:add(fallingPlatform.instance.End.Touched:Connect(function(toucher: BasePart)
		if toucher ~= base or fallingPlatform:Active() or not fallingPlatform:Enabled() then return end
		fallingPlatform:Active(true)

		const oldForce = align.MaxAxesForce
		const oldVelocity = align.MaxVelocity

		emission.emitTaggedDescendants(fallingPlatform.instance, fallingPlatform:EmitToggledTag())
		toggle.toggleInstance(false, base)
		if fallingPlatform:ToggleConnectedParts() then
			for _, connected in base:GetConnectedParts(true) do
				toggle.toggleInstance(false, base)
			end
		end

		align.MaxAxesForce = RELEASE_FORCE
		align.MaxVelocity = RELEASE_VELOCITY

		task.wait(fallingPlatform:ToggleDuration())

		-- By now, the falling platform could be destroyed, so we check again.
		if fallingPlatform.life.alive then
			emission.emitTaggedDescendants(fallingPlatform.instance, fallingPlatform:EmitRespawnedTag())

			toggle.toggleInstance(true, base)
			if fallingPlatform:ToggleConnectedParts() then
				for _, connected in base:GetConnectedParts(true) do
					toggle.toggleInstance(true, base)
				end
			end

			align.MaxAxesForce = oldForce
			align.MaxVelocity = oldVelocity

			fallingPlatform:Active(false)
		end
	end))
end

return FallingPlatform
