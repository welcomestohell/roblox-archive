const character = require "@libs/character"
const tables = require "@libs/collections/tables"
const Mechanic = require "@libs/core/Mechanic"
const Signal = require "@roblox_packages/Signal"

export type Mounter = {
	name: string,
	onDismount: Signal.Signal<()>,
}

const mounts = {
	instanceToMounts = tables.weak "k" :: { [BasePart]: { [Instance]: Mounter } },
}

function mounts.getInstanceMounts(instance: BasePart): { [Instance]: Mounter }
	mounts.instanceToMounts[instance] = mounts.instanceToMounts[instance] or tables.weak "k"
	return mounts.instanceToMounts[instance]
end

function mounts.isMounted(instance: BasePart, mounterName: string): boolean
	for _, mounter in mounts.getInstanceMounts(instance) do
		if mounter.name == mounterName then return true end
	end
	return false
end

function mounts.isMechanicMounted(instance: BasePart, mechanic: Mechanic.AnyMechanic): boolean
	const mounterName = (mechanic :: Mechanic.Mechanic<Mechanic.AnyMechanicImplementation>).name
	for _, mounter in mounts.getInstanceMounts(instance) do
		if mounter.name == mounterName then return true end
	end
	return false
end

function mounts.mount(instance: BasePart, mounterInstance: Instance, mounterName: string): Signal.Signal<()>
	const onDismount = Signal.new()
	mounts.getInstanceMounts(instance)[mounterInstance] = {
		name = mounterName,
		onDismount = onDismount,
	}
	return onDismount
end

function mounts.mountMechanic(instance: BasePart, mechanic: Mechanic.AnyMechanic): Signal.Signal<()>
	const onDismount = Signal.new()
	mounts.getInstanceMounts(instance)[mechanic.instance] = {
		name = (mechanic :: Mechanic.Mechanic<Mechanic.AnyMechanicImplementation>).name,
		onDismount = onDismount,
	}
	return onDismount
end

function mounts.dismount(instance: BasePart, mounterInstance: Instance)
	const instanceMounts = mounts.getInstanceMounts(instance)
	const mounter = instanceMounts[mounterInstance]
	if mounter then
		instanceMounts[mounterInstance] = nil
		mounter.onDismount:Fire()
	end
end

function mounts.dismountMechanic(instance: BasePart, mechanic: Mechanic.AnyMechanic)
	const instanceMounts = mounts.getInstanceMounts(instance)
	const mounter = instanceMounts[mechanic.instance]
	if mounter then
		instanceMounts[mechanic.instance] = nil
		mounter.onDismount:Fire()
	end
end

function mounts.castToucher(toucher: unknown): BasePart?
	if typeof(toucher) ~= "Instance" or not toucher:IsA "BasePart" then
		return nil
	elseif character.isFromMaybeCharacter(toucher) then
		return character.getHumanoidRootPart()
	else
		return toucher
	end
end

return table.freeze(mounts)
