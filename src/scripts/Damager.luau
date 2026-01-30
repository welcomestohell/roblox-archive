local ReplicatedStorage = game:GetService "ReplicatedStorage"

local lib = require(ReplicatedStorage.Lib)

local Damager = lib.Mechanic("Damager", lib.isA.BasePart()) {
	onStart = function(self: Self)
		print("GOT MECHANIC", self.instance, "WITH ID", self.id)
	end,
}

export type Self = lib.Mechanic<typeof(Damager)>
return Damager
