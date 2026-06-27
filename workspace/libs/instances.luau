const gt = require "@libs/vendor/gt"

-- LUAU FIXME: Waiting on cyclic requires RFC to be merged, this depends on
-- Mechanic type </3
export type InstanceLike = any

--[[
	Helper APIs to work with Roblox instances.
]]
const instances = {
	ModulePointerLike = gt.union(gt.isA.ObjectValue(), gt.isA.ModuleScript()),
	knownClassProperties = {} :: { [string]: { [string]: boolean } },
}

function instances.setUnsafe(instance: Instance, property: string, value: any)
	(instance :: any)[property] = value
end

function instances.getUnsafe(instance: Instance, property: string): any
	return (instance :: any)[property]
end

function instances.hasProperty(instance: Instance, property: string): boolean
	local knownProperties = instances.knownClassProperties[instance.ClassName]
	if knownProperties then
		local propertyExists = knownProperties[property]
		if propertyExists ~= nil then return propertyExists end
	else
		knownProperties = {}
		instances.knownClassProperties[instance.ClassName] = knownProperties
	end

	local propertyExists = pcall(function(instance: any, property)
		return (instance)[property]
	end, instance, property)
	knownProperties[property] = propertyExists
	return propertyExists
end

--[[
	Resolves ModuleScripts from module pointers. To optimize memory usage from
	modules, Welcome To Hell caches ModuleScripts under a LevelInstance into
	ReplicatedStorage.ModulePointers alongside ObjectValue module pointers.
]]
function instances.resolveModulePointer(resolvable: Instance): ModuleScript?
	-- What the FUCK is stylua smoking?
	-- stylua: ignore
	return
		if resolvable:IsA "ModuleScript" then
			resolvable
		elseif resolvable:IsA "ObjectValue" and resolvable:HasTag "Welcome To Hell: Module Pointer" and resolvable.Value then
			instances.resolveModulePointer(resolvable.Value)
		else
			nil
end

--[[
	Resolves Instances from Mechanics and plain instances.
]]
function instances.resolveInstanceLike(resolvable: InstanceLike): Instance
	local type = typeof(resolvable)
	-- stylua: ignore
	return
		if type == "Instance" then
			resolvable
		elseif type == "table" and resolvable.type == "Mechanic" then
			resolvable.instanceConfiguration 	or resolvable.instance
		elseif type == "table" and resolvable.type == "MechanicImplementation" then
			error(`No instance to resolve for MechanicImplementation {resolvable} (did you mean to use colon syntax on a mechanic *instance*?)`)
		else
			error(`Expected an instance or a mechanic, got {resolvable}`)
end

--[[
	Copies children, attributes, and tags to the destination instance. It's a
	creative name.
]]
function instances.copyCAT(from: Instance, to: Instance)
	for _, child in from:GetChildren() do
		child:Clone().Parent = to
	end

	for attribute, value in from:GetAttributes() do
		to:SetAttribute(attribute, value)
	end

	for _, tag in from:GetTags() do
		to:AddTag(tag)
	end
end

return table.freeze(instances)
