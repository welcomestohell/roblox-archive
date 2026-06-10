local TitleScreen = require "@title/ui/components/title/TitleScreen"
local createFluidStory = require "@core/shared/fluid/createFluidStory"

return createFluidStory {
	controls = {},
	render = function() return TitleScreen() end,
}
