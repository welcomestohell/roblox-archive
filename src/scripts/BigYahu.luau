local std = require("@libs/std")

local BigYahu = std.Mechanic({})
export type BigYahuMechanic = std.Mechanic<typeof(BigYahu)>
BigYahu.instanceTag = "BigYahu"
BigYahu.instanceType = std.isA.Instance()
BigYahu.debuggerEmoji = "🇮🇱"

return BigYahu
