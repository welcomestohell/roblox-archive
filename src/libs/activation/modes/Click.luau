local Players = game:GetService("Players")

local types = require("../types")
local useChildOfClass = require("@libs/activation2/useChildOfClass")

local Click = {} :: types.ActivationMode

function Click.implement(ctx: types.ActivationContext)
	local detector = useChildOfClass(ctx, "ActivationClickDetector", "ClickDetector")
	ctx.activationLife:add(detector.MouseClick:Connect(function(player: Player)
		-- TODO: is this check needed?
		if player == Players.LocalPlayer then
			ctx:onActivate()
		end
	end))
end

return Click
