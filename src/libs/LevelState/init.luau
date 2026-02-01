local MechanicTypes = require("./MechanicTypes")
local tables = require("@libs/tables")

local LevelState = {}
LevelState.__index = LevelState
LevelState.type = "LevelState" :: "LevelState"

export type LevelState<T> = setmetatable<{
	_default: T?,
	_values: { [MechanicTypes.Level]: T? },
	_cleanup: { [MechanicTypes.Level]: () -> () },
}, typeof(LevelState)>

local function new(default: any)
	return setmetatable({
		_default = default,
		_values = tables.weak("k"),
		_cleanup = tables.weak("k"),
	}, LevelState)
end

local function initializeLevel(state: LevelState<any>, level: MechanicTypes.Level)
	if state._cleanup[level] then
		return
	end

	state._cleanup[level] = level.life:add(function()
		state._cleanup[level] = nil
		state._values[level] = nil
	end)
end

LevelState.new = new :: (<T>() -> LevelState<T?>) & (<T>(default: T) -> LevelState<T>)

function LevelState.get<T>(self: LevelState<T>, level: MechanicTypes.Level): T
	return self._values[level]
end

function LevelState.getOrDefault<T>(self: LevelState<T | nil>, level: MechanicTypes.Level): T
	local value = self._values[level]
	if value == nil then
		return self._default
	end
	return value
end

function LevelState.getOrSet<T>(self: LevelState<T>, level: MechanicTypes.Level, fallback: T): T
	local value = self._values[level]
	if value == nil then
		self._values[level] = fallback
		return fallback
	end
	return value
end

function LevelState.set<T>(self: LevelState<T>, level: MechanicTypes.Level, value: T): T
	initializeLevel(self, level)
	self._values[level] = value
	return value
end

function LevelState.take<T>(self: LevelState<T>, level: MechanicTypes.Level): T?
	local old = self._values[level]
	level.life:remove(self._cleanup[level])
	self._cleanup[level] = nil
	return old
end

return table.freeze(LevelState)
