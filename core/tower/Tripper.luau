const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const character = require "@libs/character"
const properties = require "@libs/properties"
const std = require "@libs/std"

const Tripper = std.Mechanic {}
export type TripperMechanic = std.Mechanic<typeof(Tripper)>

Tripper.mechanicName = "Tripper"
Tripper.instanceType = std.isA.BasePart()
Tripper.debuggerEmoji = "🧀"

Tripper.Cooldown = Tripper:attribute("Cooldown", std.gt.positiveNumber, 0)
Tripper.StunDuration = Tripper:attribute("StunDuration", std.gt.positiveNumber, 0)
Tripper.Activation = activation.useAttributes(Tripper)

function Tripper.onActivate(self: typeof(Tripper), tripper: TripperMechanic)
	const humanoid = character.getMaybeHumanoid()
	if humanoid then
		const stunDuration = tripper:StunDuration()
		const property = if stunDuration > 0 then "PlatformStand" else "Sit"
		if properties.getUnsafe(humanoid, property) then return end

		self.Activation.Enabled(tripper, false)
		properties.setUnsafe(humanoid, property, true)
		tripper.life:delay(
			stunDuration + tripper:Cooldown(),
			Attribute.set :: any,
			self.Activation.Enabled,
			tripper,
			true
		)

		if property == "PlatformStand" then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			tripper.life:delay(stunDuration, properties.setUnsafe, humanoid, property, false)
			tripper.life:delay(stunDuration, humanoid.SetStateEnabled, humanoid, Enum.HumanoidStateType.Jumping, true)
		end
	end
end

return Tripper
