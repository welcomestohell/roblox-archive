const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const std = require "@libs/std"

const Seat = std.Mechanic {}
export type SeatMechanic = std.Mechanic<typeof(Seat)>
Seat.name = "Seat"
Seat.instanceType = std.isA.BasePart()
Seat.emoji = "🪑"

Seat.Cooldown = Seat:attribute("Cooldown", std.gt.positiveNumber, 1)
Seat.Offset = Seat:attribute("Offset", std.gt.CFrame(), CFrame.identity)
Seat.Activation = activation.useAttributes(Seat)
Seat.Deactivation = activation.useAttributes(Seat, "Deactivation")

-- FIXME: You can mount yourself on multiple seats. EToH solves this with a
-- shared mountedCOs table, we might need a mounts library
function Seat.onActivate(self: typeof(Seat), seat: SeatMechanic, level: std.Level)
	const rootPart = character.getMaybeHumanoidRootPart()
	const humanoid = character.getMaybeHumanoid()

	if not rootPart or not humanoid then return end

	self.Activation.Enabled(seat, false)
	humanoid.Sit = true

	const deactivationLife = seat.life:extend()
	rootPart.CFrame = (seat.instance.CFrame + seat.instance.CFrame.UpVector * (seat.instance.Size.Y / 2 + 1.5))
		* seat:Offset()
	constraints.weld(deactivationLife, seat.instance, rootPart)

	deactivationLife:add(function()
		rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		seat.life:delay(seat:Cooldown(), Attribute.set :: any, self.Activation.Enabled, seat, true)
	end)

	activation.bindActivation {
		instanceLife = seat.life,
		instance = seat.instance,
		instanceConfiguration = seat.instanceConfiguration,
		attributes = self.Deactivation,
		onActivate = deactivationLife:wrapDestroy() :: (...any) -> (),
	}
end

return Seat
