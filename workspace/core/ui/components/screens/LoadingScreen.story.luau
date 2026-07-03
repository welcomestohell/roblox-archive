local Liquid = require "@pkgs/Liquid"
local LoadingScreen = require "@core/ui/components/screens/LoadingScreen"
local assets = require "@core/assets"

return Liquid.createFluidStory {
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
