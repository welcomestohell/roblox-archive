local std = require("@libs/std")

local CheckpointReturner = std.Mechanic({})
export type CheckpointReturnerMechanic = std.Mechanic<typeof(CheckpointReturner)>
CheckpointReturner.instanceTag = "CheckpointReturner"
CheckpointReturner.instanceType = std.isA.BasePart()
CheckpointReturner.debuggerEmoji = "💠"

-- Checkpoint:attribute("TransitionMode", type, default)

return CheckpointReturner
