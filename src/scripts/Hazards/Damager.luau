local std = require("@libs/std")

local Damager = std.Mechanic("Damager", std.gt.isA.BasePart())({
	onStart = function(self: Mechanic) end,
})

export type Self = typeof(Damager)
export type Mechanic = std.Mechanic<Self>
return Damager
