local AccountStore = require("./AccountStore")
local gt = require("@roblox_packages/gt")

type Account = AccountStore.Account

local AccountSchema: Account = gt.table({
	gold = gt.number(),
	completedTowers = gt.number(),
})

return gt.build(AccountSchema)
