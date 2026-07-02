const Attribute = require "@libs/attributes/Attribute"
const instances = require "@libs/instances"

local AttributeMap = {}
AttributeMap.__index = AttributeMap
AttributeMap.type = "AttributeMap"

export type AttributeMap<T> = setmetatable<{
	prefix: string,
	typecheck: T,
	defaultValue: T,
	attributes: { [string]: Attribute.Attribute<any> },
}, typeof(AttributeMap)>

local function getAttribute(self: AttributeMap<any>, key: string): Attribute.Attribute<any>
	local attr = self.attributes[key]

	if not attr then
		attr = Attribute.new(self.prefix .. key, self.typecheck, self.defaultValue)

		self.attributes[key] = attr
	end

	return attr
end

function AttributeMap.new<T>(prefix: string, typecheck: T, defaultValue: T): AttributeMap<T>
	return setmetatable({
		prefix = prefix,
		typecheck = typecheck,
		defaultValue = defaultValue,
		attributes = {},
	}, AttributeMap)
end

function AttributeMap.type<T>(_: AttributeMap<T>): T
	error "This function is undefined, and should only be used in type definitions: `typeof(attributeMap:type())`"
end

function AttributeMap.isAttributeMap(x: any)
	return type(x) == "table" and getmetatable(x) == AttributeMap
end

function AttributeMap.get<T>(self: AttributeMap<T>, instance: instances.InstanceLike, key: string): T
	local attribute = getAttribute(self, key)

	return attribute:get(instance)
end

function AttributeMap.getAll<T>(self: AttributeMap<T>, instance: instances.InstanceLike): { [string]: T }
	local resolved = instances.resolveInstanceLike(instance)
	local prefixLen = #self.prefix
	local result = {}

	for attrName, value in resolved:GetAttributes() do
		if string.sub(attrName, 1, prefixLen) == self.prefix then
			local key = string.sub(attrName, prefixLen + 1)

			result[key] = value
		end
	end

	return result :: any
end

function AttributeMap.set<T>(self: AttributeMap<T>, instance: instances.InstanceLike, key: string, value: any)
	local attribute = getAttribute(self, key)

	attribute:set(instance, value)
end

function AttributeMap.onChange<T>(
	self: AttributeMap<T>,
	instance: instances.InstanceLike,
	key: string,
	listener: (value: any) -> ()
): () -> ()
	local attr = getAttribute(self, key)

	return attr:onChange(instance, listener)
end

function AttributeMap.__tostring<T>(self: AttributeMap<T>)
	return `AttributeMap("{self.prefix}")`
end

return AttributeMap
