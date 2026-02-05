-- TODO: rescript this because this is ASS

local RunService = game:GetService("RunService")

local std = require("@libs/std")

type ShoverDirectionAttributes = {
	Delay: std.Attribute<number>,
	Power: std.Attribute<number>,
}

local SHOVER_DIRECTION_ATTRIBUTES = {
	In = {
		Delay = std.Attribute("InDelay", std.gt.positiveNumber, 1),
		Power = std.Attribute("InPower", std.gt.positiveNumber, 0),
	},

	Out = {
		Delay = std.Attribute("OutDelay", std.gt.positiveNumber, 1),
		Power = std.Attribute("OutPower", std.gt.positiveNumber, 0),
	},
}

local function shove(direction: "In" | "Out", shover: Mechanic)
	local attributes: ShoverDirectionAttributes = SHOVER_DIRECTION_ATTRIBUTES[direction]

	task.wait(attributes:Delay(shover))

	if shover:Enabled() then
		local power = attributes:Power(shover)
		for _, descendant in pairs(shover.instance:GetDescendants()) do
			if descendant.Name == "ShoverConstraint" and descendant:IsA("PrismaticConstraint") then
				descendant.LinearResponsiveness = power
				descendant.Speed = power
				descendant.TargetPosition = if direction == "Out" then descendant.UpperLimit else 0
			end
		end
	end
end

local Shover = std.Mechanic("Shover", std.gt.isA.BasePart())({
	onInit = function(self: Mechanic, level: std.Level)
		local cache = {} :: { Mechanic }

		level.life:add(RunService.PreSimulation:Connect(function()
			local shovers = level.mechanicsByImplementations[self.implementation]

			if shovers then
				for _, shover: Mechanic in shovers do
					if not table.find(cache, shover) then
						level.life:add(task.spawn(function()
							while self:Enabled() do
								shove("In", shover)
								shove("Out", shover)
							end
						end))

						table.insert(cache, shover)
					end
				end
			end
		end))
	end,
})

export type Self = typeof(Shover)
export type Mechanic = std.Mechanic<Self>
return Shover
