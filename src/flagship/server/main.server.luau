local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ServerScriptService, "Core", "Server", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Core", "Shared", "providers")
framework.useModulesFromPath(ServerScriptService, "Flagship", "Server", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Flagship", "Shared", "providers")
local root = framework.root:start()
game:BindToClose(function()
	root:finish()
end)
