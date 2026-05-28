local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "core", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "core", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "universe", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "universe", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "title", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "title", "providers")

local root = framework.root:start()
game.Close:Once(function()
	root:finish()
end)
