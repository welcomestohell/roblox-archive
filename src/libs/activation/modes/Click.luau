local Players = game:GetService("Players")

local types = require("@libs/activation/types")
local utils = require("@libs/activation/utils")

local Click = {} :: types.ActivationMode

function Click.implement(ctx: types.ActivationContext)
	local detector = utils.expectChildOfClass(ctx, "ActivationClickDetector", "ClickDetector")()
	ctx.activationLife:add(detector.MouseClick:Connect(function(player: Player)
		-- TODO: is this check needed?
		if player == Players.LocalPlayer then
			ctx:onActivate()
		end
	end))
end

return Click
