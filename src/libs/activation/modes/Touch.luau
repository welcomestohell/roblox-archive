local Result = require("@libs/Result")
local touch = require("@libs/touch")
local types = require("../types")

local Touch = {} :: types.ActivationMode

function Touch.predicate(ctx: types.PredicateContext)
	if ctx.instance:IsA("BasePart") then
		return Result.Ok(nil)
	end
	return Result.Err(`Expected a BasePart, got {ctx.instance.ClassName}`)
end

function Touch.implement(ctx: types.ActivationContext)
	ctx.activationLife:add((ctx.instance :: BasePart).Touched:Connect(function(toucher: BasePart)
		if touch.isToucherValid(ctx.instance, toucher) then
			ctx:onActivate { kind = "Touch", toucher = toucher }
		end
	end))
end

return Touch
