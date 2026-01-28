local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local prvd = require "@shared/prvdmwrong/prvdmwrong"

local root = prvd.root()
	:useModules(
		ServerScriptService:WaitForChild("Internal"):WaitForChild("Server"):WaitForChild("providers"):GetDescendants()
	)
	:useModules(
		ReplicatedStorage:WaitForChild("Internal"):WaitForChild("Shared"):WaitForChild("providers"):GetDescendants()
	)
	:useProvider(require "@shared/prvdmwrong/rbx-lifecycles" :: any)
	:start()

game:BindToClose(function()
	root:finish()
end)
