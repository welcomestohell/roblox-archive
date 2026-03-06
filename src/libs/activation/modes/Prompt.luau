local Players = game:GetService("Players")

local types = require("../types")
local useChildOfClass = require("../useChildOfClass")

local Prompt = {} :: types.ActivationMode

function Prompt.implement(ctx: types.ActivationContext)
	local prompt = useChildOfClass(ctx, "ActivationProximityPrompt", "ProximityPrompt")
	ctx.activationLife:add(prompt.Triggered:Connect(function(player: Player)
		-- TODO: is this check needed?
		if player == Players.LocalPlayer then
			ctx:onActivate { kind = "Prompt", prompt = prompt }
		end
	end))
end

return Prompt
