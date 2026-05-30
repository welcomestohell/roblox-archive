local types = require("@libs/types")
local buildRojoProject = require("./buildRojoProject")
local fs = require("@std/fs")
local json = require("@std/json")

local function initializeRojo(state: types.BuildState)
	fs.writeStringToFile(state.outputProjectPath, json.serialize(buildRojoProject("output", state.rojoMembers), true))
	fs.writeStringToFile(
		state.sourcemapProjectPath,
		json.serialize(buildRojoProject("source", state.rojoMembers), true)
	)
end

return initializeRojo
