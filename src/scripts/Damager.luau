local ReplicatedStorage = game:GetService "ReplicatedStorage"

local lib = require(ReplicatedStorage.Lib)

local Damager = lib.Mechanic("Damager", lib.isA.BasePart()) {
	onActivated = function(self: Self) end,
}

export type Self = lib.Mechanic<typeof(Damager)>
return Damager
