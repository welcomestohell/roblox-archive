--!nonstrict

local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local Lyra = require "@roblox_packages/Lyra"

local AccountSchema = require "./AccountSchema"
local AccountStore = require "./AccountStore"

type Account = AccountStore.Account

local accountTemplate: Account = {
	gold = 0,
	completedTowers = 0,
}

local function onAccountChanged(key: string, account: Account)
	local player = Players:GetPlayerByUserId(tonumber(key) :: number)
	if player then AccountStore.setAccount(player.Name, account) end
end

return Lyra.createPlayerStore {
	name = "PlayerData",
	template = accountTemplate,
	schema = function(value)
		local ok, reason = AccountSchema:matches(value)
		return ok, tostring(reason)
	end,
	changedCallbacks = { onAccountChanged },
	useMock = RunService:IsStudio(),
}
