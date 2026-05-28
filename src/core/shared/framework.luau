local prvd = require("@core/shared/prvdmwrong/prvdmwrong")
local rbxLifecycles = require("@core/shared/prvdmwrong/rbx-lifecycles")

local root = prvd.root():useProvider(rbxLifecycles)

local function useModulesFromPath(parentRoot: Instance, ...: string)
	for index = 1, select("#", ...) do
		parentRoot = parentRoot:WaitForChild(select(index, ...) :: string)
	end
	root:useModules(parentRoot:GetDescendants())
end

return table.freeze({
	root = root,
	useModulesFromPath = useModulesFromPath,
})
