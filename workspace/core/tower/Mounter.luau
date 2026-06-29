const activation = require "@libs/activation"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const Level = require "@libs/core/Level"
const emission = require "@libs/emission"
const mounts = require "@libs/mounts"
const std = require "@libs/std"

const Mounter = std.Mechanic {
	emoji = "🔌",
	name = "Mounter",
	description = "When activated, mounts itself onto the activator.",
	instanceType = std.gt.instanceTree {
		Activator = std.isA.BasePart(),
		AlignOrientation = std.gt.optional(std.isA.AlignOrientation()),
		AlignPosition = std.gt.optional(std.isA.AlignPosition()),
		Mount = std.gt.union(std.isA.Model(), std.isA.BasePart()),
	},

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 1),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Debounced = std.Attribute("Active", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Dismount",
	Dismount = activation.useAttributes "Dismount",

	std.AttributeSection "Emission",
	EmitMountedTag = std.Attribute("EmitMountedTag", std.gt.tag, "Mounter: On Mounted"),
	EmitDismountedTag = std.Attribute("EmitMountedTag", std.gt.tag, "Mounter: On Dismounted"),

	std.AttributeSection "Mount",
	MountMode = std.Attribute("MountMode", std.gt.literals { "Align", "Weld" }, "Weld"),
	MountName = std.Attribute("MountName", std.gt.string(), "Mounter"),
	MountOffset = std.Attribute("MountOffset", std.gt.CFrame(), CFrame.new(0, 0, -5)),
	MountLimb = std.Attribute("MountLimb", std.gt.enumOf(Enum.Limb), Enum.Limb.Torso),
	Massless = std.Attribute("Massless", std.gt.boolean(), true),
	RemoveAfter = std.Attribute("RemoveAfter", std.gt.positiveNumber, 0),
}

export type Mounter = typeof(Mounter)
export type MounterMechanic = std.Mechanic<Mounter, { mount: Model | BasePart }>

function Mounter:getActivationInstances(mounter: MounterMechanic)
	return mounter.instance.Activator
end

function Mounter:onStart(mounter: MounterMechanic)
	-- Mounter is already loaded by the time this is called. We add the tag
	-- here so spawned mounts don't automatically load until we're done
	-- intializing them.
	mounter.instance:AddTag(Level.DO_NOT_LOAD_TAG)

	mounter.mount = mounter.instance.Mount
	mounter.mount.Parent = nil

	if not mounter.instance:FindFirstChild "AlignOrientation" then
		const alignOrientation = Instance.new "AlignOrientation"
		alignOrientation.AlignType = Enum.AlignType.Parallel
		alignOrientation.MaxAngularVelocity = math.huge
		alignOrientation.Responsiveness = 200
		alignOrientation.Parent = mounter.instance
	end

	if not mounter.instance:FindFirstChild "AlignPosition" then
		const alignPosition = Instance.new "AlignPosition"
		alignPosition.MaxForce = math.huge
		alignPosition.Responsiveness = 200
		alignPosition.Parent = mounter.instance
	end

	self.Massless:onBind(mounter, function(massless)
		if massless then
			if mounter.mount:IsA "BasePart" then mounter.mount.Massless = true end
			for _, descendant in mounter.mount:GetDescendants() do
				if descendant:IsA "BasePart" then descendant.Massless = true end
			end
		end
	end)
end

function Mounter.onActivate(
	self: Mounter,
	mounter: MounterMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	const toucher = if event.kind == "Touch" and not character.isFromCharacter(event.toucher)
		then event.toucher
		else character.getMaybeHumanoidRootPart()

	if not toucher then return end

	const mountName = mounter:MountName()
	if mounts.isMounted(toucher, mountName) then return end

	const wasActivatable = self.Activation.Enabled(mounter)
	self.Activation.Enabled(mounter, false)
	mounter:Active(true)
	mounter:Debounced(true)

	local target = toucher
	if character.isFromCharacter(toucher) then
		const limbName = character.LIMB_MAP[mounter:MountLimb()]
		if limbName then
			const limb = character.getCharacter():FindFirstChild(limbName)
			if limb and limb:IsA "BasePart" then target = limb end
		end
	end

	-- We extend level's life instead of mounter, so we can support
	-- RemoveAfter like EToH.
	const mountLife = level.life:extend()
	const mount = mountLife:add(mounter.mount:Clone())
	mount.Name ..= " (Active)"
	mountLife:destroyOn(mount.Destroying)

	const primary = if mount:IsA "Model" then mount.PrimaryPart else mount
	if not primary then
		mount:Destroy()
		return
	end

	const activationLife = mounter.life:extend()
	activationLife:destroyOn(mounts.mount(toucher, mounter.instance, mountName))

	const mode = mounter:MountMode()
	if mode == "Weld" then
		mount:PivotTo(target.CFrame * mounter:MountOffset())
		constraints.weld(mountLife, primary, target)
	elseif mode == "Align" then
		const bodyAttachment = mountLife:add(Instance.new "Attachment")
		bodyAttachment.CFrame = mounter:MountOffset()
		bodyAttachment.Name = "MounterBody"
		bodyAttachment.Parent = target

		const primaryAttachment = mountLife:add(Instance.new "Attachment")
		primaryAttachment.Name = "MounterPrimary"
		primaryAttachment.Parent = primary

		-- stylua: ignore
		const alignOrientation = mountLife:add(Instance.fromExisting(mounter.instance.AlignOrientation :: AlignOrientation))
		const alignPosition = mountLife:add(Instance.fromExisting(mounter.instance.AlignPosition :: AlignPosition))

		alignOrientation.Attachment0 = primaryAttachment
		alignOrientation.Attachment1 = bodyAttachment
		alignOrientation.Parent = primary

		alignPosition.Attachment0 = primaryAttachment
		alignPosition.Attachment1 = bodyAttachment
		alignPosition.Parent = primary

		mount:PivotTo(bodyAttachment.WorldCFrame)
	end

	primary.Anchored = false
	mount.Parent = mounter.instance
	level:loadDescendantInstancesAsync(mount)

	emission.emitTaggedDescendants(mount, mounter:EmitMountedTag())

	activationLife:add(function()
		mounter:Active(false)
		mounter.life:delay(mounter:RemoveAfter(), mountLife:wrapDestroy())
		mounter.life:delay(
			mounter:Cooldown(),
			function(mounter: typeof(mounter), wasActivatable: typeof(wasActivatable))
				mounter.Activation.Enabled(mounter, wasActivatable)
				mounter:Debounced(false)
			end,
			mounter,
			wasActivatable
		)

		mounts.dismount(toucher, mounter.instance)
		emission.emitTaggedDescendants(mount, mounter:EmitDismountedTag())
	end)

	activation.bindActivation {
		attributes = self.Dismount,
		instanceLife = activationLife,
		instance = mounter.instance,
		instanceConfiguration = mounter.instanceConfiguration,
		onActivate = activationLife:wrapDestroy(),
	}
end

return Mounter
