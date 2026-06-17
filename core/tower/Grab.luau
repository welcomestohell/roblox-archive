const std = require "@libs/std"
const chr = require "@libs/character"

const Grab = std.Mechanic {
	emoji = "🪨 ",
	name = "Grab",
	description = "Description",
	instanceType = std.isA.BasePart(),

	Active = std.Attribute("Active", std.gt.boolean(), true),
}

local function updPlrPos(grabCFrame: CFrame) end

function Grab.onStart(self: typeof(Grab), grabPart: GrabMechanic, level: std.Level) end

export type GrabMechanic = std.Mechanic<typeof(Grab)>

return Grab
