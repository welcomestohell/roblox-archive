local std = require("@libs/std")

local Turret = std.Mechanic({})
export type TM_FILENAME_BASEMechanic = std.Mechanic<typeof(Turret)>

Turret.instanceTag = "Turret"
Turret.instanceType = std.isA.Instance()
Turret.debuggerEmoji = "🔫"

return Turret
