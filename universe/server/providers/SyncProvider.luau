local AccountStore = require "@universe/server/providers/accounts/AccountStore"
local Charm = require "@roblox_packages/Charm"
local CharmSync = require "@roblox_packages/CharmSync"
local prvd = require "@prvdmwrong/prvdmwrong"

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
