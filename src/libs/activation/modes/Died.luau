local character = require("@libs/character")
local types = require("../types")

local HumanoidStateChange = {} :: types.ActivationMode

function HumanoidStateChange.implement(ctx: types.ActivationContext)
	local humanoid = character.getHumanoid()
	ctx.activationLife:add(humanoid.Died:Connect(function()
		ctx:onActivate()
	end))
end

return HumanoidStateChange
