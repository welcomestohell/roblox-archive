local gt = require("@pkgs/gt")

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

-- cyclic deps
-- export type ResolvableInstance = MechanicTypes.Mechanic<any> | Instance
export type ResolvableInstance = any

local WEAK_KEYS_MT = { __mode = "k" }

local Attribute = {}
Attribute.__index = Attribute
Attribute.type = "Attribute"

export type Attribute<T> = setmetatable<{
	attribute: string,
	check: gt.Type?,
	defaultValue: T?,
	_cache: { [Instance]: T },
	_signals: { [Instance]: RBXScriptSignal },
	_updated: { [Instance]: true },
	_observers: { [Instance]: RBXScriptConnection? },
	_observerCallbacks: { [Instance]: () -> ()? },
	_changeListeners: { [Instance]: { [(value: T, attribute: any) -> ()?]: true } },
	_fetchListeners: { [Instance]: { [(value: T, attribute: any) -> ()?]: true } },
}, typeof(Attribute)>

local function resolveInstance(resolvable: ResolvableInstance): Instance
	if type(resolvable) == "userdata" then
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
				print("UPDATING", attribute)
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

local function new(attribute: any, check: any, defaultValue: any): Attribute<any>
	return setmetatable({
		attribute = attribute,
		check = check,
		defaultValue = defaultValue,
		_cache = setmetatable({}, WEAK_KEYS_MT) :: any,
		_signals = setmetatable({}, WEAK_KEYS_MT) :: any,
		_updated = setmetatable({}, WEAK_KEYS_MT) :: any,
		_observers = setmetatable({}, WEAK_KEYS_MT) :: any,
		_observerCallbacks = setmetatable({}, WEAK_KEYS_MT) :: any,
		_changeListeners = setmetatable({}, WEAK_KEYS_MT) :: any,
		_fetchListeners = setmetatable({}, WEAK_KEYS_MT) :: any,
	}, Attribute)
end

Attribute.new = new :: (
	& (<T>(attribute: string, check: T, defaultValue: T) -> Attribute<T>)
	& (<T>(attribute: string, check: T) -> Attribute<T?>)
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

function Attribute.set<T>(self: Attribute<T>, instance: ResolvableInstance, value: T): T
	-- TODO: run updates
	local resolved = resolveInstance(instance)
	resolved:SetAttribute(self.attribute, value)
	return value
end

function Attribute.assert<T>(self: Attribute<T?>, instance: ResolvableInstance, message: string?): T
	local value = Attribute.get(self :: any, instance)
	assert(value ~= nil, message or `Instance {instance:GetFullName()} is missing attribute {self.attribute}!`)
	return value
end

-- TODO: don't repeat yourself

-- (lazily evaluated)
function Attribute.onFetch<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	local resolved = resolveInstance(instance)
	local listeners = self._fetchListeners[resolved] :: {}
	if not listeners then
		listeners = setmetatable({}, WEAK_KEYS_MT) :: any
		self._fetchListeners[resolved] = listeners
	end

	listeners[listener] = true

	local function disconnect()
		listeners[listener] = nil
		if next(listeners) == nil then
			self._fetchListeners[resolved] = nil
		end
	end

	return disconnect
end

-- (eagerly evaluated)
function Attribute.onChange<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	local resolved = resolveInstance(instance)
	local listeners = self._changeListeners[resolved] :: {}
	if not listeners then
		listeners = setmetatable({}, WEAK_KEYS_MT) :: any
		self._changeListeners[resolved] = listeners
	end

	listeners[listener] = true

	local function disconnect()
		listeners[listener] = nil
		if next(listeners) == nil then
			self._changeListeners[resolved] = nil
		end
	end

	observeChanges(self, self.attribute, resolved)

	return disconnect
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

return Attribute
