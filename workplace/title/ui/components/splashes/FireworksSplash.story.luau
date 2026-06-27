local FireworksSplash = require "@title/ui/components/splashes/FireworksSplash"
local createFluidStory = require "@core/shared/fluid/createFluidStory"

return createFluidStory {
	controls = {
		visible = false,
	},
	render = function(props)
		return FireworksSplash {
			visible = props.controls.visible,
		}
	end,
}
