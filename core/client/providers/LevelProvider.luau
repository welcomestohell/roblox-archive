const ReplicatedStorage = game:GetService "ReplicatedStorage"

const logger = require "@core/shared/logger"
const character = require "@libs/character"
const tables = require "@libs/collections/tables"
const Level = require "@libs/core/Level"
const Life = require "@libs/memory/Life"
const prvd = require "@roblox_packages/prvd"
const Charm = require "@roblox_packages/Charm"

local LevelProvider = { activeLevels = Charm.atom<<{ Level }>> {}, priority = -1 }
export type LevelProvider = typeof(LevelProvider)

function LevelProvider.onInit(self: typeof(LevelProvider))
	self.life = Life.new()
	Level.baseScripts
		:collectInstancesAsync(ReplicatedStorage:WaitForChild("TowerScripts"):WaitForChild("Core"):GetDescendants())
		:await()
end

function LevelProvider.tryLoadLevel(self: typeof(LevelProvider), instance: Instance): Level.Level?
	if not game:IsLoaded() then
		logger:Debug "Waiting for game to load"
		game.Loaded:Wait()
	end

	local levelResult = Level.new(self.life, instance.Name, instance)
	if levelResult:isOk() then
		local level = levelResult:unwrap<<Level.Level>>()
		character.getCharacter():PivotTo(level.instance.Spawn.CFrame)
		level:start()

		self.activeLevels(function(activeLevels)
			table.insert(activeLevels, level)
			return activeLevels
		end)

		level.life:add(function()
			self.activeLevels(function(activeLevels)
				tables.findAndRemove(activeLevels, level)
				return activeLevels
			end)
		end)

		return level
	end

	local err: any = levelResult:unwrapErr()
	if err.id == "invalidInstance" then
		logger:Error("Invalid level instance client-side:", err.cause:formatErr())
	else
		logger:Error("Unknown error while initializing level:", err)
	end

	return nil
end

return prvd(LevelProvider)
