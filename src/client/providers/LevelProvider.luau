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
	task.wait(1)
	local kitLife = Life.new()
	local kitLevel = Level.new(kitLife, "Kit", Workspace:WaitForChild("Kit") :: any)
	kitLevel:start()
end

function LevelProvider.onFinish() end

export type LevelProvider = typeof(LevelProvider)
return prvd(LevelProvider)
