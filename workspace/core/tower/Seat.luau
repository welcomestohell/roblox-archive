local activation = require "@libs/activation"
local character = require "@libs/character"
local constraints = require "@libs/constraints"
local emission = require "@libs/emission"
local mounts = require "@libs/mounts"
local std = require "@libs/std"

local Seat = std.Mechanic {
	emoji = "🪑",
	name = "Seat",
	description = "When activated, seats the player on top by welding.",
	instanceType = std.isA.BasePart(),

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Offset = std.Attribute("Offset", std.gt.CFrame(), CFrame.identity),

	std.AttributeSection "Emission",
	EmitMountedTag = std.Attribute("EmitMountedTag", std.gt.tag, "Seat: On Mounted"),
	EmitDismountedTag = std.Attribute("EmitMountedTag", std.gt.tag, "Seat: On Dismounted"),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Dismount",
	Dismount = activation.useAttributes "Dismount",
}

export type Seat = typeof(Seat)
export type SeatMechanic = std.Mechanic<Seat>

function Seat.onActivate(self: Seat, seat: SeatMechanic, level: std.Level)
	if seat:Active() or seat:Debounced() then return end

	local rootPart = character.getMaybeHumanoidRootPart()
	local humanoid = character.getMaybeHumanoid()

	if not rootPart or not humanoid or mounts.isMechanicMounted(rootPart, seat) then return end

	local activationLife = seat.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(rootPart, seat))

	local wasActivatable = self.Activation.Enabled(seat)
	self.Activation.Enabled(seat, false)
	seat:Active(true)
	seat:Debounced(true)

	humanoid.Sit = true
	rootPart.CFrame = (seat.instance.CFrame + seat.instance.CFrame.UpVector * (seat.instance.Size.Y / 2 + 1.5))
		* seat:Offset()
	constraints.weld(activationLife, seat.instance, rootPart)
	emission.emitTaggedDescendants(seat.instance, seat:EmitMountedTag())

	activationLife:add(function()
		seat:Active(false)
		seat.life:delay(seat:Cooldown(), function(seat: typeof(seat))
			self.Activation.Enabled(seat, wasActivatable)
			seat:Debounced(false)
		end, seat)

		mounts.dismountMechanic(rootPart, seat)
		rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		emission.emitTaggedDescendants(seat.instance, seat:EmitDismountedTag())
	end)

	activation.bindActivation {
		instanceLife = seat.life,
		instance = seat.instance,
		instanceConfiguration = seat.instanceConfiguration,
		attributes = self.Dismount,
		onActivate = activationLife:wrapDestroy(),
	}
end

return Seat
