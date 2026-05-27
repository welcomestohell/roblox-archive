--!nocheck
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Lyra = require("@pkgs/Lyra")

local accountStore = require("./accountStore")
local schema = require("./schema")

type Account = accountStore.Account

local accountTemplate: Account = {
	gold = 0,
	completedTowers = 0,
}

local function onAccountChanged(key: string, account: Account)
	local player = Players:GetPlayerByUserId(tonumber(key) :: number)
	if player then
		accountStore.setAccount(player.Name, account)
	end
end

return Lyra.createPlayerStore({
	name = "PlayerData",
	template = accountTemplate,
	schema = function(value)
		local ok, reason = schema:matches(value)
		return ok, tostring(reason)
	end,
	changedCallbacks = { onAccountChanged },
	memoryStoreService = if RunService:IsStudio() then Lyra.MockMemoryStoreService.new() else nil,
	dataStoreService = if RunService:IsStudio() then Lyra.MockDataStoreService.new() else nil,
})
