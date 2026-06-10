const createFluidStory = require "@core/shared/fluid/createFluidStory"
const useRem = require "@core/shared/fluid/useRem"
const NumberSpinner = require "@core/ui/components/base/NumberSpinner"
const UILabs = require "@roblox_packages/UILabs"

return createFluidStory {
	controls = {
		value = UILabs.Slider(727, 0, 999, 1),
	},
	render = function(props)
		local rem = useRem()

		return NumberSpinner {
			value = props.controls.value :: any,
			numDigits = 3,
			position = UDim2.fromScale(0.5, 0.5),
			anchorPoint = Vector2.new(0.5, 0.5),
			size = rem:intoUdim2(8, 8),
			textSize = rem:intoPx(12),
			fontWeight = Enum.FontWeight.Bold,
		}
	end,
}
