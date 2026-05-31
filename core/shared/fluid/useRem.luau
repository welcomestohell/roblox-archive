local Fluid = require("@roblox_packages/Fluid")
local useCamera = require("@core/shared/fluid/useCamera")

const BASE_REM = 16
const MIN_REM = 10
const BASE_RESOLUTION = Vector2.new(1280, 832)
const DOMINANT_AXIS = 0.5

local function calculateRem(viewport: Vector2)
	local width = math.log(viewport.X / BASE_RESOLUTION.X, 2)
	local height = math.log(viewport.Y / BASE_RESOLUTION.Y, 2)
	local centered = width + (height - width) * DOMINANT_AXIS

	return math.max(BASE_REM * 2 ^ centered, MIN_REM)
end

local function useRem()
	local camera = useCamera()

	local viewportSize = Fluid.derive(function()
		return camera().ViewportSize
	end)

	local rem = Fluid.derive(function()
		return calculateRem(viewportSize())
	end)

	return function(value: Fluid.UsedAs<number>, mode: "scale" | "unit" | nil)
		return if mode == "scale" then Fluid.read(value) * rem() / BASE_REM else Fluid.read(value) * rem()
	end
end

return useRem
