local Charm = require "@pkgs/Charm"

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
		table.clone(state)
		state[username] = account
		return state
	end)
end

local function removeAccount(username: string)
	setAccounts(function(state: Accounts)
		table.clone(state)
		state[username] = nil
		return state
	end)
end

return {
	getAccounts = getAccounts,
	getAccount = getAccount,
	setAccount = setAccount,
	removeAccount = removeAccount,
}
