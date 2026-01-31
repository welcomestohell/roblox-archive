local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Attribute = require(ReplicatedStorage.Libs.Attribute)
local Mechanic = require(ReplicatedStorage.Libs.Mechanic)
local gt = require(ReplicatedStorage.Packages.gt)

local Conveyor = Mechanic.new("Conveyor", gt.isA.BasePart())({
	Speed = Attribute.new("Speed", gt.number({ limits = { range = { min = 0 } } }), 0),
	SynchronizeBeams = Attribute.new("SynchronizeBeams", gt.boolean(), false),

	onInit = function(self: any, level: Mechanic.Level)
		level.life:add(RunService.PreSimulation:Connect(function()
			for _, conveyor: Self in level.mechanicsByImplementations[self] do
				local speed: number = conveyor:Enabled() and conveyor:Speed() or 0
				conveyor.instance.AssemblyLinearVelocity = conveyor.instance.CFrame.LookVector * speed

				if conveyor:SynchronizeBeams() then
					for _, beam in conveyor.instance:GetDescendants() :: { Beam } do
						if beam.Name == "ConveyorBeam" and beam.ClassName == "Beam" then
							beam.TextureSpeed = speed / beam.TextureLength
						end
					end
				end
			end
		end))
	end,
})

export type Self = Mechanic.Mechanic<typeof(Conveyor)>
return Conveyor
