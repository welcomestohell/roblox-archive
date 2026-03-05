local Button = require("./Button")
local std = require("@libs/std")

local BoxSpawner = std.Mechanic({})
export type BoxSpawnerMechanic = std.Mechanic<typeof(BoxSpawner)>
BoxSpawner.instanceTag = "BoxSpawner"
BoxSpawner.instanceType = std.gt.instanceTree({
	Button = std.isA.BasePart(),
	Box = std.gt.union2(std.isA.BasePart(), std.isA.Model()),
})
BoxSpawner.debuggerEmoji = "📦"

BoxSpawner.Button = Button.useAttributes(BoxSpawner)

function BoxSpawner.onActivate() end

return BoxSpawner
