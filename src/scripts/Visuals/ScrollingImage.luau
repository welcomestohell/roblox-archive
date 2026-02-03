local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")

local ScrollingImage = Mechanic.new("ScrollingImage", gt.isA.ImageLabel())({})

export type Self = Mechanic.Mechanic<typeof(ScrollingImage)>
return ScrollingImage
