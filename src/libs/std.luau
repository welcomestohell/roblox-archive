local Attribute = require("./Attribute")
local Level = require("./Level")
local LevelState = require("./LevelState")
local gt = require("./gt")
local mechanics = require("./mechanics")

export type Mechanic<Instance = any> = mechanics.Mechanic<Instance>
export type MechanicImplementation<Self = any, Instance = any> = mechanics.MechanicImplementation<Self, Instance>
export type BaseMechanicImplementation<Instance = any> = mechanics.BaseMechanicImplementation<Instance>

export type Level = Level.Level

export type LevelState<T> = LevelState.LevelState<T>
export type Attribute<T> = Attribute.Attribute<T>

--[=[
	@class std
	@tag lib

	Welcome To Hell comes with a variety of things in it's libraries. However,
	if you had to manually import every single thing that you used, it would be
	very verbose. But importing a lot of things that a script never uses isn’t
	good either. A balance needs to be struck.

	The standard library is kept as small as possible to focus on things
	that are most frequently used for tower scripting.
]=]
return table.freeze {
	Mechanic = mechanics.Mechanic,
	Attribute = Attribute.new,
	LevelState = LevelState.new,

	gt = gt,
}
