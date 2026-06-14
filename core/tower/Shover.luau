local std = require "@libs/std"

local Shover = std.Mechanic {}
export type ShoverMechanic = std.Mechanic<typeof(Shover)>
Shover.name = "Shover"
Shover.instanceType = std.isA.PrismaticConstraint()
Shover.emoji = "🤜"

type ShoverDirection = "In" | "Out"
type ShoverDirectionAttributes = {
	delay: std.Attribute<number>,
	power: std.Attribute<number>,
}

Shover.Enabled = Shover:attribute("Enabled", std.gt.boolean(), true)

Shover.directions = {} :: { [ShoverDirection]: ShoverDirectionAttributes }

Shover:attributeSection "In"
Shover.directions.In = {
	delay = Shover:attribute("InDelay", std.gt.positiveNumber, 1),
	power = Shover:attribute("InPower", std.gt.positiveNumber, 0),
}

Shover:attributeSection "Out"
Shover.directions.Out = {
	delay = Shover:attribute("OutDelay", std.gt.positiveNumber, 1),
	power = Shover:attribute("OutPower", std.gt.positiveNumber, 0),
}

function Shover.shove(shover: ShoverMechanic, direction: ShoverDirection)
	local attributes: ShoverDirectionAttributes = Shover.directions[direction]

	task.wait(attributes.delay(shover))

	if shover:Enabled() then
		local power = attributes.power(shover)
		local constraint = shover.instance
		constraint.LinearResponsiveness = power
		constraint.Speed = power
		constraint.TargetPosition = if direction == "Out" then shover.instance.UpperLimit else 0
	end
end

function Shover:onStart(shover: ShoverMechanic, level: std.Level)
	repeat
		shover:shove "In"
		shover:shove "Out"
	until shover.life.destroyed
end

return Shover
