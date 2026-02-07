local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Level = require("@libs/Level")
local Life = require("@libs/Life")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local LevelProvider = {}
export type DebugProvider = typeof(LevelProvider)

function LevelProvider.constructor()
	Level.collectScripts(
		ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("Core"),
		Level.baseScripts,
		Level.baseMechanicImplementations
	)
end

function LevelProvider.onStart()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	local kitLife = Life.new()
	local levelResult = Level.new(kitLife, "Kit", Workspace:WaitForChild("Kit") :: any)
	levelResult:match({
		Err = function(e: Level.NewLevelError)
			print("Failed to start kit:", e)
			return nil
		end,
		Ok = function(level: Level.Level)
			print("starting")
			level:start()
			print("started")
			return nil
		end,
	} :: any)
end

function LevelProvider.onFinish() end

export type LevelProvider = typeof(LevelProvider)
return prvd(LevelProvider)
