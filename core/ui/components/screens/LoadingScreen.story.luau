local LoadingScreen = require("@core/ui/components/screens/LoadingScreen")
local createFluidStory = require("@core/shared/fluid/createFluidStory")

return createFluidStory({
	controls = {
		label = "Teleporting...",
		title = "A Star Upon A Child",
	},
	render = function(props)
		return LoadingScreen({
			label = props.controls.label,
			title = props.controls.title,
		})
	end,
})
