local Liquid = require "@pkgs/Liquid"
local TitleScreen = require "@title/ui/components/title/TitleScreen"

return Liquid.createFluidStory {
	controls = {},
	render = function()
		return TitleScreen()
	end,
}
