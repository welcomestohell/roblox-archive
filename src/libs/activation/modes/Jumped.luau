local UserInputService = game:GetService("UserInputService")

local types = require("../types")

local Jump = {} :: types.ActivationMode

function Jump.implement(ctx: types.ActivationContext)
	ctx.activationLife:add(UserInputService.JumpRequest:Connect(function()
		ctx:onActivate()
	end))
end

return Jump
