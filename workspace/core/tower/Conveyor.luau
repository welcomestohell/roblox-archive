local std = require "@libs/std"

local Conveyor = std.Mechanic {
	emoji = "🛣️",
	name = "Conveyor",
	description = "Moves objects in the direction it's facing.",
	instanceType = std.isA.BasePart(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 0),
	SynchronizeBeams = std.Attribute("SynchronizeBeams", std.gt.boolean(), false),
	BeamTag = std.Attribute("BeamTag", std.gt.tag, "Conveyor: Beam"),
}

export type ConveyorMechanic = std.Mechanic<typeof(Conveyor)>

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
