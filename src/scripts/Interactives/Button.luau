local std = require("@libs/std")

local Damager = std.Mechanic("Damager", std.gt.isA.BasePart())({
	onStart = function(self: Self) end,
})

export type Self = std.Mechanic<typeof(Damager)>
return Damager
