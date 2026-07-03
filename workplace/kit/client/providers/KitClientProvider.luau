local ReplicatedStorage = game:GetService "ReplicatedStorage"

local LevelProvider = require "@core/client/providers/LevelProvider"
local Level = require "@libs/core/Level"
local logger = require "@core/shared/logger"
local net = require "@kit/client/generated/net"
local prvd = require "@pkgs/prvd"

local KitClientProvider = {}
export type KitClientProvider = typeof(KitClientProvider)

function KitClientProvider.onInit(self: KitClientProvider)
	Level.baseScripts
		:collectInstancesAsync(ReplicatedStorage:WaitForChild("TowerScripts"):WaitForChild("Kit"):GetDescendants())
		:await()
end

function KitClientProvider.onStart(self: KitClientProvider)
	local tower = net.getTower.invoke():expect()
	local existingMechanics = tower:FindFirstChild "Mechanics"
	if existingMechanics then
		logger:Debug "Removing existing mechanics"
		existingMechanics:Destroy()
	end

	local mechanics = net.loadMechanics.invoke():expect()
	mechanics:Clone().Parent = tower
	mechanics:Destroy()

	self.level = LevelProvider:tryLoadLevel(tower)
end

function KitClientProvider.onStop(self: KitClientProvider)
	if self.level then self.level.life:destroy() end
end

return prvd(KitClientProvider)
