local Life = require "@self/memory/Life"
local Mechanic = require "@self/core/Mechanic"
local destroy = require "@self/memory/destroy"
local gt = require "@pkgs/gt"
local types = require "@self/types"

export type Level = types.Level
export type LevelInstance = types.LevelInstance

export type Mechanic<Implementation> = types.Mechanic<Implementation>
export type MechanicImplementation<Implementation> = types.MechanicImplementation<Implementation>
export type BaseMechanicImplementation<Implementation> = types.BaseMechanicImplementation<Implementation>

local lib = table.freeze {
	Mechanic = Mechanic.new,
	isMechanicImplementation = Mechanic.isMechanicImplementation,
	isMechanic = Mechanic.isMechanic,
	isMechanicImplementationOf = Mechanic.isMechanicImplementationOf,
	isMechanicOf = Mechanic.isMechanicOf,

	Life = Life.new,
	destroy = destroy,

	gt = gt,
	isA = gt.isA,
}

return lib
