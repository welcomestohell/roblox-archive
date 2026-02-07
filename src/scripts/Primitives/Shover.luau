local std = require("@libs/std")

local Shover = std.Mechanic({})
export type ShoverMechanic = std.Mechanic<typeof(Shover)>
Shover.instanceTag = "Shover"
Shover.instanceType = std.isA.BasePart()

type ShoverDirection = "In" | "Out"
type ShoverDirectionAttributes = {
	delay: std.Attribute<number>,
	power: std.Attribute<number>,
}

Shover.threads = std.LevelState({} :: any)
Shover.directions = {} :: { [ShoverDirection]: ShoverDirectionAttributes }

Shover:attributeSection("In")
Shover.directions.In = {
	delay = Shover:attribute("InDelay", std.gt.positiveNumber, 1),
	power = Shover:attribute("InPower", std.gt.positiveNumber, 0),
}

Shover:attributeSection("Out")
Shover.directions.Out = {
	delay = std.Attribute("OutDelay", std.gt.positiveNumber, 1),
	power = std.Attribute("OutPower", std.gt.positiveNumber, 0),
}

local function shove(direction: ShoverDirection, shover: ShoverMechanic)
	local attributes: ShoverDirectionAttributes = Shover.directions[direction]

	task.wait(attributes.delay(shover))

	if shover:Enabled() then
		local power = attributes.power(shover)
		for _, descendant in pairs(shover.instance:GetDescendants()) do
			if descendant.Name == "ShoverConstraint" and descendant:IsA("PrismaticConstraint") then
				descendant.LinearResponsiveness = power
				descendant.Speed = power
				descendant.TargetPosition = if direction == "Out" then descendant.UpperLimit else 0
			end
		end
	end
end

function Shover:onPreSimulation(_, level: std.Level)
	local threads = Shover.threads:getOrSet(level, {})
	for _, shover: ShoverMechanic in level:getMechanics(Shover) do
		if not threads[shover] then
			threads[shover] = level.life:add(task.spawn(function()
				while self:Enabled() do
					shove("In", shover)
					shove("Out", shover)
				end
			end))
		end
	end
end

return Shover
