local Life = require("@libs/Life")
local Result = require("@libs/Result")
local gt = require("@libs/gt")

export type PredicateContext = {
	instance: Instance,
	instanceConfiguration: Instance,
}

export type BindContext = PredicateContext & {
	instanceLife: Life.Life,
	onActivate: (ctx: ActivationContext) -> (),
}

export type ActivationContext = BindContext & {
	activationLife: Life.Life,
}

local ActivationMode = gt.build(gt.table({
	predicate = gt.optional(gt.anyfn() :: (PredicateContext) -> Result.Result<nil, string>),
	implement = gt.anyfn() :: (ActivationContext) -> (),
}))

export type ActivationMode = typeof(ActivationMode:type())

return table.freeze {
	ActivationMode = ActivationMode,
}
