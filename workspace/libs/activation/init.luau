const Result = require "@libs/Result"
const createChildOfClass = require "@self/createChildOfClass"
const functions = require "@libs/primitives/functions"
const gt = require "@libs/vendor/gt"
const logger = require "@core/shared/logger"
const types = require "@self/types"
const useAttributes = require "@self/useAttributes"
const useChildOfClass = require "@self/useChildOfClass"

export type ActivationAttributes = types.ActivationAttributes
export type PredicateContext = types.PredicateContext
export type BindContext = types.BindContext
export type ActivationContext = types.ActivationContext
export type ActivationEvent = types.ActivationEvent
export type ActivationMode = types.ActivationMode

const modes: { [string]: ActivationMode } = {
	Click = require "@self/modes/Click",
	Died = require "@self/modes/Died",
	HumanoidStateChanged = require "@self/modes/HumanoidStateChanged",
	Jump = require "@self/modes/Jump",
	JumpInside = require "@self/modes/JumpInside",
	None = require "@self/modes/None",
	Prompt = require "@self/modes/Prompt",
	Touch = require "@self/modes/Touch",
}

export type RegisterModeError = { id: "invalidMode", cause: gt.Cause } | { id: "alreadyExists" }

const function registerMode(
	key: string,
	mode: types.ActivationMode
): Result.Result<types.ActivationMode, RegisterModeError>
	if modes[key] then return Result.Err { id = functions.literal "alreadyExists" } end

	local isValid, invalidatedCause = types.ActivationMode:matches(mode)

	if isValid then
		modes[key] = mode
		return Result.Ok(mode)
	end

	return Result.Err {
		id = functions.literal "invalidMode",
		cause = invalidatedCause,
	}
end

const function unregisterMode(key: string)
	modes[key] = nil
end

export type ActivationError = { id: "noMode" } | { id: "unknownMode" } | { id: "predicateFailed", error: string }

const function activate(context: types.ActivationContext): Result.Result<nil, ActivationError>
	local modeKey = context.attributes.Mode(context.instanceConfiguration)
	if modeKey then
		local mode: ActivationMode? = modes[modeKey]

		if mode then
			if mode.predicate then
				local predicateResult = mode.predicate(context)
				if predicateResult:isErr() then
					return Result.Err {
						id = functions.literal "predicateFailed",
						error = predicateResult:unwrapErr() :: string,
					}
				end
			end

			mode.implement(context)
			return Result.Ok(nil)
		end

		return Result.Err { id = functions.literal "unknownMode" }
	end
	return Result.Err { id = functions.literal "noMode" }
end

const function bindActivation(bindContext: BindContext)
	local context = table.clone(bindContext) :: ActivationContext
	local life = context.instanceLife:extend()
	context.activationLife = life:extend()

	local function update()
		context.activationLife:destroy()
		context.activationLife = life:extend()

		if context.attributes.Enabled(context.instanceConfiguration) then
			local result = activate(context)
			if result:isErr() then
				logger:Warn(
					"Failed to bind activation for",
					context.instance:GetFullName(),
					"because:",
					result:unwrapErr()
				)
			end
		end
	end

	life:add(context.attributes.Enabled:onBind(context.instanceConfiguration, update))
	life:add(context.attributes.Mode:onBind(context.instanceConfiguration, update))
end

const function castEvent(eventLike: { kind: string }): ActivationEvent
	return eventLike :: ActivationEvent
end

return table.freeze {
	modes = modes,
	registerMode = registerMode,
	unregisterMode = unregisterMode,

	activate = activate,
	bindActivation = bindActivation,
	castEvent = castEvent,

	createChildOfClass = createChildOfClass,
	useChildOfClass = useChildOfClass,
	useAttributes = useAttributes,
}
