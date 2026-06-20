const Level = require "@libs/core/Level"

const LevelTable = { type = "LevelTable" }
LevelTable.__index = LevelTable

export type LevelTable<K, V> = setmetatable<{ [Level.Level]: { [K]: V } }, typeof(LevelTable)>

function LevelTable.new<K, V>(): LevelTable<K, V>
	return setmetatable({}, LevelTable)
end

function LevelTable.get<K, V>(self: LevelTable<K, V>, level: Level.Level): { [K]: V }
	if self[level] then return self[level] end
	self[level] = {}
	level.life:add(function()
		self[level] = nil
	end)
	return self[level]
end

function LevelTable.index<K, V>(self: LevelTable<K, V>, level: Level.Level, key: K): V
	return self:get(level)[key]
end

function LevelTable.insert<V>(self: LevelTable<number, V>, level: Level.Level, position: number, value: V): V
	table.insert(self:get(level), position, value)
	return value
end

function LevelTable.push<V>(self: LevelTable<number, V>, level: Level.Level, value: V): V
	table.insert(self:get(level), value)
	return value
end

return table.freeze(LevelTable)
