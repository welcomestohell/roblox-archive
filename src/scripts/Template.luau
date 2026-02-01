local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")

local Template = Mechanic.new("Template", gt.Instance())({})

export type Self = Mechanic.Mechanic<typeof(Template)>
return Template
