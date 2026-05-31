local SplashWth = require("@title/ui/components/SplashWth")
local UILabs = require("@roblox_packages/UILabs")
local Vide = require("@roblox_packages/Vide")
local createFluidStory = require("@core/shared/fluid/createFluidStory")

return createFluidStory({
	controls = {},
	render = function()
		return SplashWth()
	end,
})
