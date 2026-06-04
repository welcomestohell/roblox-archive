local Charm = require "@roblox_packages/Charm"

return table.freeze {
	preloadAssetIds = Charm.atom<<{ string }?>>(),
}
