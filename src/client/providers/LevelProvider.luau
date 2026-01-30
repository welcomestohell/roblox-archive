local prvd = require "@shared/prvdmwrong/prvdmwrong"

local LevelProvider = {}
export type DebugProvider = typeof(LevelProvider)

function LevelProvider.onStart(self: LevelProvider) end

function LevelProvider.onFinish() end

export type LevelProvider = typeof(LevelProvider)
return prvd(LevelProvider)
