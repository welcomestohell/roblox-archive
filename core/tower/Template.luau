const std = require "@libs/std"

const Template = std.Mechanic {}
export type TemplateMechanic = std.Mechanic<typeof(Template)>
Template.name = "Template"
Template.instanceType = std.isA.BasePart()
Template.emoji = "💠"

function Template.onStart(self: typeof(Template), mechanic: TemplateMechanic, level: std.Level) end

return Template
