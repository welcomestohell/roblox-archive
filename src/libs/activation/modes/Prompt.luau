local Players = game:GetService("Players")

local types = require("@libs/activation/types")
local utils = require("@libs/activation/utils")

local Prompt = {} :: types.ActivationMode

function Prompt.implement(ctx: types.ActivationContext)
	local prompt = utils.expectChildOfClass(ctx, "ActivationProximityPrompt", "ProximityPrompt")()
	ctx.activationLife:add(prompt.Triggered:Connect(function(player: Player)
		-- TODO: is this check needed?
		if player == Players.LocalPlayer then
			ctx:onActivate()
		end
	end))
end

return Prompt
