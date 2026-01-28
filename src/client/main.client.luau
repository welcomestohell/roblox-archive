local ReplicatedStorage = game:GetService "ReplicatedStorage"

local prvd = require "@shared/prvdmwrong/prvdmwrong"

local root = prvd.root()
	:useModules(
		ReplicatedStorage:WaitForChild("Internal"):WaitForChild("Client"):WaitForChild("providers"):GetDescendants()
	)
	:useModules(
		ReplicatedStorage:WaitForChild("Internal"):WaitForChild("Shared"):WaitForChild("providers"):GetDescendants()
	)
	:useProvider(require "@shared/prvdmwrong/rbx-lifecycles" :: any)
	:start()

game.Close:Once(function()
	root:finish()
end)
