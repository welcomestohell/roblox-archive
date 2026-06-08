local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Level = require "@libs/core/Level"
local Life = require "@libs/memory/Life"
local Promise = require "@roblox_packages/Promise"
local logger = require "@core/shared/logger"
-- local audios = require "@core"
local character = require "@libs/character"
local net = require "@kit/client/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"
local sounds = require "@libs/sounds"

local KitClientProvider = {}
export type KitClientProvider = typeof(KitClientProvider)

function KitClientProvider.constructor(self: KitClientProvider)
	self.life = Life.new()
	Promise.all({
		Level.baseScripts:collectInstancesAsync(ReplicatedStorage.TowerScripts.Core:GetDescendants()),
		Level.baseScripts:collectInstancesAsync(ReplicatedStorage.TowerScripts.Kit:GetDescendants()),
	}):await()
end

function KitClientProvider.onStart(self: KitClientProvider)
	if not game:IsLoaded() then
		logger:Debug "Waiting for game to finish loading"
		game.Loaded:Wait()
	end

	-- sounds.useAssets(audios :: any)
	logger:Debug("Loaded audios from assets:", sounds.assetPaths)
	task.spawn(sounds.preloadAssets)

	local tower = net.getTower.invoke():expect()

	local existingMechanics = tower:FindFirstChild "Mechanic"
	if existingMechanics then
		logger:Debug "Removing existing mechanics"
		existingMechanics:Destroy()
	end

	local mechanics = net.loadMechanics.invoke():expect()
	mechanics:Clone().Parent = tower
	mechanics:Destroy()

	local levelResult = Level.new(self.life, tower.Name, tower)
	levelResult:match({
		Ok = function(level: Level.Level)
			logger:Debug "Starting kit..."
			character.getCharacter():PivotTo(level.instance.Spawn.CFrame)
			level:start()
			logger:Info "Kit has started!"
		end,
		Err = function(e)
			if e.id == "invalidInstance" then
				logger:Error("Invalid kit instance client-side:", e.cause:formatErr())
			else
				logger:Error("Unknown error while initializing kit:", e)
			end
		end,
	} :: any)
end

function KitClientProvider.onFinish(self: KitClientProvider)
	self.life:destroy()
end

return prvd(KitClientProvider)
