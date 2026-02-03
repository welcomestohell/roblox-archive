local RunService = game:GetService("RunService")

local std = require("@libs/std")

local ScrollingImage = std.Mechanic("ScrollingImage", std.gt.isA.ImageLabel())({
	Speed = std.Attribute("Speed", std.gt.UDim2(), UDim2.new()),
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),
	DisableDefaults = std.Attribute("DisableDefaults", std.gt.boolean(), false),

	onInit = function(self: Self, level: std.Level)
		level.life:add(RunService.PreRender:Connect(function(dt)
			for _, image: Self in level:getMechanics(self) do
				if not image:Enabled() then
					continue
				end

				local speed = image:Speed()
				local absoluteSize = image.instance.AbsoluteSize

				local tileSize = image.instance.TileSize
				local tileSizeScale = Vector2.new(tileSize.X.Scale, tileSize.Y.Scale)
				local tileSizeOffset = Vector2.new(tileSize.X.Offset, tileSize.Y.Offset)
				local absoluteTileSize = absoluteSize * tileSizeScale + tileSizeOffset

				local position = image.instance.Position
				local positionScale = Vector2.new(position.X.Scale, position.Y.Scale)
				local positionOffset = Vector2.new(position.X.Offset, position.Y.Offset)
				local absolutePosition = absoluteSize * positionScale + positionOffset

				local deltaPosition = absoluteSize * Vector2.new(speed.X.Scale, speed.Y.Scale)
					+ Vector2.new(speed.X.Offset, speed.Y.Offset)

				absolutePosition += deltaPosition * dt
				absolutePosition = Vector2.new(
					((absolutePosition.X + absoluteTileSize.X) % absoluteTileSize.X) - absoluteTileSize.X,
					((absolutePosition.Y + absoluteTileSize.Y) % absoluteTileSize.Y) - absoluteTileSize.Y
				)

				image.instance.Position = UDim2.fromOffset(absolutePosition.X, absolutePosition.Y)
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
			tileSize.Width.Scale * 2,
			tileSize.Width.Offset * 2,
			tileSize.Height.Scale * 2,
			tileSize.Width.Offset * 2
		)
	end,
})

export type Self = typeof(ScrollingImage)
export type Mechanic = std.Mechanic<Self>
return ScrollingImage
