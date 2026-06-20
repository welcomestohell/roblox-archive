local AccountStore = require "@universe/server/providers/accounts/AccountStore"
local Charm = require "@pkgs/Charm"
local CharmSync = require "@pkgs/CharmSync"
local prvd = require "@pkgs/prvd"

local SyncProvider = {}
export type SyncProvider = typeof(SyncProvider)
SyncProvider.priority = math.huge - 1

function SyncProvider.onPlayerAdded(self: SyncProvider, player: Player)
	CharmSync.server.addSignalsToClient(player, {
		[`account-{player.Name}`] = Charm.computed(function()
			return AccountStore.getAccount(player.Name)
		end),
	})
end

return prvd(SyncProvider)
