const activation = require "@libs/activation"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const mounts = require "@libs/mounts"
const std = require "@libs/std"

const Seat = std.Mechanic {
	emoji = "🪑",
	name = "Seat",
	description = "When activated, seats the player on top by welding.",
	instanceType = std.isA.BasePart(),

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Offset = std.Attribute("Offset", std.gt.CFrame(), CFrame.identity),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Deactivation",
	Deactivation = activation.useAttributes "Deactivation",
}

export type SeatMechanic = std.Mechanic<typeof(Seat)>

function Seat.onActivate(self: typeof(Seat), seat: SeatMechanic, level: std.Level)
	const rootPart = character.getMaybeHumanoidRootPart()
	const humanoid = character.getMaybeHumanoid()

	if not rootPart or not humanoid or mounts.isMechanicMounted(rootPart, seat) then return end
	const activationLife = seat.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(rootPart, seat))

	const wasActivatable = self.Activation.Enabled(seat)
	self.Activation.Enabled(seat, false)
	seat:Active(true)
	seat:Debounced(true)

	humanoid.Sit = true
	rootPart.CFrame = (seat.instance.CFrame + seat.instance.CFrame.UpVector * (seat.instance.Size.Y / 2 + 1.5))
		* seat:Offset()
	constraints.weld(activationLife, seat.instance, rootPart)

	activationLife:add(function()
		mounts.dismountMechanic(rootPart, seat)
		rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		self:Active(false)
		seat.life:delay(seat:Cooldown(), function(seat: typeof(seat))
			if seat.life.alive then
				self.Activation.Enabled(seat, wasActivatable)
				self:Debounced(false)
			end
		end, seat)
	end)

	activation.bindActivation {
		instanceLife = seat.life,
		instance = seat.instance,
		instanceConfiguration = seat.instanceConfiguration,
		attributes = self.Deactivation,
		onActivate = activationLife:wrapDestroy(),
	}
end

return Seat
