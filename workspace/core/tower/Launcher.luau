const activation = require "@libs/activation"
const character = require "@libs/character"
const emission = require "@libs/emission"
const std = require "@libs/std"

const Launcher = std.Mechanic {
	emoji = "🦘",
	name = "Launcher",
	description = "When activated, launches the activator upwards.",
	instanceType = std.isA.BasePart(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	Power = std.Attribute("Power", std.gt.positiveNumber, 100),
	RelativeForce = std.Attribute("RelativeForce", std.gt.boolean(), false),
	ForceFreefall = std.Attribute("ForceFreefall", std.gt.boolean(), true),
	EmitLaunchTag = std.Attribute("EmitLaunchTag", std.gt.tag, "Launcher: On Launch"),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type LauncherMechanic = std.Mechanic<typeof(Launcher)>

function Launcher.onActivate(
	self: typeof(Launcher),
	launcher: LauncherMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	const wasActivatable = self.Activation.Enabled(launcher)
	self.Activation.Enabled(launcher, false)
	launcher:Debounced(true)

	local target = event.kind == "Touch" and event.toucher or character:getMaybeHumanoidRootPart()
	if not target then return end
	if character.isFromMaybeCharacter(target) and launcher:ForceFreefall() then
		const humanoid = character.getMaybeHumanoid()
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
	end

	target.AssemblyLinearVelocity = if launcher:RelativeForce()
		then -launcher.instance.CFrame.RightVector * launcher:Power()
		else Vector3.new(target.AssemblyLinearVelocity.X, launcher:Power(), target.AssemblyLinearVelocity.Z)

	emission.emitTaggedDescendants(launcher.instance, launcher:EmitLaunchTag())

	task.wait(launcher:Cooldown())
	if launcher.life.alive then
		self.Activation.Enabled(launcher, wasActivatable)
		launcher:Debounced(false)
	end
end

return Launcher
