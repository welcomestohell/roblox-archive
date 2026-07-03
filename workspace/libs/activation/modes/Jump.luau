const jump = require "@libs/jump"
local types = require "../types"

local Jump = {} :: types.ActivationMode

function Jump.implement(context: types.ActivationContext)
	context.activationLife:add(jump.onBind(function()
		context:onActivate { kind = "Jump" }
	end))
end

return Jump
