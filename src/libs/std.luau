local Attribute = require("./Attribute")
local LevelState = require("./LevelState")
local Mechanic = require("./Mechanic")
local MechanicTypes = require("./MechanicTypes")
local gt = require("./gt")

export type Mechanic<Self = MechanicTypes.BaseMechanicImplementation> = MechanicTypes.Mechanic<Self>
export type MechanicImplementation<Self = MechanicTypes.BaseMechanicImplementation, Instance = Instance> =
	MechanicTypes.MechanicImplementation<Self, Instance>

export type Level = MechanicTypes.Level

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
	Mechanic = Mechanic.new,
	Attribute = Attribute.new,
	LevelState = LevelState.new,

	gt = gt,
}
