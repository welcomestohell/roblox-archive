local useMonorepo = require("@libs/useMonorepo")
local fs = require("@std/fs")
local json = require("@std/json")
local path = require("@std/path")

local monorepo = useMonorepo()

local luaurcAliases = { pkgs = "roblox_packages" }
for _, member in ipairs(monorepo) do
	luaurcAliases[member.dirName] = path.format(member.dirPath)
end

fs.writeStringToFile(".luaurc", json.serialize({ aliases = luaurcAliases }, true))
