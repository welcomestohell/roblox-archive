local Attribute = require("@libs/Attribute")
local Mechanic = require("@libs/Mechanic")
local gt = require("@libs/gt")

local Teleporter = Mechanic.new("Teleporter", gt.isA.BasePart())({
	Id = Attribute.new("Id", gt.string()),
	KeepVelocity = Attribute.new("KeepVelocity", gt.boolean(), true),
	Cooldown = Attribute.new("Cooldown", gt.number(), 0),
	PlaySound = Attribute.new("PlaySound", gt.boolean(), true),
	Seamless = Attribute.new("Seamless", gt.boolean(), true),
	SeamlessMeasurement = Attribute.new(
		"SeamlessMeasurement",
		gt.union2(gt.literal("Relative"), gt.literal("World")),
		"Relative"
	),
	Offset = Attribute.new("Offset", gt.CFrame()),
})

export type Self = Mechanic.Mechanic<typeof(Teleporter)>
return Teleporter
