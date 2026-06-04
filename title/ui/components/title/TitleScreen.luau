local Fluid = require "@roblox_packages/Fluid"
local WTHLogo = require "@core/ui/components/branding/WTHLogo"
local useDelay = require "@core/shared/fluid/useDelay"
local useNextOrder = require "@core/shared/fluid/useNextOrder"
local useToggled = require "@core/shared/fluid/useToggled"

local function TitleScreen()
	local nextOrder = useNextOrder()

	local logoVisible = Fluid.source(false)
	local shiftLogo = useDelay(2, logoVisible)

	Fluid.cleanup(task.delay(0.2, logoVisible, true))

	return Fluid.create "Frame" {
		Name = "TitleScreen",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = Fluid.spring(useToggled(shiftLogo, 1, 0), 2, 0.5),
		Size = UDim2.fromScale(1, 1),

		WTHLogo {
			layoutOrder = nextOrder(),
			visible = logoVisible,

			anchorPoint = Fluid.spring(useToggled(shiftLogo, Vector2.new(0.5, 0), Vector2.new(0.5, 0.5)), 2, 0.5),
			position = Fluid.spring(useToggled(shiftLogo, UDim2.fromScale(0.5, 0), UDim2.fromScale(0.5, 0.5)), 2, 0.5),
			size = Fluid.spring(useToggled(shiftLogo, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.75, 0.75)), 2, 0.5),
		},
	}
end

return TitleScreen
