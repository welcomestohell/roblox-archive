local prvd = require "@prvdmwrong/prvdmwrong"

local TowerProvider = {}
export type TowerProvider = typeof(TowerProvider)

function TowerProvider.onStart(self: TowerProvider) end

return prvd(TowerProvider)
