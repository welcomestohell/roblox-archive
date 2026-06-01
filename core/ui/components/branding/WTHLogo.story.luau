local WTHLogo = require("./WTHLogo")
local createFluidStory = require("@core/shared/fluid/createFluidStory")

return createFluidStory({
	controls = {
		visible = true,
	},
	render = function(props)
		return WTHLogo({
			visible = props.controls.visible,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.5, 0.5),
		})
	end,
})
