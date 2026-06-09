local std = require "@libs/std"

local Template = std.Mechanic {}
export type TemplateMechanic = std.Mechanic<typeof(Template)>
Template.mechanicName = "Template"
Template.instanceType = std.isA.BasePart()
Template.debuggerEmoji = "💠"

function Template.onStart(self: typeof(Template), mechanic: TemplateMechanic, level: std.Level) end

return Template
