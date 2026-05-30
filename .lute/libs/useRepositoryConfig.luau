local luau = require("@std/luau")
local types = require("./types")

local cache: any

local function useRepositoryConfig(): types.RepositoryConfig
	cache = cache or luau.loadModule(".config.luau")
	return cache
end

return useRepositoryConfig
