local prvd = require "@roblox_packages/prvd"

local TowerProvider = {}
export type TowerProvider = typeof(TowerProvider)

function TowerProvider.onStart(self: TowerProvider) end

return prvd(TowerProvider)
