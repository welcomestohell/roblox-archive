const activation = require "@libs/activation"
const character = require "@libs/character"
const std = require "@libs/std"

const Destroyer = std.Mechanic {
	emoji = "🚫",
	name = "Destroyer",
	description = "When activated, destroys the activator.",
	instanceType = std.isA.Instance(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	TargetTag = std.Attribute("TargetTag", std.gt.optional(std.gt.tag), nil),
	TargetCharacterByDefault = std.Attribute("TargetCharacterByDefault", std.gt.boolean(), false),
	TargetWholeModel = std.Attribute("TargetWholeModel", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type DestroyerModule = typeof(Destroyer)
export type DestroyerMechanic = std.Mechanic<DestroyerModule>

function Destroyer.onActivate(self: DestroyerModule, destroyer: DestroyerMechanic, _, event: activation.ActivationEvent)
	if destroyer:Debounced() then return end

	local target: Instance? = if event.kind == "Touch"
		then event.toucher
		elseif event.kind == "Activator" then event.mechanic.instance
		elseif
			self:TargetCharacterByDefault()
			or event.kind == "Click"
			or event.kind == "Died"
			or event.kind == "Jump"
			or event.kind == "HumanoidStateChanged"
		then character.getHumanoidRootPart()
		else nil

	if not target then return end
	if destroyer:TargetWholeModel() then
		target = target:FindFirstAncestor "Box"
			or target:FindFirstAncestor "Bullet"
			or character.isFromCharacter(target) and character.getCharacter()
			or target
	end

	const targetTag = destroyer:TargetTag()
	if targetTag and not target:HasTag(targetTag) then return end

	const wasActivatable = self.Activation.Enabled(destroyer)
	destroyer.Activation.Enabled(destroyer, false)
	destroyer:Debounced(true)

	destroyer.life:delay(destroyer:Cooldown(), function(destroyer: DestroyerMechanic)
		destroyer.Activation.Enabled(destroyer, wasActivatable)
		destroyer:Debounced(false)
	end, destroyer)

	target:Destroy()
end

return Destroyer
