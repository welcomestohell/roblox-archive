local std = require("@libs/std")

local Damager = std.Mechanic({})
export type DamagerMechanic = std.Mechanic<typeof(Damager)>

Damager.instanceTag = "Damager"
Damager.instanceType = std.isA.BasePart()
Damager.debuggerEmoji = "☠️"

return Damager
