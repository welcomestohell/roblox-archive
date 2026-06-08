local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Workspace = game:GetService "Workspace"

local Level = require "@libs/core/Level"
local Life = require "@libs/memory/Life"
local character = require "@libs/character"
local logger = require "@core/shared/logger"
local net = require "@chapter/client/generated/net"
local prvd = require "@prvdmwrong/prvdmwrong"

local LevelProvider = {}
export type LevelProvider = typeof(LevelProvider)

function LevelProvider.constructor(self: LevelProvider)
	self.life = Life.new()
	Level.baseScripts:collectInstancesAsync(ReplicatedStorage.TowerScripts.Core:GetDescendants()):await()
end

function LevelProvider.onStart(self: LevelProvider)
	if not game:IsLoaded() then
		logger:Debug "Waiting for game to load"
		game.Loaded:Wait()
	end

	local existingMechanics = Workspace:FindFirstChild "Mechanics"
	if existingMechanics then
		logger:Debug "Removing existing mechanics"
		existingMechanics:Destroy()
	end

	local mechanics = net.loadMechanics.invoke():expect()
	mechanics:Clone().Parent = Workspace
	mechanics:Destroy()

	local levelResult = Level.new(self.life, "Chapter", Workspace)
	levelResult:match({
		Ok = function(level: Level.Level)
			logger:Debug "Starting chapter..."
			character.getCharacter():PivotTo(level.instance.SpawnCharacter.CFrame)
			level:start()
			logger:Info "Chapter has started!"
		end,
		Err = function(e)
			if e.id == "invalidInstance" then
				logger:Error("Invalid chapter instance client-side:", e.cause:formatErr())
			else
				logger:Error("Unknown error while initializing kit:", e)
			end
		end,
	} :: any)
end

return prvd(LevelProvider)
