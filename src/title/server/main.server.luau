local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "Core", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "Core", "providers")
framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "Universe", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "Universe", "providers")
framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "Title", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "Title", "providers")

local root = framework.root:start()
game:BindToClose(function()
	root:finish()
end)
