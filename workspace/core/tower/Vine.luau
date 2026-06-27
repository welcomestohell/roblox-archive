const activation = require "@libs/activation"
const character = require "@libs/character"
const constraints = require "@libs/constraints"
const emission = require "@libs/emission"
const mounts = require "@libs/mounts"
const std = require "@libs/std"
const tweens = require "@libs/tweens"

const Vine = std.Mechanic {
	emoji = "🪝",
	name = "Vine",
	description = "When activated, attaches the player or a Box to itself using a given Constraint.",
	instanceType = std.gt.instanceTree {
		Activator = std.isA.BasePart(),
		Constraint = std.isA.Constraint(),
		Base = std.gt.instanceTree(std.isA.BasePart(), {
			BaseAttachment = std.isA.Attachment(),
		}),
		Handle = std.gt.instanceTree(std.isA.BasePart(), {
			HandleAttachment = std.isA.Attachment(),
		}),
	},

	-- TODO: implement animations
	Animated = std.Attribute("Animated", std.gt.boolean(), true),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	HideHandle = std.Attribute("HideHandle", std.gt.boolean(), false),
	JumpOnDismount = std.Attribute("JumpOnDismount", std.gt.boolean(), true),
	KeepMomentum = std.Attribute("KeepMomentum", std.gt.boolean(), true),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Deactivation",
	Deactivation = activation.useAttributes "Deactivation",

	std.AttributeSection "Tags",
	EmitActivatedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Vine: On Activated"),
	EmitDeactivatedTag = std.Attribute("EmitDeactivatedTag", std.gt.tag, "Vine: On Deactivated"),
	EmitJumpedTag = std.Attribute("EmitJumpTag", std.gt.tag, "Vine: On Jumped"),
	EmitRefreshedTag = std.Attribute("EmitRefreshedTag", std.gt.tag, "Vine: On Refreshed"),

	std.AttributeSection "Activator",
	ActivatorTween = tweens.useAttributes "ActivatorTween",
	ActivatorTransparency = std.Attribute("ActivatorTransparency", std.gt.constrainNumber(0, 1), 0),
	ActivatorPosition = std.Attribute("ActivatorCFrame", std.gt.Vector3(), Vector3.zero),
	ActivatorSize = std.Attribute("ActivatorSize", std.gt.Vector3(), Vector3.zero),
}

export type VineMechanic = std.Mechanic<typeof(Vine), { handle: BasePart }>

function Vine.getActivationInstances(self: typeof(Vine), vine: VineMechanic)
	return vine.instance.Activator
end

function Vine.onStart(self: typeof(Vine), vine: VineMechanic)
	vine.handle = vine.instance.Handle
	vine.handle.Parent = nil
	self.ActivatorTransparency(vine, vine.instance.Activator.Transparency)
	self.ActivatorPosition(vine, vine.instance.Activator.Position)
	self.ActivatorSize(vine, vine.instance.Activator.Size)
end

function Vine.onActivate(self: typeof(Vine), vine: VineMechanic, level: std.Level, event: activation.ActivationEvent)
	const toucher = if event.kind == "Touch" and not character.isFromCharacter(event.toucher)
		then event.toucher
		else character.getCharacter().Head

	if mounts.isMechanicMounted(toucher, vine) then return end

	const wasActivatable = self.Activation.Enabled(vine)
	self.Activation.Enabled(vine, false)
	vine:Active(true)
	vine:Debounced(true)

	const activationLife = vine.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(toucher, vine))
	activationLife:destroyOn(toucher.Destroying)

	vine.instance.Activator.Transparency = 1
	vine.instance.Activator.Position = vine.instance.Base.Position
	vine.instance.Activator.Size = Vector3.zero

	const handle = activationLife:add(vine.handle:Clone())
	if vine:HideHandle() then
		handle.Size = Vector3.zero
		handle.Transparency = 1
	end
	handle.CFrame = toucher.CFrame + toucher.CFrame.UpVector * (toucher.Size.Y / 2)
	handle.Anchored = false
	handle.Parent = vine.instance
	constraints.weld(activationLife, handle, toucher)

	const constraint = activationLife:add(vine.instance.Constraint:Clone())
	constraint.Color = vine.instance.Activator.BrickColor
	constraint.Attachment0 = handle:FindFirstChild "HandleAttachment" :: Attachment
	constraint.Attachment1 = vine.instance.Base:FindFirstChild "BaseAttachment" :: Attachment
	constraint.Enabled = true
	constraint.Parent = handle

	emission.emitTaggedDescendants(vine.instance, vine:EmitActivatedTag())

	activationLife:add(function()
		vine:Active(false)
		mounts.dismountMechanic(toucher, vine)
		emission.emitTaggedDescendants(vine.instance, vine:EmitDeactivatedTag())

		if toucher and vine:KeepMomentum() == false then toucher.AssemblyLinearVelocity = Vector3.zero end
		if character.isFromCharacter(toucher) then
			const humanoid = character.getMaybeHumanoid()
			if humanoid then
				humanoid.PlatformStand = false
				if vine:JumpOnDismount() then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
				emission.emitTaggedDescendants(vine.instance, vine:EmitJumpedTag())
			end
		end

		vine.life:delay(vine:Cooldown(), function(vine: typeof(vine))
			vine.Activation.Enabled(vine, wasActivatable)
			vine:Debounced(false)

			emission.emitTaggedDescendants(vine.instance, vine:EmitRefreshedTag())
			tweens.playFromAttributes(vine.instance.Activator, {
				Transparency = vine:ActivatorTransparency(),
				Position = vine:ActivatorPosition(),
				Size = vine:ActivatorSize(),
			}, vine.ActivatorTween, vine.instanceConfiguration)
		end, vine)
	end)

	activation.bindActivation {
		instanceLife = activationLife,
		instance = vine.instance.Activator,
		instanceConfiguration = vine.instanceConfiguration,
		attributes = self.Deactivation,
		onActivate = activationLife:wrapDestroy(),
	}
end

return Vine
