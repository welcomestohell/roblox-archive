local activation = require("@libs/activation")
local std = require("@libs/std")
local tweens = require("@libs/tweens")

local Anchor = std.Mechanic({})
export type AnchorMechanic = std.Mechanic<typeof(Anchor)>
Anchor.instanceTag = "Anchor"
Anchor.instanceType = std.isA.BasePart()
Anchor.debuggerEmoji = "🔱"

Anchor.JumpOnDismount = Anchor:attribute("JumpOnDismount", std.gt.boolean(), true)

Anchor:attributeSection("Activation")
Anchor.Activation = activation.useAttributes(Anchor)

Anchor:attributeSection("Deactivation")
Anchor.Deactivation = activation.useAttributes(Anchor)

Anchor:attributeSection("Transition")
Anchor.Transition = tweens.useAttributes(Anchor)

function Anchor.onActivate(self: typeof(Anchor), mechanic: AnchorMechanic, level: std.Level) end

return Anchor
