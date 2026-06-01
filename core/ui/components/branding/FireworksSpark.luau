local Fluid = require("@roblox_packages/Fluid")
local assets = require("@core/shared/generated/assets")
local useRem = require("@core/shared/fluid/useRem")

local function FireworksSpark(props: {
	visible: Fluid.UsedAs<boolean>,

	name: Fluid.UsedAs<string>?,
	size: Fluid.UsedAs<UDim2>?,
	color: Fluid.UsedAs<Color3>?,

	anchorPoint: Fluid.UsedAs<Vector2>?,
	position: Fluid.UsedAs<UDim2>?,
	rotation: Fluid.UsedAs<number>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,
})
	local rem = useRem()

	local function transparency()
		return Fluid.read(props.visible) and 0 or 1
	end

	local size = Fluid.spring(function()
		local scale = math.map(transparency(), 0, 1, 1, 0)
		return UDim2.fromScale(scale, scale)
	end, 30, 1)

	return Fluid.create("Frame")({
		Name = props.name or "FireworksSpark",
		BackgroundTransparency = 1,
		ZIndex = props.zIndex,

		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Rotation = props.rotation,
		LayoutOrder = props.layoutOrder,
		Size = props.size or function()
			return UDim2.fromOffset(rem(24), rem(24))
		end,

		Fluid.create("ImageLabel")({
			BackgroundTransparency = 1,

			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,

			Image = assets.branding.fireworks.fireworks8,
			ImageColor3 = props.color,
			ImageTransparency = Fluid.spring(transparency, 15, 0.5),

			Rotation = Fluid.spring(function()
				return transparency() * -60 * 4
			end, 15, 1),
		}),

		Fluid.create("ImageLabel")({
			BackgroundTransparency = 1,

			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,

			Image = assets.branding.fireworks.fireworksX,
			ImageColor3 = props.color,
			ImageTransparency = Fluid.spring(transparency, 15, 0.5),

			Rotation = Fluid.spring(function()
				return transparency() * -60 * 2
			end, 15, 1),
		}),
	})
end

return FireworksSpark
