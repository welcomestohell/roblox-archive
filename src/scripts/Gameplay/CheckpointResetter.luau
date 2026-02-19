local std = require("@libs/std")

local CheckpointResetter = std.Mechanic({})
export type CheckpointResetterMechanic = std.Mechanic<typeof(CheckpointResetter)>
CheckpointResetter.instanceTag = "CheckpointResetter"
CheckpointResetter.instanceType = std.isA.BasePart()
CheckpointResetter.debuggerEmoji = "💠"

return CheckpointResetter
