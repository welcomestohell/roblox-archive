local ids = require("@libs/ids")
local std = require("@libs/std")

local Box = std.Mechanic({})
export type BoxMechanic = std.Mechanic<typeof(Box)>
Box.instanceTag = "Box"
Box.instanceType = std.gt.union2(std.isA.BasePart(), std.isA.Model())
Box.debuggerEmoji = "🎁"

Box.Id = ids.withAttribute(Box)
Box.boxesById = std.LevelState({} :: ids.MechanicsById<BoxMechanic>)

function Box:onStart(box: BoxMechanic, level: std.Level)
	ids.trackMechanic(level, box, box.boxesById)
end

return Box
