local FireworksLogo = require "@core/ui/components/branding/FireworksLogo"
local Fluid = require "@roblox_packages/Fluid"
local useDelay = require "@core/shared/fluid/useDelay"
-- local assets = require "@core/assets"
-- local useMotion = require "@core/shared/fluid/useMotion"
local useNextOrder = require "@core/shared/fluid/useNextOrder"

local function FireworksSplash(props: {
	visible: Fluid.UsedAs<boolean>,
	layoutOrder: Fluid.UsedAs<number>?,
})
	local nextOrder = useNextOrder()

	-- local outlineSize, outlineSizeMotion = useMotion(UDim2.fromScale(0, 0))
	-- local outlineTransparency, outlineTransparencyMotion = useMotion(1)

	-- Fluid.effect(function()
	-- 	if Fluid.read(props.visible) then
	-- 		outlineSizeMotion:setPosition(UDim2.fromScale(0.5, 0.5))
	-- 		outlineTransparencyMotion:setPosition(0)
	-- 	else
	-- 		outlineSizeMotion:spring(UDim2.fromScale(2, 2))
	-- 		outlineTransparencyMotion:spring(1)
	-- 	end
	-- end)

	return Fluid.create "Frame" {
		Name = "FireworksSplash",
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = props.layoutOrder,
		Visible = props.visible,

		BackgroundColor3 = Color3.new(0, 0, 0),

		-- Fluid.create "ImageLabel" {
		-- 	Name = "Outline",
		-- 	Image = assets.branding.fireworks.wordmarkOutline,
		-- 	BackgroundTransparency = 1,
		-- 	LayoutOrder = nextOrder(),
		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 	Position = UDim2.fromScale(0.5, 0.5),

		-- 	ImageTransparency = outlineTransparency,
		-- 	Size = outlineSize,

		-- 	Fluid.create "UIAspectRatioConstraint" {
		-- 		AspectRatio = 74 / 24,
		-- 	},
		-- },

		FireworksLogo {
			visible = props.visible,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.5, 0.5),
			layoutOrder = nextOrder(),
		},
	}
end

return FireworksSplash
