local prvd = require "@prvdmwrong/prvdmwrong"

local RunProvider = {}
export type RunProvider = typeof(RunProvider)

function RunProvider.onStart(self: RunProvider) end

return prvd(RunProvider)
