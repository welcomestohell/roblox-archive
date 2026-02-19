local std = require("@libs/std")

local Checkpoint = std.Mechanic({})
export type CheckpointMechanic = std.Mechanic<typeof(Checkpoint)>
Checkpoint.instanceTag = "Checkpoint"
Checkpoint.instanceType = std.isA.BasePart()
Checkpoint.debuggerEmoji = "💠"

return Checkpoint
