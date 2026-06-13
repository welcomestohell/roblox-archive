const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const character = require "@libs/character"
const emission = require "@libs/emission"
const std = require "@libs/std"

const Launcher = std.Mechanic {}
export type LauncherMechanic = std.Mechanic<typeof(Launcher)>
Launcher.mechanicName = "Launcher"
Launcher.instanceType = std.isA.BasePart()
Launcher.debuggerEmoji = "🦘"

Launcher.Cooldown = Launcher:attribute("Cooldown", std.gt.positiveNumber, 0)
Launcher.Power = Launcher:attribute("Power", std.gt.positiveNumber, 100)
Launcher.RelativeForce = Launcher:attribute("RelativeForce", std.gt.boolean(), false)
Launcher.ForceFreefall = Launcher:attribute("ForceFreefall", std.gt.boolean(), true)
Launcher.EmitLaunchTag = Launcher:attribute("EmitLaunchTag", std.gt.string(), "Launcher: On Launch")
Launcher.Activation = activation.useAttributes(Launcher)

function Launcher.onActivate(
	self: typeof(Launcher),
	launcher: LauncherMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	self.Activation.Enabled(launcher, false)
	launcher.life:delay(launcher:Cooldown(), Attribute.set :: any, self.Activation.Enabled, launcher, true)

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
end

return Launcher
