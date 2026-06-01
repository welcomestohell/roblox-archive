local Fluid = require "@roblox_packages/Fluid"
local assets = require "@core/shared/generated/assets"
local useDelay = require "@core/shared/fluid/useDelay"
local useRem = require "@core/shared/fluid/useRem"

local function Letter(props: {
	name: string,
	imageId: string,

	visible: Fluid.UsedAs<boolean>,
	transparency: Fluid.UsedAs<number>?,

	xShift: number,
	zIndex: number,
})
	local function progress()
		return Fluid.read(props.visible) and 0 or 1
	end

	local transparency = props.transparency or progress

	local function size()
		local scale = 1 + Fluid.read(progress) / 100
		return UDim2.fromScale(scale, scale)
	end

	local function position()
		local transparency = Fluid.read(progress)
		return UDim2.fromScale(
			0.5 + math.map(transparency, 1, 0, 0.02, 0) * props.xShift,
			math.map(transparency, 1, 0, -0.09, 0)
		)
	end

	return Fluid.create "ImageLabel" {
		Name = props.name,
		ZIndex = props.zIndex,
		BackgroundTransparency = 1,

		Image = props.imageId,
		ImageTransparency = Fluid.spring(progress, 30, 2 / 3),

		AnchorPoint = Vector2.new(0.5, 0),
		Position = Fluid.spring(position, 30, 2 / 3),
		Size = Fluid.spring(size, 20, 2 / 3),
	}
end

local function WTHLogo(props: {
	visible: Fluid.UsedAs<boolean>,
	transparency: Fluid.UsedAs<number>?,

	name: Fluid.UsedAs<string>?,
	size: Fluid.UsedAs<UDim2>?,

	anchorPoint: Fluid.UsedAs<Vector2>?,
	position: Fluid.UsedAs<UDim2>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,
})
	local rem = useRem()

	return Fluid.create "Frame" {
		Name = props.name or "WTHLogo",
		BackgroundTransparency = 1,
		ZIndex = props.zIndex,

		AnchorPoint = props.anchorPoint,
		Position = props.position,
		LayoutOrder = props.layoutOrder,
		Size = props.size or function()
			return UDim2.fromOffset(rem(24), rem(24))
		end,

		Letter {
			name = "W",
			imageId = assets.branding.wth.letterW,
			visible = useDelay<<boolean>>(0, props.visible),
			transparency = props.transparency,
			xShift = -1,
			zIndex = 1,
		},

		Letter {
			name = "T",
			imageId = assets.branding.wth.letterT,
			visible = useDelay<<boolean>>(0.1, props.visible),
			transparency = props.transparency,
			xShift = 0,
			zIndex = 2,
		},

		Letter {
			name = "H",
			imageId = assets.branding.wth.letterH,
			visible = useDelay<<boolean>>(0.2, props.visible),
			transparency = props.transparency,
			xShift = 1,
			zIndex = 1,
		},
	}
end

return WTHLogo
