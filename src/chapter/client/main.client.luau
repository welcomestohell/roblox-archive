local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ReplicatedStorage, "Core", "Client", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Core", "Shared", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Flagship", "Client", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Flagship", "Shared", "providers")
local root = framework.root:start()
game.Close:Once(function()
	root:finish()
end)
