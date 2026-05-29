local luau = require("@std/luau")

local cache: any

local function useRepositoryConfig(): typeof(require("@libs/../../.config"))
	cache = cache or luau.loadModule(".config.luau")
	return cache
end

return useRepositoryConfig
