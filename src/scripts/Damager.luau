local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mechanic = require(ReplicatedStorage.Libs.Mechanic)
local gt = require(ReplicatedStorage.Packages.gt)

local Damager = Mechanic.new("Damager", gt.isA.BasePart())({
	onStart = function(self: Self)
		print("GOT MECHANIC", self.instance, "WITH ID", self.id)
	end,
})

export type Self = Mechanic.Mechanic<typeof(Damager)>
return Damager
