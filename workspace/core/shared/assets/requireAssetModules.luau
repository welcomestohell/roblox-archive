local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require "@core/shared/assets/types"

local function requireAssetModules(): { [string]: types.Assets }
	local result = {}
	for _, module in ReplicatedStorage:WaitForChild("Assets"):GetChildren() do
		if module:IsA "ModuleScript" then result[module.Name] = (require)(module) end
	end
	return result
end

return requireAssetModules
