local gt = require("@libs/gt")
local std = require("@libs/std")

local Template = std.Mechanic("Template", gt.Instance()) {}

export type Self = typeof(Template)
export type Mechanic = std.Mechanic<Self>

return Template
