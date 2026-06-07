local std = require "@libs/std"

local Carryable = std.Mechanic {}
export type CarryableMechanic = std.Mechanic<typeof(Carryable)>
Carryable.mechanicName = "Carryable"
Carryable.instanceType = std.isA.Instance()
Carryable.debuggerEmoji = "💠"

-- TODO: implement

return Carryable
