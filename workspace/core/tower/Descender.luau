local emission = require "@libs/emission"
local std = require "@libs/std"
local toggle = require "@libs/toggle"

local RELEASE_FORCE = Vector3.one * math.huge
local RELEASE_VELOCITY = math.huge

local Descender = std.Mechanic {
	emoji = "⬇️",
	name = "Descender",
	description = "Descends with the weight of other instances to disable itself when it reaches it's End part.",
	instanceType = std.gt.instanceTree {
		Base = std.gt.instanceTree(std.isA.BasePart(), {
			AlignPosition = std.isA.AlignPosition(),
			PrismaticConstraint = std.isA.PrismaticConstraint(),
		}),
		End = std.isA.BasePart(),
	},

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Mass = std.Attribute("Mass", std.gt.positiveNumber, 12.6),

	std.AttributeSection "Toggle",
	ToggleDuration = std.Attribute("ToggleDuration", std.gt.positiveNumber, 1.5),
	ToggleConnectedParts = std.Attribute("ToggleConnectedParts", std.gt.boolean(), true),

	std.AttributeSection "Emission",
	EmitToggledTag = std.Attribute("EmitToggledTag", std.gt.tag, "Descender: On Toggled"),
	EmitRespawnedTag = std.Attribute("EmitRespawnedTag", std.gt.tag, "Descender: On Respawned"),
}

export type DescenderMechanic = std.Mechanic<typeof(Descender)>

function Descender.onStart(self: typeof(Descender), descender: DescenderMechanic, level: std.Level)
	local base = descender.instance.Base
	local align = base.AlignPosition

	descender.life:add(self.Mass:onBind(descender, function(mass: number)
		local oldProperties = base.CustomPhysicalProperties
		local densityMultiplier = 1 / (base.Mass * oldProperties.Density)
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

	if descender:ToggleConnectedParts() then
		for _, connected in base:GetConnectedParts(true) do
			connected.Massless = connected ~= descender
		end
	end

	descender.life:add(descender.instance.End.Touched:Connect(function(toucher: BasePart)
		if toucher ~= base or descender:Active() or not descender:Enabled() then return end
		descender:Active(true)

		local oldForce = align.MaxAxesForce
		local oldVelocity = align.MaxVelocity

		emission.emitTaggedDescendants(descender.instance, descender:EmitToggledTag())
		if descender:ToggleConnectedParts() then
			for _, connected in base:GetConnectedParts(true) do
				toggle.toggleInstance(false, connected)
			end
		else
			toggle.toggleInstance(false, base)
		end

		align.MaxAxesForce = RELEASE_FORCE
		align.MaxVelocity = RELEASE_VELOCITY

		task.wait(descender:ToggleDuration())

		if descender.life.alive then
			emission.emitTaggedDescendants(descender.instance, descender:EmitRespawnedTag())

			if descender:ToggleConnectedParts() then
				for _, connected in base:GetConnectedParts(true) do
					toggle.toggleInstance(true, connected)
				end
			else
				toggle.toggleInstance(true, base)
			end

			align.MaxAxesForce = oldForce
			align.MaxVelocity = oldVelocity

			descender:Active(false)
		end
	end))
end

return Descender
