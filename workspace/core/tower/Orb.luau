local activation = require "@libs/activation"
local character = require "@libs/character"
local constraints = require "@libs/constraints"
local emission = require "@libs/emission"
local mounts = require "@libs/mounts"
local std = require "@libs/std"

local Orb = std.Mechanic {
	name = "Orb",
	description = "",
	instanceType = std.isA.BasePart(),

	Mount = std.Attribute("Mount", std.gt.boolean(), false),
	Force = std.Attribute("Force", std.gt.positiveNumber, 0),
	Timeout = std.Attribute("Timeout", std.gt.number(), 0),

	std.AttributeSection "Pivot",
	XRotationEnabled = std.Attribute("XRotationEnabled", std.gt.boolean(), true),
	YRotationEnabled = std.Attribute("YRotationEnabled", std.gt.boolean(), true),
	ZRotationEnabled = std.Attribute("ZRotationEnabled", std.gt.boolean(), true),

	std.AttributeSection "Tags",
	EmitMountedTag = std.Attribute("EmitMountedTag", std.gt.tag, "Orb: On Mounted"),
	EmitLaunchedTag = std.Attribute("EmitLaunchedTag", std.gt.tag, "Orb: On Launched"),
	EmitTimedOutTag = std.Attribute("EmitTimedOutTag", std.gt.tag, "Orb: On Timed Out"),

	std.AttributeSection "Activation",
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Activation = activation.useAttributes(),

	std.AttributeSection "Dismount",
	Dismount = activation.useAttributes "Dismount",
}

export type OrbSelf = typeof(Orb)
export type OrbMechanic = std.Mechanic<OrbSelf>

function Orb.launch(orb: OrbMechanic, toucher: BasePart)
	local lookVector = orb.instance.CFrame.LookVector

	local maxForce = if math.abs(lookVector.X) < 0.1 and math.abs(lookVector.Z) < 0.1
		then Vector3.yAxis * 40000
		else Vector3.one * 40000

	local launchLife = orb.life:extend()

	local velocityAttachment = launchLife:add(Instance.new "Attachment")
	local linearVelocity = launchLife:add(Instance.new "LinearVelocity")
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
	if orb:Debounced() or orb:Active() then return end

	local raw = event.kind == "Touch" and event.toucher or character.getMaybeCharacter()

	local toucher = mounts.castToucher(raw)
	if not toucher then return end

	if orb:Mount() then
		if mounts.isMechanicMounted(toucher, orb) then return end
		orb.Activation.Enabled(orb, false)
		orb:Active(true)
		orb:Debounced(true)

		local activationLife = orb.life:extend()
		activationLife:destroyOn(mounts.mountMechanic(toucher, orb))
		toucher:PivotTo(orb.instance.CFrame)
		constraints.weld(activationLife, toucher, orb.instance)
		emission.emitTaggedDescendants(orb.instance, orb:EmitMountedTag())

		local function onDismount(launch: boolean)
			if activationLife.alive then
				if launch then orb:launch(toucher) end
				emission.emitTaggedDescendants(orb.instance, launch and orb:EmitLaunchedTag() or orb:EmitTimedOutTag())
			end

			orb:Active(false)
			orb.life:delay(orb:Cooldown(), self.reactivate, orb)
			mounts.dismountMechanic(toucher, orb)
			activationLife:destroy()
		end

		local timeout = orb:Timeout()
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
	else
		orb.Activation.Enabled(orb, false)
		orb:Debounced(true)
		orb.life:delay(orb:Cooldown(), self.reactivate, orb)
		orb:launch(toucher)
		emission.emitTaggedDescendants(orb.instance, orb:EmitLaunchedTag())
	end
end

return Orb
