local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "Core", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "Core", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "Universe", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "Universe", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "Title", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "Title", "providers")

local root = framework.root:start()
game.Close:Once(function()
	root:finish()
end)
