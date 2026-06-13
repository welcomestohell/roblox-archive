local TitleScreen = require "@title/ui/components/title/TitleScreen"
const Liquid = require "@roblox_packages/Liquid"

return Liquid.createFluidStory {
	controls = {},
	render = function() return TitleScreen() end,
}
