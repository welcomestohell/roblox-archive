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

	std.AttributeSection "Mount",
	Mount = activation.useAttributes "Mount",
}

export type OrbSelf = typeof(Orb)
export type OrbMechanic = std.Mechanic<OrbSelf, { activationLife: std.Life? }>

function Orb.launch(orb: OrbMechanic, toucher: BasePart)
	const upVector = orb.instance.CFrame.UpVector
	const maxForce = if math.abs(upVector.X) < 0.1 and math.abs(upVector.Z) < 0.1
		then Vector3.yAxis * 40000
		else Vector3.one * 40000

	const launchLife = orb.life:extend()

	const velocityAttachment = launchLife:add(Instance.new "Attachment")
	const linearVelocity = launchLife:add(Instance.new "LinearVelocity")
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = maxForce
	linearVelocity.VectorVelocity = upVector * orb:Force()
	linearVelocity.Attachment0 = velocityAttachment

	velocityAttachment.Parent = toucher
	linearVelocity.Parent = toucher

	launchLife:delay(0.125, launchLife:wrapDestroy())
end

function Orb.onStart(self: OrbSelf, orb: OrbMechanic)
	const function onMount(context: activation.ActivationContext, event: activation.ActivationEvent)
		const toucher = mounts.castToucher(event.kind == "Touch" and event.toucher or character.getMaybeCharacter())

		if not toucher or mounts.isMechanicMounted(toucher, orb) then return end
		if orb.activationLife then orb.activationLife:destroy() end

		const activationLife = context.instanceLife:extend()
		orb.activationLife = activationLife
		activationLife:destroyOn(mounts.mountMechanic(toucher, orb))
		toucher:PivotTo(orb.instance.CFrame)
		constraints.weld(activationLife, toucher, orb.instance)

		const timeout = orb:Timeout()
		if timeout > 0 then activationLife:delay(timeout, activationLife:wrapDestroy()) end

		-- const function onDismount(launch: boolean)
		-- 	if activationLife.alive then activationLife:destroy() end
		-- 	if launch then orb:launch(toucher) end
		-- end

		-- activation.bindActivation {
		-- 	attributes = self.Dismount,
		-- 	instanceLife = activationLife,
		-- 	instance = orb.instance,
		-- 	instanceConfiguration = orb.instanceConfiguration,
		-- 	onActivate = function()
		-- 		onDismount(true)
		-- 	end,
		-- }
	end

	local mountLife = orb.life:extend()
	self.Mode:onBind(orb, function(mode: typeof(self.Mode:type()))
		if mode == "Launch" then return end

		mountLife:destroy()
		mountLife = orb.life:extend()

		activation.bindActivation {
			attributes = self.Mount,
			instanceLife = mountLife,
			instance = orb.instance,
			instanceConfiguration = orb.instanceConfiguration,
			onActivate = onMount,
		}
	end)
end

function Orb.onActivate(self: OrbSelf, orb: OrbMechanic, level: std.Level, event: activation.ActivationEvent)
	if orb:Debounced() then return end
	orb:Debounced(true)

	const toucher = mounts.castToucher(event.kind == "Touch" and event.toucher or character.getMaybeCharacter())
	if not toucher then return end

	const mode = orb:Mode()
	if mode == "Launch" then
		orb:launch(toucher)
		return
	end
end

return Orb
