local rojo = require("@libs/rojo")
local types = require("@libs/types")
local fs = require("@std/fs")
local json = require("@std/json")

local function initializeRojo(state: types.BuildState)
	local outputProject = state.repository.wth.paths.outputProject
	local sourcemapProject = state.repository.wth.paths.sourcemapProject

	local rojoMembers = table.clone(state.dependencies)
	table.insert(rojoMembers, 1, state.member)

	fs.writeStringToFile(outputProject, json.serialize(rojo.projectFromMembers("output", rojoMembers), true))
	fs.writeStringToFile(sourcemapProject, json.serialize(rojo.projectFromMembers("source", rojoMembers), true))
end

return initializeRojo
