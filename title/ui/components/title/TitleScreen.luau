local Fluid = require "@roblox_packages/Fluid"
local WTHLogo = require "@core/ui/components/branding/WTHLogo"
const Liquid = require "@roblox_packages/Liquid"

local function TitleScreen()
	local nextOrder = Liquid.useNextOrder()

	local logoVisible = Fluid.source(false)
	local shiftLogo = Liquid.useDelay(2, logoVisible)

	Fluid.cleanup(task.delay(0.2, logoVisible, true))

	return Fluid.create "Frame" {
		Name = "TitleScreen",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = Fluid.spring(Liquid.useToggled(shiftLogo, 1, 0), 2, 0.5),
		Size = UDim2.fromScale(1, 1),

		WTHLogo {
			layoutOrder = nextOrder(),
			visible = logoVisible,

			anchorPoint = Fluid.spring(
				Liquid.useToggled(shiftLogo, Vector2.new(0.5, 0), Vector2.new(0.5, 0.5)),
				2,
				0.5
			),

			position = Fluid.spring(
				Liquid.useToggled(shiftLogo, UDim2.fromScale(0.5, 0), UDim2.fromScale(0.5, 0.5)),
				2,
				0.5
			),

			size = Fluid.spring(
				Liquid.useToggled(shiftLogo, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.75, 0.75)),
				2,
				0.5
			),
		},
	}
end

return TitleScreen
