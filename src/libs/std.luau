local Attribute = require("./Attribute")
local Level = require("./Level")
local LevelState = require("./LevelState")
local Mechanic = require("./Mechanic")
local gt = require("./gt")

export type Mechanic<Self = any> = Mechanic.Mechanic<Self>
export type MechanicImplementation = Mechanic.MechanicImplementation
export type MechanicImplementationMetadata = Mechanic.MechanicImplementationMetadata

export type Level = Level.Level

export type LevelState<T> = LevelState.LevelState<T>
export type Attribute<T> = Attribute.Attribute<T>

--[=[
	@class std
	@tag Library

	Welcome To Hell comes with a variety of things in it's libraries. However,
	if you had to manually import every single thing that you used, it would be
	very verbose. But importing a lot of things that a script never uses isn’t
	good either. A balance needs to be struck.

	The standard library is kept as small as possible to focus on things
	that are most frequently used for tower scripting.
]=]
return table.freeze {
	Mechanic = Mechanic.new,
	Attribute = Attribute.new,
	LevelState = LevelState.new,

	gt = gt,
	isA = gt.isA,
}
