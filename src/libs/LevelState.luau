local Level = require("./Level")
local tables = require("@libs/tables")

local LevelState = {}
LevelState.__index = LevelState
LevelState.type = "LevelState" :: "LevelState"

export type LevelState<T> = setmetatable<{
	_default: T,
	_values: { [Level.Level]: T },
	_cleanup: { [Level.Level]: () -> () },
}, typeof(LevelState)>

local function initializeLevel(state: LevelState<any>, level: Level.Level)
	if state._cleanup[level] then
		return
	end

	state._cleanup[level] = level.life:add(function()
		state._cleanup[level] = nil
		state._values[level] = nil
	end)
end

function LevelState.new<T>(default: T): LevelState<T>
	return setmetatable({
		_default = default,
		_values = tables.weak("k"),
		_cleanup = tables.weak("k"),
	}, LevelState)
end

function LevelState.get<T>(self: LevelState<T>, level: Level.Level): T
	return self._values[level]
end

function LevelState.getOrDefault<T>(self: LevelState<T>, level: Level.Level): T
	local value = self._values[level]
	if value == nil then
		return self._default
	end
	return value
end

function LevelState.getOrSet<T>(self: LevelState<T>, level: Level.Level, fallback: T): T
	local value = self._values[level]
	if value == nil then
		self._values[level] = fallback
		return fallback
	end
	return value
end

function LevelState.getOrInitialize<T>(self: LevelState<T>, level: Level.Level, initialize: (level: Level.Level) -> T): T
	local value = self._values[level]
	if value == nil then
		value = initialize(level)
		self._values[level] = value
		return value
	end
	return value
end

function LevelState.set<T>(self: LevelState<T>, level: Level.Level, value: T): T
	initializeLevel(self, level)
	self._values[level] = value
	return value
end

function LevelState.take<T>(self: LevelState<T>, level: Level.Level): T?
	local old = self._values[level]
	local cleanup = self._cleanup[level]
	if cleanup then
		cleanup()
	end
	return old
end

return table.freeze(LevelState)
