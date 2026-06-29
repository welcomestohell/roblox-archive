const RunService = game:GetService "RunService"

const activation = require "@libs/activation"
const arrays = require "@libs/primitives/arrays"
const std = require "@libs/std"

const Contraption = std.Mechanic {
	name = "Contraption",
	description = "When activated, activate the grouped mechanics sequentially across it's front.",
	instanceType = std.isA.BasePart(),
	emoji = "⚙️",

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	RunAtStart = std.Attribute("RunAtStart", std.gt.boolean(), false),
	Visualize = std.Attribute("Visualize", std.gt.boolean(), RunService:IsStudio()),
	Speed = std.Attribute("Speed", std.gt.number(), 1),

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),

	std.AttributeSection "Group",
	Group = std.Attribute("Group", std.gt.group, ""),
	OptimizeGroupedInstances = std.Attribute("OptimizeGroupedInstances", std.gt.boolean(), true),

	std.AttributeSection "Loop",
	LoopAmount = std.Attribute("LoopAmount", std.gt.number(), 0),
	LoopDelay = std.Attribute("LoopDelay", std.gt.number(), 0),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type ContraptionModule = typeof(Contraption)
export type ContraptionMechanic = std.Mechanic<ContraptionModule, {
	mechanics: { std.Mechanic },
}>

function Contraption.onStart(self: ContraptionModule, contraption: ContraptionMechanic, level: std.Level)
	contraption.mechanics = {}

	for _, instance in level:getGroupedInstances(contraption:Group()) do
		const mechanics = level.mechanicsByInstance[instance]
		if not mechanics then continue end
		contraption.mechanics = arrays.concatenated<<std.Mechanic>>(contraption.mechanics, mechanics)
	end

	print("Contraption got", contraption.mechanics)

	if contraption:RunAtStart() then self:onActivate(contraption) end
end

function Contraption.onActivate(self: ContraptionModule, contraption: ContraptionMechanic) end

return Contraption
