local character = require("@libs/character")
local std = require("@libs/std")

local Wind = std.Mechanic({})
export type WindMechanic = std.Mechanic<typeof(Wind)>

Wind.instanceTag = "Wind"
Wind.debuggerEmoji = "🌪"
