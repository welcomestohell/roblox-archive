local Result = require("@libs/Result")
local createChildOfClass = require("@self/createChildOfClass")
local functions = require("@libs/functions")
local gt = require("@libs/gt")
local log = require("@self/log")
local types = require("@self/types")
local useAttributes = require("@self/useAttributes")
local useChildOfClass = require("@self/useChildOfClass")

export type ActivationAttributes = types.ActivationAttributes
export type PredicateContext = types.PredicateContext
export type BindContext = types.BindContext
export type ActivationContext = types.ActivationContext
export type ActivationEvent = types.ActivationEvent
export type ActivationMode = types.ActivationMode

local modes: { [string]: ActivationMode } = {
	Click = require("@self/modes/Click"),
	Died = require("@self/modes/Died"),
	HumanoidStateChanged = require("@self/modes/HumanoidStateChanged"),
	Jumped = require("@self/modes/Jumped"),
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
	log:trace("Activate", ctx.instance:GetFullName())
	local modeKey = ctx.attributes.Mode(ctx.instanceConfiguration)
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

local function bindActivation(bindCtx: BindContext)
	local ctx = table.clone(bindCtx) :: ActivationContext
	local life = ctx.instanceLife:extend()
	ctx.activationLife = life:extend()

	local function update()
		ctx.activationLife:destroy()
		ctx.activationLife = life:extend()

		if bindCtx.attributes.Enabled(ctx.instanceConfiguration) then
			local result = activate(ctx)
			if result:isErr() then
				log:warn("Failed to bind activation for", ctx.instance:GetFullName(), "because:", result:unwrapErr())
			end
		end
	end

	log:trace("Binding activation to", ctx.instance:GetFullName())
	life:add(bindCtx.attributes.Enabled:onBind(ctx.instanceConfiguration, update))
	life:add(bindCtx.attributes.Mode:onBind(ctx.instanceConfiguration, update))
end

return table.freeze {
	modes = modes,
	registerMode = registerMode,
	unregisterMode = unregisterMode,

	activate = activate,
	bindActivation = bindActivation,

	createChildOfClass = createChildOfClass,
	useChildOfClass = useChildOfClass,
	useAttributes = useAttributes,
}
