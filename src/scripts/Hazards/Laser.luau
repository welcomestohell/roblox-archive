local std = require("@libs/std")

local Laser = std.Mechanic({})
export type TM_FILENAME_BASEMechanic = std.Mechanic<typeof(Laser)>

Laser.instanceTag = "Laser"
Laser.instanceType = std.isA.Instance()
Laser.debuggerEmoji = "🔦"

return Laser
