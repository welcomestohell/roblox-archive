local Result = require("@libs/Result")
local attributes = require("@self/attributes")
local functions = require("@libs/functions")
local gt = require("@libs/gt")
local types = require("@self/types")
local utils = require("@libs/activation/utils")

export type PredicateContext = types.PredicateContext
export type ActivationContext = types.ActivationContext
export type ActivationMode = types.ActivationMode

local modes: { [string]: ActivationMode } = {
	Click = require("@self/modes/Click"),
	HumanoidStateChanged = require("@self/modes/HumanoidStateChanged"),
	Prompt = require("@self/modes/Prompt"),
	Touch = require("@self/modes/Touch"),
}

export type RegisterModeError = { id: "invalidMode", cause: gt.Cause } | { id: "alreadyExists" }

local function registerMode(
	key: string,
	mode: types.ActivationMode
): Result.Result<types.ActivationMode, RegisterModeError>
	if modes[key] then
		return Result.Err({ id = functions.literal "alreadyExists" })
	end

	local isValid, invalidatedCause = types.ActivationMode:matches(mode)

	if isValid then
		modes[key] = mode
		return Result.Ok(mode)
	end

	return Result.Err({
		id = functions.literal "invalidMode",
		cause = invalidatedCause,
	})
end

local function unregisterMode(key: string)
	modes[key] = nil
end

export type ActivationError = { id: "noMode" } | { id: "unknownMode" } | { id: "predicateFailed", error: string }

local function activate(ctx: types.ActivationContext): Result.Result<nil, ActivationError>
	local modeKey = attributes.ActivationMode(ctx.instanceConfiguration)
	if modeKey then
		local mode: ActivationMode? = modes[modeKey]

		if mode then
			if mode.predicate then
				local predicateResult = mode.predicate(ctx)
				if predicateResult:isErr() then
					return Result.Err({
						id = functions.literal "predicateFailed",
						error = predicateResult:unwrapErr() :: string,
					})
				end
			end

			mode.implement(ctx)
			return Result.Ok(nil)
		end

		return Result.Err({ id = functions.literal "unknownMode" })
	end
	return Result.Err({ id = functions.literal "noMode" })
end

local function bindActivation(ctx: types.ActivationContext)
	local life = ctx.instanceLife:inner()
	local activationLife = life:inner()

	life:add(attributes.IsActivatable:onBind(ctx.instanceConfiguration, function(isActivatable)
		activationLife:destroy()
		activationLife = life:inner()

		if isActivatable then
			activate(ctx)
		end
	end))
end

return table.freeze {
	modes = modes,
	attributes = attributes,

	registerMode = registerMode,
	unregisterMode = unregisterMode,

	activate = activate,
	bindActivation = bindActivation,

	createChildOfClass = utils.createChildOfClass,
	expectChildOfClass = utils.expectChildOfClass,
}
