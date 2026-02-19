local std = require("@libs/std")

local Laser = std.Mechanic({})
export type LaserMechanic = std.Mechanic<typeof(Laser)>

Laser.instanceTag = "Laser"
Laser.instanceType = std.isA.Instance()
Laser.debuggerEmoji = "🔦"

return Laser
