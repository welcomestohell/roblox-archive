local Charm = require "@pkgs/Charm"

return table.freeze {
	preloadAssetIds = Charm.atom<<{ string }?>>(),
}
