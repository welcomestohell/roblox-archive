-- Sorry miantoz1980

local std = require("@libs/std")

local Oppenheimer = std.Mechanic({})
export type OppenheimerMechanic = std.Mechanic<typeof(Oppenheimer)>
Oppenheimer.instanceTag = "Oppenheimer"
Oppenheimer.instanceType = std.isA.BasePart()
Oppenheimer.debuggerEmoji = "☢️"

Oppenheimer.Enabled = Oppenheimer:withEnabled()

function Oppenheimer.crashRoblox() end

return Oppenheimer
