const emission = require "@libs/emission"
const logger = require "@core/shared/logger"
const Level = require "@libs/core/Level"
const std = require "@libs/std"
const touch = require "@libs/touch"

const Turret = std.Mechanic {
	emoji = "🔫",
	name = "Turret",
	description = "Continously shoot bullets based on its current orientation.",
	instanceType = std.gt.instanceTree {
		Base = std.isA.BasePart(),
		Bullet = std.gt.instanceTree(std.isA.BasePart(), {
			BulletAttachment = std.isA.Attachment(),
			BulletAlignOrientation = std.isA.AlignOrientation(),
			BulletVelocity = std.isA.LinearVelocity(),
		}),
	},

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	SpreadAngle = std.Attribute("SpreadAngle", std.gt.NumberRange, NumberRange.new(0, 0)),

	std.AttributeSection "Bullets",
	Firerate = std.Attribute("Firerate", std.gt.positiveNumber, 1),
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 25),
	Acceleration = std.Attribute("Acceleration", std.gt.Vector3(), Vector3.zero),
	Lifetime = std.Attribute("Lifetime", std.gt.positiveNumber, 2),
	DestroyOnTouch = std.Attribute("DestroyOnTouch", std.gt.boolean(), true),

	std.AttributeSection "Tags",
	IgnoreTag = std.Attribute("IgnoreTag", std.gt.tag, "Turret: Ignore"),
	EmitFireTag = std.Attribute("EmitFireTag", std.gt.tag, "Turret: On Fire"),
	EmitTouchTag = std.Attribute("EmitTouchTag", std.gt.tag, "Turret: On Touch"),
	EmitExpireTag = std.Attribute("EmitExpireTag", std.gt.tag, "Turret: On Expire"),

	std.AttributeSection "Touch",
	Touch = touch.useAttributes(),
}

export type TurretMechanic = std.Mechanic<typeof(Turret), { template: Bullet }>
export type Bullet = typeof(Turret.instanceType.Bullet)

function Turret.calculateSpreadAngle(turret: TurretMechanic, direction: Vector3): Vector3
	const spreadAngleRange: NumberRange = turret:SpreadAngle()

	const directionCFrame = CFrame.new(Vector3.zero, direction)
	const spreadDirection = CFrame.fromOrientation(0, 0, math.random() * math.tau)
	-- stylua: ignore
	const spreadAngle = CFrame.fromOrientation(math.rad(spreadAngleRange.Min + math.random() * (spreadAngleRange.Max - spreadAngleRange.Min)), 0, 0)

	return (directionCFrame * spreadDirection * spreadAngle).LookVector
end

function Turret.onActivate(self: typeof(Turret), turret: TurretMechanic)
	emission.emitTaggedDescendants(turret.instance, turret:EmitFireTag())

	const bulletLife = turret.life:extend()
	const bulletInstance = bulletLife:add(turret.template:Clone())

	const function cleanup(isTouch: boolean?)
		emission.emitTaggedDescendants(
			bulletInstance,
			if isTouch then turret:EmitTouchTag() else turret:EmitExpireTag()
		)
		bulletLife:destroy()
	end

	const spawnCFrame: CFrame = turret.instance.base.CFrame
	const spreadAngle = turret:calculateSpreadAngle(spawnCFrame.LookVector)

	bulletInstance.Massless = true
	bulletInstance:PivotTo(spawnCFrame)

	const mainAttachment = bulletInstance:FindFirstChildOfClass "Attachment"
	const linearVelocity = bulletInstance:FindFirstChildOfClass "LinearVelocity"
	const alignOrientation = bulletInstance:FindFirstChildOfClass "AlignOrientation"

	if not mainAttachment or not linearVelocity or not alignOrientation then return cleanup() end

	local finalCFrame = CFrame.lookAt(spawnCFrame.Position, spawnCFrame.Position + spreadAngle)

	linearVelocity.Attachment0 = mainAttachment
	linearVelocity.VectorVelocity = finalCFrame.LookVector * turret:Speed()
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = math.huge

	alignOrientation.Attachment0 = mainAttachment
	alignOrientation.CFrame = spawnCFrame.Rotation

	bulletInstance.Anchored = false
	bulletInstance.Parent = turret.instance

	bulletLife:add(bulletInstance.Touched:Connect(function(toucher)
		const destroyOnTouch = turret:DestroyOnTouch()
		const isTouched = destroyOnTouch
			and not toucher:IsDescendantOf(turret.instance)
			and not toucher:HasTag(turret:IgnoreTag())
			and (
				toucher.CanCollide
				or touch.isToucherValid(turret.Touch, turret.instance, turret.instanceConfiguration, toucher)
			)

		if isTouched then cleanup(true) end
	end))

	bulletLife:delay(turret:Lifetime(), cleanup, nil)
end

function Turret.onStart(self: typeof(Turret), turret: TurretMechanic, level: std.Level)
	const instance = turret.instance
	const primaryPart = instance.PrimaryPart

	if not primaryPart then
		logger:Error("Turret", instance:GetFullName(), "is missing the PrimaryPart.")
		return
	end

	-- Turret is already loaded by the time this is called. We add the tag here
	-- so spawned bullets don't automatically load until we're done intializing
	-- them.
	turret.instance:AddTag(Level.DO_NOT_LOAD_TAG)

	turret.template = turret.life:add(instance.Bullet)
	turret.template.Parent = nil
	turret.template:AddTag "Bullet"

	turret.life:spawn(function()
		while not turret.life.destroyed do
			task.wait(1 / turret:Firerate())
			if turret:Enabled() then self:onActivate(turret) end
		end
	end)
end

return Turret
