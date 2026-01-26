local identity = require "@lib/utils/identity"
local types = require "./types"

return table.freeze {
	abstractPlace = identity :: (types.AbstractPlaceConfiguration) -> types.AbstractPlaceConfiguration,
	place = identity :: (types.PlaceConfiguration) -> types.PlaceConfiguration,
	library = identity :: (types.LibraryConfiguration) -> types.LibraryConfiguration,
	project = identity :: (types.ProjectConfiguration) -> types.ProjectConfiguration,
}
