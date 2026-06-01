local Players = game:GetService "Players"

local AccountStore = require "@universe/server/providers/accounts/AccountStore"
local Charm = require "@roblox_packages/Charm"
local CharmSync = require "@roblox_packages/CharmSync"
local net = require "@universe/server/generated/net"
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

function SyncProvider.onPlayerRemoving(self: SyncProvider, player: Player)
	CharmSync.server.removeClient(player)
end

function SyncProvider.onStart(self: SyncProvider)
	CharmSync.server.connect(function(player, patches)
		net.patch.fire(player, patches)
	end)

	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)

	for _, player in Players:GetPlayers() do
		self:onPlayerAdded(player)
	end
end

return prvd(SyncProvider)
