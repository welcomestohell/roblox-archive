const activation = require "@libs/activation"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const mounts = require "@libs/mounts"
const std = require "@libs/std"

const Orb = std.Mechanic {
	name = "Orb",
	description = "",
	instanceType = std.isA.BasePart(),

	Mode = std.Attribute("Mode", std.gt.literals { "Launch", "MountLaunch", "MountPivot" }, "Launch" :: "Launch"),
	Force = std.Attribute("Force", std.gt.positiveNumber, 0),
	Timeout = std.Attribute("Timeout", std.gt.number(), 0),

	std.AttributeSection "Pivot",
	XRotationEnabled = std.Attribute("XRotationEnabled", std.gt.boolean(), true),
	YRotationEnabled = std.Attribute("YRotationEnabled", std.gt.boolean(), true),
	ZRotationEnabled = std.Attribute("ZRotationEnabled", std.gt.boolean(), true),

	std.AttributeSection "Tags",
	EmitActivatedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Orb: On Activated"),
	EmitDismountedTag = std.Attribute("EmitDismountedTag", std.gt.tag, "Orb: On Dismounted"),
	EmitLaunchedTag = std.Attribute("EmitLaunchedTag", std.gt.tag, "Orb: On Launched"),

	std.AttributeSection "Activation",
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Activation = activation.useAttributes(),

	std.AttributeSection "Dismount",
	Dismount = activation.useAttributes "Dismount",
}

export type OrbSelf = typeof(Orb)
export type OrbMechanic = std.Mechanic<OrbSelf>

function Orb.launch(orb: OrbMechanic, toucher: BasePart)
	const lookVector = orb.instance.CFrame.LookVector
	const maxForce = if math.abs(lookVector.X) < 0.1 and math.abs(lookVector.Z) < 0.1
		then Vector3.yAxis * 40000
		else Vector3.one * 40000

	const launchLife = orb.life:extend()

	const velocityAttachment = launchLife:add(Instance.new "Attachment")
	const linearVelocity = launchLife:add(Instance.new "LinearVelocity")
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = maxForce
	linearVelocity.VectorVelocity = lookVector * orb:Force()
	linearVelocity.Attachment0 = velocityAttachment

	velocityAttachment.Parent = toucher
	linearVelocity.Parent = toucher

	launchLife:delay(0.125, launchLife:wrapDestroy())
end

function Orb.reactivate(orb: OrbMechanic)
	orb.Activation.Enabled(orb, true)
	orb:Debounced(false)
end

function Orb.onActivate(self: OrbSelf, orb: OrbMechanic, level: std.Level, event: activation.ActivationEvent)
	if orb:Debounced() then return end

	print "not debounced"

	const raw = event.kind == "Touch" and event.toucher or character.getMaybeCharacter()
	print("raw", raw)

	const toucher = mounts.castToucher(raw)
	if not toucher then return end

	print("got toucher", toucher)

	orb.Activation.Enabled(orb, false)
	orb:Debounced(true)

	const mode = orb:Mode()
	if mode == "Launch" then
		orb:launch(toucher)
		orb.life:delay(orb:Cooldown(), self.reactivate, orb)
		return
	end

	if mounts.isMechanicMounted(toucher, orb) then return end

	const activationLife = orb.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(toucher, orb))
	toucher:PivotTo(orb.instance.CFrame)
	constraints.weld(activationLife, toucher, orb.instance)

	const function onDismount(launch: boolean)
		activationLife:destroy()
		mounts.dismountMechanic(toucher, orb)
		orb.life:delay(orb:Cooldown(), self.reactivate, orb)

		if launch then orb:launch(toucher) end
	end

	const timeout = orb:Timeout()
	if timeout > 0 then activationLife:delay(timeout, onDismount, false) end

	activation.bindActivation {
		attributes = self.Dismount,
		instanceLife = activationLife,
		instance = orb.instance,
		instanceConfiguration = orb.instanceConfiguration,
		onActivate = function()
			onDismount(true)
		end,
	}
end

return Orb
