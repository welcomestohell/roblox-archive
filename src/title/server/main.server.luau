local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "core", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "core", "providers")
framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "universe", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "universe", "providers")
framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "title", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "title", "providers")

local root = framework.root:start()
game:BindToClose(function()
	root:finish()
end)
