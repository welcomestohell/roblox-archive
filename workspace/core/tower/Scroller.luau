local logger = require "@core/shared/logger"
local std = require "@libs/std"
local types = require "@libs/types"

local Scroller = std.Mechanic {
	name = "Scroller",
	description = "Continuously scrolls a image on an ImageLabel or Texture.",
	instanceType = std.gt.union(std.isA.ImageLabel(), std.isA.Texture()),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Speed = std.Attribute("Speed", std.gt.union(std.gt.UDim2(), std.gt.Vector2()), types.nilAs<<UDim2 | Vector2>>()),
	Offset = std.Attribute("Offset", std.gt.union(std.gt.UDim2(), std.gt.Vector2()), types.nilAs<<UDim2 | Vector2>>()),
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),
	SetDefaults = std.Attribute("SetDefaults", std.gt.boolean(), true),
	LoopHorizontally = std.Attribute("LoopHorizontally", std.gt.boolean(), true),
	LoopVertically = std.Attribute("LoopVertically", std.gt.boolean(), true),
}

export type ScrollerSelf = typeof(Scroller)
export type ScrollerMechanic = std.Mechanic<ScrollerSelf>

function Scroller.onStart(self: ScrollerSelf, scroller: ScrollerMechanic)
	local offset = self.Offset:peek(scroller)
	if scroller.instance:IsA "ImageLabel" then
		if typeof(offset) == "UDim2" then
			scroller.instance.Position = offset
		else
			scroller:Offset(scroller.instance.Position)
		end

		scroller.Speed:onBind(function(offset)
			if typeof(offset) == "Vector2" then
				logger:Error "Cannot set a Scroller's Speed to a Vector2 value on an ImageLabel"
				scroller:Speed(UDim2.new())
			end
		end)

		scroller.Offset:onBind(function(offset)
			if typeof(offset) == "Vector2" then
				logger:Error "Cannot set a Scroller's Offset to a Vector2 value on an ImageLabel"
				scroller:Offset(UDim2.new())
			end
		end)
	else
		if typeof(offset) == "Vector2" then
			scroller.instance.OffsetStudsU = offset.X
			scroller.instance.OffsetStudsV = offset.Y
		else
			scroller:Offset(Vector2.new(scroller.instance.OffsetStudsU, scroller.instance.OffsetStudsV))
		end

		scroller.Speed:onBind(function(offset)
			if typeof(offset) == "UDim2" then
				logger:Error "Cannot set a Scroller's Speed to a UDim2 value on a Texture"
				scroller:Speed(Vector2.zero)
			end
		end)

		scroller.Offset:onBind(function(offset)
			if typeof(offset) == "UDim2" then
				logger:Error "Cannot set a Scroller's Offset to a UDim2 value on a Texture"
				scroller:Offset(Vector2.zero)
			end
		end)
	end
end

function Scroller.stepImageLabel(scroller: ScrollerMechanic, deltaTime: number, lifetime: number)
	local speed = scroller:Speed() :: UDim2
	local offset = scroller:Offset() :: UDim2

	local instance = scroller.instance :: ImageLabel
	local absoluteSize = instance.AbsoluteSize

	local tileSize = instance.TileSize
	local tileSizeScale = Vector2.new(tileSize.X.Scale, tileSize.Y.Scale)
	local tileSizeOffset = Vector2.new(tileSize.X.Offset, tileSize.Y.Offset)
	local absoluteTileSize = absoluteSize * tileSizeScale + tileSizeOffset

	local baseAbsolute = absoluteSize * Vector2.new(offset.X.Scale, offset.Y.Scale)
		+ Vector2.new(offset.X.Offset, offset.Y.Offset)

	local delta = absoluteSize * Vector2.new(speed.X.Scale, speed.Y.Scale) + Vector2.new(speed.X.Offset, speed.Y.Offset)

	local absolutePosition = if scroller:Synchronized()
		then baseAbsolute + delta * lifetime
		else baseAbsolute + delta * deltaTime

	instance.Position = UDim2.fromOffset(
		((absolutePosition.X + absoluteTileSize.X) % absoluteTileSize.X) - absoluteTileSize.X,
		((absolutePosition.Y + absoluteTileSize.Y) % absoluteTileSize.Y) - absoluteTileSize.Y
	)

	if not scroller:Synchronized() then scroller:Offset(instance.Position) end
end

function Scroller.step(scroller: ScrollerMechanic, deltaTime: number, lifetime: number)
	if scroller.instance:IsA "ImageLabel" then
		scroller:stepImageLabel(deltaTime, lifetime)
	else
		scroller:stepTexture(deltaTime, lifetime)
	end
end

function Scroller.stepTexture(scroller: ScrollerMechanic, deltaTime: number, lifetime: number)
	local speed = scroller:Speed() :: Vector2
	local offset = scroller:Offset() :: Vector2
	local instance = scroller.instance :: Texture

	local newOffset = if scroller:Synchronized()
		then offset + speed / Vector2.new(instance.StudsPerTileU, instance.StudsPerTileV) * lifetime
		else Vector2.new(instance.OffsetStudsU, instance.OffsetStudsV) + speed * deltaTime

	instance.OffsetStudsU = if scroller:LoopHorizontally() then newOffset.X % instance.StudsPerTileU else newOffset.X
	instance.OffsetStudsV = if scroller:LoopVertically() then newOffset.Y % instance.StudsPerTileV else newOffset.Y
end

function Scroller.onPreRender(self: ScrollerSelf, deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()
	for _, scroller: ScrollerMechanic in level:getMechanics(self) do
		scroller:step(deltaTime, lifetime)
	end
end

return Scroller
