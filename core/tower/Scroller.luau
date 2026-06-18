const std = require "@libs/std"

const Scroller = std.Mechanic {
	emoji = "❔",
	name = "Scroller",
	description = "Hello, Welcome To Hell!",
	instanceType = std.isA.Texture(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Speed = std.Attribute("Speed", std.gt.Vector2(), Vector2.zero),
	Offset = std.Attribute("Offset", std.gt.Vector2(), Vector2.zero),
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),
	LoopHorizontally = std.Attribute("LoopHorizontally", std.gt.boolean(), true),
	LoopVertically = std.Attribute("LoopVertically", std.gt.boolean(), true),
}

export type ScrollerMechanic = std.Mechanic<typeof(Scroller)>

function Scroller.onStart(self: typeof(Scroller), scroller: ScrollerMechanic, level: std.Level)
	local offset = self.Offset:peek(scroller)
	if offset then
		scroller.instance.OffsetStudsU = offset.X
		scroller.instance.OffsetStudsV = offset.Y
	else
		scroller:Offset(Vector2.new(scroller.instance.OffsetStudsU, scroller.instance.OffsetStudsV))
	end
end

function Scroller.onPreRender(self: typeof(Scroller), deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()

	for _, texture: ScrollerMechanic in level:getMechanics(self) do
		if not texture:Enabled() then continue end

		local speed = texture:Speed()
		local offset = texture:Offset()
		local newOffset = if texture:Synchronized()
			then offset + speed / Vector2.new(texture.instance.StudsPerTileU, texture.instance.StudsPerTileV) * lifetime
			else Vector2.new(texture.instance.OffsetStudsU, texture.instance.OffsetStudsV) + speed * deltaTime

		texture.instance.OffsetStudsU = if texture:LoopHorizontally()
			then newOffset.X % texture.instance.StudsPerTileU
			else newOffset.X

		texture.instance.OffsetStudsV = if texture:LoopVertically()
			then newOffset.Y % texture.instance.StudsPerTileV
			else newOffset.Y
	end
end

return Scroller
