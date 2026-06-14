local std = require "@libs/std"

local Conveyor = std.Mechanic {}
export type ConveyorMechanic = std.Mechanic<typeof(Conveyor)>
Conveyor.name = "Conveyor"
Conveyor.instanceType = std.isA.BasePart()
Conveyor.emoji = "🛣️"

Conveyor.Enabled = Conveyor:attribute("Enabled", std.gt.boolean(), true)
Conveyor.Speed = Conveyor:attribute("Speed", std.gt.positiveNumber, 0)
Conveyor.SynchronizeBeams = Conveyor:attribute("SynchronizeBeams", std.gt.boolean(), false)
Conveyor.BeamTag = Conveyor:attribute("BeamTag", std.gt.string(), "Conveyor: Beam")

function Conveyor:onPreSimulation(deltaTime: number, level: std.Level)
	for _, conveyor: ConveyorMechanic in level:getMechanics(Conveyor) do
		local speed: number = conveyor:Enabled() and conveyor:Speed() or 0
		conveyor.instance.AssemblyLinearVelocity = conveyor.instance.CFrame.LookVector * speed

		if conveyor:SynchronizeBeams() then
			local beamTag = conveyor:BeamTag()
			for _, beam in conveyor.instance:GetDescendants() :: { Beam } do
				if beam:HasTag(beamTag) and beam.ClassName == "Beam" then
					beam.TextureSpeed = speed / beam.TextureLength
				end
			end
		end
	end
end

return Conveyor
