local Fluid = require("@roblox_packages/Fluid")
local useRem = require("@core/shared/fluid/useRem")

local function SplashWth(props)
	local rem = useRem()

	return Fluid.create("Frame")({
		Size = function()
			return UDim2.fromOffset(rem(16), rem(16))
		end,
	})
end

return SplashWth
