-- TODO: this is hot garbage

local attributes = require("@self/attributes")
local impls = require("@self/impls")
local life = require("@libs/Life")

type ActivationBehaviorImpl = {
	predicate: ((instance: Instance) -> boolean)?,
	implement: (
		life: life.Life,
		instanceLife: life.Life,
		instance: Instance,
		onActivated: (life: life.Life, instance: Instance) -> ()
	) -> (),
}

local activation = {}

local function implementActivationBehavior<T>(
	life: life.Life,
	instanceLife: life.Life,
	instance: T & Instance,
	configurationInstance: Instance,
	onActivated: (life: life.Life, instance: T) -> ()
)
	local behavior = attributes.ActivationBehavior(configurationInstance)
	local behaviorImpl: ActivationBehaviorImpl? = (impls :: any)[behavior]
	if behaviorImpl then
		if behaviorImpl.predicate and not behaviorImpl.predicate(instance) then
			return
		end
		behaviorImpl.implement(life, instanceLife, instance, configurationInstance, onActivated :: any)
	end
end

function activation.onActivated<T>(
	instanceLife: life.Life,
	instance: T & Instance,
	configurationInstance: Instance,
	onActivated: (life: life.Life, instance: T) -> ()
)
	local life = instanceLife:inner()
	local activationLife = life:inner()

	print("???", instance)

	if attributes.Activatable:get(configurationInstance) then
		implementActivationBehavior(activationLife, life, instance, configurationInstance, onActivated)
	end

	life:add(attributes.Activatable:onBind(configurationInstance, function(new)
		activationLife:destroy()
		activationLife = life:inner()

		if new then
			implementActivationBehavior(activationLife, life, instance, configurationInstance, onActivated)
		end
	end))
end

return table.freeze(activation)
