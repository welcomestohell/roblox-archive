local gt = require("@pkgs/gt")
local tables = require(script.Parent.tables)

export type AttributeValue =
	| string
	| boolean
	| number
	| UDim
	| UDim2
	| BrickColor
	| Color3
	| Vector2
	| Vector3
	| CFrame
	| NumberSequence
	| ColorSequence
	| NumberRange
	| Rect
	| Font

-- LUAU FIXME: Can't require the Mechanic class due to cyclic dependencies, so
-- we specify a proxy type.
export type ResolvableInstance = any

local Attribute = {}
Attribute.__index = Attribute

export type Attribute<T> = setmetatable<{
	attribute: string,
	check: gt.Type?,
	defaultValue: T,
	_cache: { [Instance]: T },
	_signals: { [Instance]: RBXScriptSignal },
	_updated: { [Instance]: true },
	_observers: { [Instance]: RBXScriptConnection? },
	_observerCallbacks: { [Instance]: () -> ()? },
	_changeListeners: { [Instance]: { [(value: T, attribute: any) -> ()]: true } },
	_fetchListeners: { [Instance]: { [(value: T, attribute: any) -> ()]: true } },
}, typeof(Attribute)>

local function resolveInstance(resolvable: ResolvableInstance): Instance
	if typeof(resolvable) == "Instance" then
		return resolvable
	else
		return resolvable.instanceConfiguration or resolvable.instance
	end
end

local function observeChanges(self: Attribute<any>, attribute: string, instance: Instance)
	if not self._observers[instance] then
		local signal = self._signals[instance]
		if not signal then
			signal = instance:GetAttributeChangedSignal(attribute)
			self._signals[instance] = signal
		end

		local observe = self._observerCallbacks[instance]
		if not observe then
			function observe()
				local listeners = self._changeListeners[instance]
				if listeners and next(listeners) ~= nil then
					local value = instance:GetAttribute(self.attribute)
					for l in listeners do
						task.spawn(l, value, self)
					end
				else
					local connection = self._observers[instance]
					if connection and connection.Connected then
						connection:Disconnect()
					end
					self._observers[instance] = nil
				end
				self._updated[instance] = nil
			end

			self._observerCallbacks[instance] = observe
		end

		self._observers[instance] = (signal :: RBXScriptSignal):Connect(observe :: () -> ())
	end
end

local function fetchAttribute(self: Attribute<any>, instance: Instance)
	local attribute = self.attribute
	local value: any = instance:GetAttribute(attribute)

	self._cache[instance] = value
	self._updated[instance] = true

	observeChanges(self, attribute, instance)

	local listeners = self._fetchListeners[instance]
	if listeners and next(listeners) ~= nil then
		for l in listeners do
			task.spawn(l, value, self)
		end
	end

	return value
end

local function observeListener<T>(
	attribute: Attribute<T>,
	instance: ResolvableInstance,
	listeners: { [Instance]: { [(value: T, attribute: Attribute<T>) -> ()]: true } },
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	local resolved = resolveInstance(instance)
	local listeners = listeners[resolved] :: {}
	if not listeners then
		listeners = tables.weak("k") :: any
		listeners[resolved] = listeners
	end

	listeners[listener] = true

	local function disconnect()
		listeners[listener] = nil
		if next(listeners) == nil then
			listeners[resolved] = nil
		end
	end

	return disconnect
end

local function new(attribute: any, check: any, defaultValue: any): Attribute<any>
	return setmetatable({
		attribute = attribute,
		check = check,
		defaultValue = defaultValue,
		_cache = tables.weak("k"),
		_signals = tables.weak("k"),
		_updated = tables.weak("k"),
		_observers = tables.weak("k"),
		_observerCallbacks = tables.weak("k"),
		_changeListeners = tables.weak("k"),
		_fetchListeners = tables.weak("k"),
	}, Attribute) :: any
end

Attribute.new = new :: (
	& (<T>(attribute: string, check: T, defaultValue: T) -> Attribute<T>) & (<T>(attribute: string, check: T) -> Attribute<T?>)
)

function Attribute.peek<T>(self: Attribute<T>, instance: ResolvableInstance): T
	local value = self._cache[resolveInstance(instance)] :: any
	return if value == nil then self.defaultValue else value
end

function Attribute.fetch<T>(self: Attribute<T>, instance: ResolvableInstance): T
	local fetched = fetchAttribute(self, resolveInstance(instance))
	return if fetched == nil then self.defaultValue else fetched
end

function Attribute.get<T>(self: Attribute<T>, instance: ResolvableInstance): T
	local resolved = resolveInstance(instance)

	if self._updated[resolved] then
		local cached = self._cache[resolved]
		if cached == nil then
			return self.defaultValue
		end
	end

	return fetchAttribute(self :: any, resolved)
end

function Attribute.getOrSet<T>(self: Attribute<T>, instance: ResolvableInstance, default: T): T
	local value = self:get(instance)

	if value == nil then
		value = self:set(instance, default)
	end

	return value
end

function Attribute.getOrSetWith<T>(self: Attribute<T>, instance: ResolvableInstance, derive: () -> T): T
	local value = self:get(instance)

	if value == nil then
		value = self:set(instance, derive())
	end

	return value
end

function Attribute.set<T>(self: Attribute<T>, instance: ResolvableInstance, value: T): T
	local resolved = resolveInstance(instance)

	resolved:SetAttribute(self.attribute, value)

	self._cache[resolved] = value
	self._updated[resolved] = true

	return value
end

function Attribute.assert<T>(self: Attribute<T?>, instance: ResolvableInstance, message: string?): T
	local value = Attribute.get(self :: any, instance)
	assert(value ~= nil, message or `Instance {resolveInstance(instance):GetFullName()} is missing attribute {self.attribute}!`)
	return value
end

-- (lazily evaluated)
function Attribute.onFetch<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	return observeListener(self, instance, self._fetchListeners, listener)
end

-- (eagerly evaluated)
function Attribute.onChange<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	return observeListener(self, instance, self._changeListeners, listener)
end

function Attribute.onBind<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	task.spawn(listener, Attribute.get(self :: any, instance), self)
	return Attribute.onChange(self :: any, instance, listener)
end

function Attribute.__call<T>(self: Attribute<T>, instance: ResolvableInstance, ...: T): T
	return if select("#", ...) == 0 then self:get(instance) else self:set(instance, ...)
end

function Attribute.__tostring<T>(self: Attribute<T>)
	return if self.check then `Attribute<{self.check:format()}>("{self.attribute}")` else `Attribute("{self.attribute}")`
end

return Attribute
