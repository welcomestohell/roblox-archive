local Boba = require "@lib/vendor/boba"
local literal = require "@lib/utils/literal"
local path = require "@std/path"

export type Project = {
	name: string,
	instanceName: string,
	configuration: ProjectConfiguration,
	configurationPath: path.path,
	dirPath: path.path,
}

local AbstractPlaceConfiguration = Boba.Struct {
	kind = Boba.Literal(literal "abstract-place").T,
	placeDependencies = Boba.String:Array():Optional().T,
}

local PlaceConfiguration = Boba.Struct {
	kind = Boba.Literal(literal "place").T,
	placeId = Boba.String.T,
	placeDependencies = Boba.String:Array():Optional().T,
}

local LibraryConfiguration = Boba.Struct {
	kind = Boba.Literal(literal "library").T,
}

local ProjectConfiguration = AbstractPlaceConfiguration:Or(PlaceConfiguration):Or(LibraryConfiguration)

export type AbstractPlaceConfiguration = typeof(AbstractPlaceConfiguration.T)
export type PlaceConfiguration = typeof(PlaceConfiguration.T)
export type LibraryConfiguration = typeof(LibraryConfiguration.T)
export type ProjectConfiguration = typeof(ProjectConfiguration.T)

return table.freeze {
	AbstractPlaceConfiguration = AbstractPlaceConfiguration,
	PlaceConfiguration = PlaceConfiguration,
	LibraryConfiguration = LibraryConfiguration,
	ProjectConfiguration = ProjectConfiguration,
}
