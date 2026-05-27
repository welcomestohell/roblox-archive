local Players = game:GetService("Players")

local accountStore = require("@self/accountStore")
local objects = require("@libs/objects")
local prvd = require("@core/shared/prvdmwrong/prvdmwrong")
local store = require("@self/store")

type Account = accountStore.Account

local AccountProvider = {}
export type AccountProvider = typeof(AccountProvider)
AccountProvider.priority = math.huge

function AccountProvider.setGold(self: AccountProvider, player: Player, operator: "add" | "subtract", amount: number)
	return store:updateImmutable(player, function(account: Account)
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
	return store:updateImmutable(player, function(account: Account)
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

function AccountProvider.onStart(self: AccountProvider)
	Players.PlayerAdded:Connect(function(player)
		store:load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		store:unload(player)
		accountStore.removeAccount(player.Name)
	end)

	game:BindToClose(function()
		store:closeAsync()
	end)
end

return prvd(AccountProvider)
