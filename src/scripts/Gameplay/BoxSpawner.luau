local Button = require("./Button")
local std = require("@libs/std")

local BoxSpawner = std.Mechanic({})
export type BoxSpawnerMechanic = std.Mechanic<typeof(BoxSpawner)>
BoxSpawner.instanceTag = "BoxSpawner"
BoxSpawner.instanceType = std.isA.Instance()
BoxSpawner.debuggerEmoji = "📦"

BoxSpawner.Button = Button.useAttributes(BoxSpawner)

return BoxSpawner
