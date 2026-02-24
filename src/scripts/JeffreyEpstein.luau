local std = require("@libs/std")

local JeffreyEpstein = std.Mechanic({})
export type JeffreyEpsteinMechanic = std.Mechanic<typeof(JeffreyEpstein)>
JeffreyEpstein.instanceTag = "JeffreyEpstein"
JeffreyEpstein.instanceType = std.isA.Instance()
JeffreyEpstein.debuggerEmoji = "👼"

return JeffreyEpstein
