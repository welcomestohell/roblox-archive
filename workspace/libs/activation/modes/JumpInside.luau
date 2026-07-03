const UserInputService = game:GetService "UserInputService"

const Result = require "@libs/Result"
const tables = require "@libs/primitives/tables"
const touch = require "@libs/touch"
const types = require "../types"

const JumpInside = {} :: types.ActivationMode

function JumpInside.predicate(context: types.PredicateContext): Result.Result<nil, string>
	if context.instance:IsA "BasePart" then return Result.Ok(nil) end
	return Result.Err(`Expected a BasePart, got {context.instance.ClassName}`)
end

function JumpInside.implement(context: types.ActivationContext)
	const part = context.instance :: BasePart
	const touchingParts: { [BasePart]: true } = {}
	context.activationLife:addMany(
		part.Touched:Connect(function(toucher: BasePart)
			if touch.isToucherValid(context.attributes.Touch, part, context.instanceConfiguration, toucher) then
				touchingParts[toucher] = true
			end
		end),
		part.TouchEnded:Connect(function(toucher: BasePart)
			touchingParts[toucher] = nil
		end),
		UserInputService.JumpRequest:Connect(function()
			if tables.isNotEmpty(touchingParts) then context:onActivate { kind = "JumpInside", instance = part } end
		end),
		function()
			table.clear(touchingParts)
		end
	)
end

return JumpInside
