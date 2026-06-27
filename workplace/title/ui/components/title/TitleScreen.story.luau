local TitleScreen = require "@title/ui/components/title/TitleScreen"
const Liquid = require "@pkgs/Liquid"

return Liquid.createFluidStory {
	controls = {},
	render = function()
		return TitleScreen()
	end,
}
