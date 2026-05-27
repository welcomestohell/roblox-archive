local accountStore = require("./accountStore")
local gt = require("@pkgs/gt")

type Account = accountStore.Account

local accountSchema: Account = gt.table({
	gold = gt.number(),
	completedTowers = gt.number(),
})

return gt.build(accountSchema)
