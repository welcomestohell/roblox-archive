local Charm = require "@roblox_packages/Charm"
local objects = require "@libs/objects"

export type Account = {
	read gold: number,
	read completedTowers: number,
}

type Accounts = {
	[string]: Account,
}

local getAccounts, setAccounts = Charm.signal({} :: Accounts)

local function getAccount(username: string): Account?
	return getAccounts()[username]
end

local function setAccount(username: string, account: Account)
	setAccounts(function(state: Accounts)
		return objects.set(state, username, account)
	end)
end

local function removeAccount(username: string)
	setAccounts(function(state: Accounts)
		return objects.delete(state, username)
	end)
end

return {
	getAccounts = getAccounts,
	getAccount = getAccount,
	setAccount = setAccount,
	removeAccount = removeAccount,
}
