local Mechanic = require "@libs/core/Mechanic"
local Signal = require "@pkgs/Signal"
local character = require "@libs/character"
local tables = require "@libs/primitives/tables"
local triplets = require "@libs/primitives/triplets"

export type Mounter = {
	name: string,
	onDismount: Signal.Signal<()>,
}

local mounts = {
	instanceToMounts = tables.createWeakened<<BasePart, { [Instance]: Mounter }>> "k",
}

function mounts.getInstanceMounts(instance: BasePart): { [Instance]: Mounter }
	return triplets.get(mounts.instanceToMounts, instance, "k")
end

function mounts.isMounted(instance: BasePart, mounterName: string): boolean
	for _, mounter in mounts.getInstanceMounts(instance) do
		if mounter.name == mounterName then return true end
	end
	return false
end

function mounts.isMechanicMounted(instance: BasePart, mechanic: Mechanic.AnyMechanic): boolean
	local mounterName = (mechanic :: Mechanic.Mechanic<Mechanic.AnyMechanicImplementation>).name
	for _, mounter in mounts.getInstanceMounts(instance) do
		if mounter.name == mounterName then return true end
	end
	return false
end

function mounts.mount(instance: BasePart, mounterInstance: Instance, mounterName: string): Signal.Signal<()>
	local onDismount = Signal.new()
	mounts.getInstanceMounts(instance)[mounterInstance] = {
		name = mounterName,
		onDismount = onDismount,
	}
	return onDismount
end

function mounts.mountMechanic(instance: BasePart, mechanic: Mechanic.AnyMechanic): Signal.Signal<()>
	local onDismount = Signal.new()
	mounts.getInstanceMounts(instance)[mechanic.instance] = {
		name = (mechanic :: Mechanic.Mechanic<Mechanic.AnyMechanicImplementation>).name,
		onDismount = onDismount,
	}
	return onDismount
end

function mounts.dismount(instance: BasePart, mounterInstance: Instance)
	local instanceMounts = mounts.getInstanceMounts(instance)
	local mounter = instanceMounts[mounterInstance]
	if mounter then
		instanceMounts[mounterInstance] = nil
		mounter.onDismount:Fire()
	end
end

function mounts.dismountMechanic(instance: BasePart, mechanic: Mechanic.AnyMechanic)
	local instanceMounts = mounts.getInstanceMounts(instance)
	local mounter = instanceMounts[mechanic.instance]
	if mounter then
		instanceMounts[mechanic.instance] = nil
		mounter.onDismount:Fire()
	end
end

function mounts.castToucher(toucher: unknown): BasePart?
	if not toucher or typeof(toucher) ~= "Instance" then return nil end

	-- LUAU FIXME: some straight bullshit going on here
	const maybeCharacter: Instance = character.getMaybeCharacter() :: any
	if maybeCharacter ~= nil and (toucher == maybeCharacter or toucher:IsDescendantOf(maybeCharacter)) then
		return maybeCharacter:FindFirstChild "HumanoidRootPart" :: BasePart?
	end

	if toucher:IsA "Model" and toucher.PrimaryPart then return toucher.PrimaryPart end

	if toucher:IsA "BasePart" then return toucher end

	return nil
end

return table.freeze(mounts)
