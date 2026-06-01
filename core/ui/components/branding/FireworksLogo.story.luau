local FireworksLogo = require("./FireworksLogo")
local createFluidStory = require("@core/shared/fluid/createFluidStory")

return createFluidStory({
	controls = {
		visible = true,
		color = Color3.fromHex("#FF004D"),
	},
	render = function(props)
		return FireworksLogo({
			visible = props.controls.visible,
			color = props.controls.color,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.5, 0.5),
		})
	end,
})
