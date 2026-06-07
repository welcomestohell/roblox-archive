local std = require "@libs/std"

local Breakable = std.Mechanic {}
export type BreakableMechanic = std.Mechanic<typeof(Breakable)>
Breakable.mechanicName = "Breakable"
Breakable.instanceType = std.isA.Instance()
Breakable.debuggerEmoji = "💥"

return Breakable
