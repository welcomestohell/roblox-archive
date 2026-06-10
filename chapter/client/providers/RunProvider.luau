local prvd = require "@roblox_packages/prvd"

local RunProvider = {}
export type RunProvider = typeof(RunProvider)

function RunProvider.onStart(self: RunProvider) end

return prvd(RunProvider)
