local LoadingScreen = require "@core/ui/components/screens/LoadingScreen"
local assets = require "@core/shared/generated/assets"
local createFluidStory = require "@core/shared/fluid/createFluidStory"

return createFluidStory {
	controls = {
		label = "Teleporting",
		title = "A Star Upon A Child",
		visible = false,
	},
	render = function(props)
		return LoadingScreen {
			label = props.controls.label,
			title = props.controls.title,
			imageId = assets.placeholder,
			visible = props.controls.visible,
		}
	end,
}
