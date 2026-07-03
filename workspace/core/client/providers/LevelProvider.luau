local ContentProvider = game:GetService "ContentProvider"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local collectAssets = require "@core/shared/assets/collectAssets"
local flattenAssetIds = require "@core/shared/assets/flattenAssetIds"
local logger = require "@core/shared/logger"
local character = require "@libs/character"
local arrays = require "@libs/primitives/arrays"
local Level = require "@libs/core/Level"
local startLevel = require "@libs/core/startLevel"
local Life = require "@libs/memory/Life"
local threadpool = require "@libs/threadpool"
local prvd = require "@pkgs/prvd"
local Charm = require "@pkgs/Charm"

local LevelProvider = { activeLevels = Charm.atom<<{ Level.Level }>> {}, priority = -1 }
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

	for _, ids in arrays.mapped(collectAssets(), flattenAssetIds) do
		threadpool.spawn(ContentProvider.PreloadAsync, ContentProvider, ids)
	end

	local levelResult = Level.new(self.life, instance.Name, instance)
	if levelResult:isOk() then
		local level = levelResult:unwrap<<Level.Level>>()
		character.getCharacter():PivotTo(level.instance.Spawn.CFrame)
		startLevel(level)

		self.activeLevels(function(activeLevels: { Level.Level })
			-- LUAU FIXME: eugh
			table.insert(activeLevels :: { any }, level)
			return activeLevels
		end)

		level.life:add(function()
			self.activeLevels(function(activeLevels: { Level.Level })
				arrays.findAndRemove<<Level.Level>>(activeLevels, level)
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
