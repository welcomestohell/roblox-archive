local std = require("@libs/std")

local Seat = std.Mechanic({})
export type SeatMechanic = std.Mechanic<typeof(Seat)>
Seat.instanceTag = "Seat"
Seat.instanceType = std.isA.BasePart()

return Seat
