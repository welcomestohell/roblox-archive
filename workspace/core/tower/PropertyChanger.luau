const logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const functions = require "@libs/primitives/functions"
const std = require "@libs/std"
const tweens = require "@libs/tweens"
const Result = require "@libs/Result"
const character = require "@libs/character"
const instances = require "@libs/instances"

const PropertyChanger = std.Mechanic {
	name = "PropertyChanger",
	description = "When activated, tweens it's target properties to it's set attributes.",
	instanceType = std.gt.instanceTree { Target = std.gt.optional(std.isA.ObjectValue()) },

	Target = std.Attribute(
		"Target",
		std.gt.literals {
			"Activator",
			"Character",
			"Group",
			"LevelMechanics",
			"Pointer",
			"Self",
		},
		"Self" :: "Self"
	),
	Group = std.Attribute("Group", std.gt.group, ""),
	QueryDescendants = std.Attribute("QueryDescendants", std.gt.string(), ""),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
	Cooldown = std.Attribute("Cooldown", std.gt.number(), 1),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),

	std.AttributeSection "Properties",
	Property = std.AttributeMap("Property", std.gt.unknown(), nil),
	Attribute = std.AttributeMap("Attribute", std.gt.unknown(), nil),
	NilProperty = std.AttributeMap("NilProperty", std.gt.boolean(), true),
	NilAttribute = std.AttributeMap("NilAttribute", std.gt.boolean(), true),

	std.AttributeSection "Tween",
	Tween = tweens.useAttributes(),
}

export type PropertyChangerSelf = typeof(PropertyChanger)
export type PropertyChangerMechanic = std.Mechanic<PropertyChangerSelf>

function PropertyChanger.getPointer(changer: PropertyChangerMechanic): Result.Result<{ Instance }, string>
	const target = changer.instance:FindFirstChild "Target" :: ObjectValue
	return target and target.Value and Result.Ok { target.Value } or Result.Err(`Missing "Target" ObjectValue`)
end

function PropertyChanger.getActivationTarget(changer: PropertyChangerMechanic, event: activation.ActivationEvent)
	return if event.kind == "Touch"
		then Result.Ok(event.toucher)
		elseif event.kind == "Click" or event.kind == "Prompt" or event.kind == "Died" then Result.Ok(
			character.getCharacter()
		)
		else Result.Err "Unsupported ActivationMode"
end

function PropertyChanger.getTarget(
	changer: PropertyChangerMechanic,
	level: std.Level,
	event: activation.ActivationEvent
): Result.Result<{ Instance }, string>
	const target = changer:Target()
	-- stylua: ignore
	return
		if target == "Activator" and event then changer:getActivationTarget(event)
		elseif target == "Character" then Result.Ok(character.getCharacter())
		elseif target == "Group" then Result.Ok(level:getGroupedInstances(changer:Group()))
		elseif target == "LevelMechanics" then Result.Ok { level.instance.Mechanics }
		elseif target == "Pointer" then changer:getPointer()
		elseif target == "Self" then Result.Ok { changer.instance }
		else functions.never(target)
end

function PropertyChanger.onActivate(
	self: PropertyChangerSelf,
	changer: PropertyChangerMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	if changer:Active() or changer:Debounced() then return end
	changer:Debounced(true)

	self.Activation.Enabled(false)
	changer.life:delay(changer:Cooldown(), function(changer: PropertyChangerMechanic)
		changer.Activation.Enabled(false)
		changer:Debounced(false)
	end, changer)

	const targetResult = changer:getTarget(level, event)
	if targetResult:isErr() then
		logger:Error("Failed to get target instances:", targetResult:unwrapErr())
		return
	end

	changer:Active(true)
	-- TODO: better error handling, im lazy rn
	for _, instance in targetResult:unwrap() :: { Instance } do
		tweens.playFromAttributes(instance, self.Property:getAll(changer), self.Tween)

		for property, setNil in self.NilProperty:getAll(changer) do
			if setNil then instances.setUnsafe(instance, property, nil) end
		end

		for attribute, value in self.Attribute:getAll(changer) do
			instance:SetAttribute(attribute, value)
		end

		for attribute, setNil in self.NilAttribute:getAll(changer) do
			if setNil then instance:SetAttribute(attribute, nil) end
		end
	end

	task.wait(self.Tween.Duration(changer))
	changer:Active(false)
end

return PropertyChanger
