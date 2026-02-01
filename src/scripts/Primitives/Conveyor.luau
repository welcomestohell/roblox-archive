local RunService = game:GetService("RunService")

local std = require("@libs/std")

local Conveyor = std.Mechanic("Conveyor", std.gt.isA.BasePart())({
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 0),
	SynchronizeBeams = std.Attribute("SynchronizeBeams", std.gt.boolean(), false),

	onInit = function(self: Self, level: std.Level)
		level.life:add(RunService.PreSimulation:Connect(function()
			local conveyors = level.mechanicsByImplementations[self]
			if conveyors then
				for _, conveyor: Self in conveyors do
					local speed: number = conveyor:Enabled() and conveyor:Speed() or 0
					conveyor.parent.AssemblyLinearVelocity = conveyor.parent.CFrame.LookVector * speed

					if conveyor:SynchronizeBeams() then
						for _, beam in conveyor.parent:GetDescendants() :: { Beam } do
							if beam.Name == "ConveyorBeam" and beam.ClassName == "Beam" then
								beam.TextureSpeed = speed / beam.TextureLength
							end
						end
					end
				end
			end
		end))
	end,
})

export type Self = std.Mechanic<typeof(Conveyor)>
return Conveyor
