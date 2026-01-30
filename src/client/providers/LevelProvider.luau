local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Workspace = game:GetService "Workspace"

local lib = require "@lib"
local prvd = require "@shared/prvdmwrong/prvdmwrong"

local LevelProvider = {}
export type DebugProvider = typeof(LevelProvider)

function LevelProvider.constructor()
	lib.collectScripts(
		ReplicatedStorage:WaitForChild("Scripts"):WaitForChild "Core",
		lib.baseScripts,
		lib.baseMechanicImplementations
	)
end

function LevelProvider.onStart()
	task.wait(1)
	local kitLife = lib.Life()
	local kitLevel = lib.Level(kitLife, "Kit", Workspace:WaitForChild "Kit" :: any)
	print "STARTING"
	kitLevel:bootstrap()
end

function LevelProvider.onFinish() end

export type LevelProvider = typeof(LevelProvider)
return prvd(LevelProvider)
