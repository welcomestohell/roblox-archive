local prvd = require "@pkgs/prvd"

local RunProvider = {}
export type RunProvider = typeof(RunProvider)

function RunProvider.onStart(self: RunProvider) end

return prvd(RunProvider)
