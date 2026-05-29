local log = require("@libs/log")
local run = require("@libs/run")
local sourcemapIndices = require("@libs/sourcemapIndices")
local types = require("@libs/types")
local fs = require("@std/fs")
local json = require("@std/json")
local task = require("@std/task")

local function processSourcemap(state: types.BuildState)
	state.sourcemap = sourcemapIndices(
		json.deserialize(fs.readFileToString(state.repository.wth.paths.sourcemapProject)) :: types.SourcemapNode
	)
end

local function initializeSourcemap(state: types.BuildState)
	local sourcemapPath = state.repository.wth.paths.sourcemap
	local sourcemapProjectPath = state.repository.wth.paths.sourcemapProject

	local sourcemapArgs = { "sourcemap", "--absolute", "--output", sourcemapPath, sourcemapProjectPath }
	run("rojo", sourcemapArgs)
	processSourcemap(state)

	table.insert(sourcemapArgs, 2, "--watch")
	task.spawn(run, "rojo", sourcemapArgs)

	local watcher = fs.watch(sourcemapPath)
	task.spawn(function(watcher: typeof(watcher), state: types.BuildState)
		while task.wait(0.01) do
			if watcher:next() then
				processSourcemap(state)
				log.info("an iq too high?", state.sourcemap)
			end
		end
	end, watcher, state)
end

return initializeSourcemap
