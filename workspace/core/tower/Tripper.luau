local activation = require "@libs/activation"
local character = require "@libs/character"
local instances = require "@libs/instances"
local std = require "@libs/std"

local Tripper = std.Mechanic {
	emoji = "🧀",
	name = "Tripper",
	description = "When activated, trips the player by making them sit down.",
	instanceType = std.isA.BasePart(),

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	StunDuration = std.Attribute("StunDuration", std.gt.positiveNumber, 0),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type TripperMechanic = std.Mechanic<typeof(Tripper)>

function Tripper.onActivate(self: typeof(Tripper), tripper: TripperMechanic)
	if tripper:Active() then return end

	local humanoid = character.getMaybeHumanoid()
	if humanoid then
		local stunDuration = tripper:StunDuration()
		local property = if stunDuration > 0 then "PlatformStand" else "Sit"
		if instances.getUnsafe(humanoid, property) then return end

		local wasActivatable = self.Activation.Enabled(tripper)
		self.Activation.Enabled(tripper, false)
		tripper:Active(true)
		tripper:Debounced(true)

		instances.setUnsafe(humanoid, property, true)

		if property == "PlatformStand" then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			tripper.life:delay(stunDuration, instances.setUnsafe, humanoid, property, false)
			tripper.life:delay(stunDuration, humanoid.SetStateEnabled, humanoid, Enum.HumanoidStateType.Jumping, true)
		end

		tripper:Active(false)
		tripper.life:delay(tripper:Cooldown(), function(tripper: typeof(tripper))
			tripper:Debounced(false)
			self.Activation.Enabled(tripper, wasActivatable)
		end, tripper)
	end
end

return Tripper
