local AccountStore = require "./AccountStore"
local PlayerStore = require "./PlayerStore"
local objects = require "@libs/collections/objects"
local prvd = require "@roblox_packages/prvd"

type Account = AccountStore.Account

local AccountProvider = {}
export type AccountProvider = typeof(AccountProvider)

function AccountProvider.setGold(self: AccountProvider, player: Player, operator: "add" | "subtract", amount: number)
	return PlayerStore:updateImmutable(player, function(account: Account)
		if operator == "add" then
			return objects.join(account, {
				gold = account.gold + amount,
				completedTowers = account.completedTowers,
			})
		else
			return objects.join(account, {
				gold = account.gold - amount,
				completedTowers = account.completedTowers,
			})
		end
	end)
end

function AccountProvider.setCompletedTowers(
	self: AccountProvider,
	player: Player,
	operator: "add" | "subtract",
	amount: number
)
	return PlayerStore:updateImmutable(player, function(account: Account)
		if operator == "add" then
			return objects.join(account, {
				gold = account.gold,
				completedTowers = account.completedTowers + amount,
			})
		else
			return objects.join(account, {
				gold = account.gold,
				completedTowers = account.completedTowers - amount,
			})
		end
	end)
end

-- function AccountProvider.onPlayerAdded(self: AccountProvider, player: Player)
-- 	self.log:debug("Loading account for", player.Name)
--  PlayerStore:load(player)
-- end

-- function AccountProvider.onPlayerRemoving(self: AccountProvider, player: Player)
-- 	self.log:debug("Unloading account for", player.Name)
-- 	PlayerStore:unload(player)
-- 	AccountStore.removeAccount(player.Name)
-- end

function AccountProvider.onStop(self: AccountProvider)
	PlayerStore:closeAsync()
end

return prvd(AccountProvider)
