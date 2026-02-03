local RunService = game:GetService("RunService")

local std = require("@libs/std")

local ScrollingImage = std.Mechanic("ScrollingImage", std.gt.isA.ImageLabel())({
	Speed = std.Attribute("Speed", std.gt.UDim2(), UDim2.new()),
	BasePosition = std.Attribute("BasePosition", std.gt.UDim2()),
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),
	DisableDefaults = std.Attribute("DisableDefaults", std.gt.boolean(), false),

	onInit = function(self: Self, level: std.Level)
		level.life:add(RunService.PreRender:Connect(function(dt)
			local lifetime = level:getLifetime()
			for _, image: Self in level:getMechanics(self) do
				if not image:Enabled() then
					continue
				end

				local instance = image.instance
				local absoluteSize = instance.AbsoluteSize

				local speed = image:Speed()
				local base = image:BasePosition() or instance.Position

				local tileSize = instance.TileSize
				local tileSizeScale = Vector2.new(tileSize.X.Scale, tileSize.Y.Scale)
				local tileSizeOffset = Vector2.new(tileSize.X.Offset, tileSize.Y.Offset)
				local absoluteTileSize = absoluteSize * tileSizeScale + tileSizeOffset

				local baseAbsolute = absoluteSize * Vector2.new(base.X.Scale, base.Y.Scale)
					+ Vector2.new(base.X.Offset, base.Y.Offset)

				local delta = absoluteSize * Vector2.new(speed.X.Scale, speed.Y.Scale)
					+ Vector2.new(speed.X.Offset, speed.Y.Offset)

				local absolutePosition = if image:Synchronized()
					then baseAbsolute + delta * lifetime
					else baseAbsolute + delta * dt

				absolutePosition = Vector2.new(
					((absolutePosition.X + absoluteTileSize.X) % absoluteTileSize.X) - absoluteTileSize.X,
					((absolutePosition.Y + absoluteTileSize.Y) % absoluteTileSize.Y) - absoluteTileSize.Y
				)

				instance.Position = UDim2.fromOffset(absolutePosition.X, absolutePosition.Y)

				if not image:Synchronized() then
					image.BasePosition:set(image, instance.Position)
				end
			end
		end))
	end,

	onStart = function(self: Mechanic)
		if self:DisableDefaults() then
			return
		end

		self.instance.AnchorPoint = Vector2.zero
		self.instance.ScaleType = Enum.ScaleType.Tile

		local tileSize = self.instance.TileSize
		self.instance.Size = UDim2.new(
			1 + tileSize.Width.Scale * 2,
			tileSize.Width.Offset * 2,
			1 + tileSize.Height.Scale * 2,
			tileSize.Width.Offset * 2
		)

		local offset = self:BasePosition()
		if not offset then
			self.BasePosition:set(self, self.instance.Position)
		else
			self.instance.Position = offset
		end
	end,
})

export type Self = typeof(ScrollingImage)
export type Mechanic = std.Mechanic<Self>
return ScrollingImage
