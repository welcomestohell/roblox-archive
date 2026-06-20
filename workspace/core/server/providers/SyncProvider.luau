-- Note: Other providers are expected to add their own signals in onStart,]

local CharmSync = require "@pkgs/CharmSync"
local net = require "@core/server/generated/net"
local prvd = require "@pkgs/prvd"

local SyncProvider = {}
export type SyncProvider = typeof(SyncProvider)
SyncProvider.priority = -1

function SyncProvider.onPlayerRemoving(self: SyncProvider, player: Player)
	CharmSync.server.removeClient(player)
end

function SyncProvider.onStart(self: SyncProvider)
	CharmSync.server.connect(function(player, patches)
		net.patch.fire(player, patches)
	end)
end

return prvd(SyncProvider)
