local cli = require "@libs/cli"
local fs = require "@std/fs"
local initializeOutput = require "@libs/build/initializeOutput"
local initializeRojo = require "@libs/build/initializeRojo"
local log = require "@libs/log"
local path = require "@std/path"
local process = require "@std/process"
local run = require "@libs/run"
local shouldFileBeTranspiled = require "@libs/build/shouldFileBeTranspiled"
local task = require "@std/task"
local transpile = require "@libs/build/transpile"
local types = require "./libs/types"
local useMonorepo = require "@libs/useMonorepo"
local usePlaceDependencies = require "@libs/usePlaceDependencies"
local useRepositoryConfig = require "@libs/useRepositoryConfig"
local useSourcemapIndices = require "@libs/useSourcemapIndices"
local useSourcemapProcessor = require "@libs/useSourcemapProcessor"

local args = cli.parser { description = "Launches and observes the given place for development" }
args:add("place", "positional", { help = "Name of place to build", required = true })
args:add("open", "flag", { help = "Whether to open the place in Roblox Studio" })
args:parse { ... }

local repository = useRepositoryConfig()
local outputPath = repository.wth.paths.output
local outputProjectPath = repository.wth.paths.outputProject
local sourcemapPath = repository.wth.paths.sourcemap
local sourcemapProjectPath = repository.wth.paths.sourcemapProject

local monorepo = useMonorepo()
local member = monorepo[args:get "place"] or log.throw(`Unknown place named {args:get "place"}`)
local memberPlace = member.place or log.throw(`Member {member.dirName} is not a place (does it have a place field?)`)
local placeId = memberPlace.placeId or log.throw(`{memberPlace.title} is an abstract place (does it have a placeId?)`)

local memberDependencies = usePlaceDependencies(monorepo, member)
local rojoMembers = table.clone(memberDependencies)
table.insert(rojoMembers, 1, member)

local state: types.BuildContext = {
	monorepo = monorepo,
	repository = repository,

	member = member,
	memberPlace = memberPlace,
	memberDependencies = memberDependencies,
	rojoMembers = rojoMembers,

	outputPath = outputPath,
	outputProjectPath = outputProjectPath,
	sourcemapPath = sourcemapPath,
	sourcemapProjectPath = sourcemapProjectPath,

	sourcemapIndices = {},
}

initializeOutput(state)
initializeRojo(state)

local sourcemapProcessor = useSourcemapProcessor(sourcemapPath)
local sourcemapWatcher = fs.watch(sourcemapPath)

local sourcemapArgs = { "sourcemap", "--absolute", "--output", sourcemapPath, sourcemapProjectPath }
run("rojo", sourcemapArgs)
table.insert(sourcemapArgs, 2, "--watch")
task.spawn(run, "rojo", sourcemapArgs)

task.spawn(function()
	while task.wait(0.05) do
		for absolutePath, fileWatcher in sourcemapProcessor.fileWatchers do
			if fileWatcher:next() then
				sourcemapProcessor.filesChanged[absolutePath] = true
			end
		end

		-- print(string.rep("\n", 67))

		if sourcemapWatcher:next() then
			state.sourcemapIndices = useSourcemapIndices(sourcemapPath)
			sourcemapProcessor.onChanged(state.sourcemapIndices)
		end

		local processedFiles = {}

		for fileChanged in sourcemapProcessor.filesChanged do
			if
				not processedFiles[fileChanged]
				and fs.exists(fileChanged)
				and shouldFileBeTranspiled(monorepo, fileChanged)
			then
				fs.writeStringToFile(
					path.join(outputPath, path.relative(process.cwd(), fileChanged)),
					transpile(state, fileChanged, fs.readFileToString(fileChanged))
				)
			end
			processedFiles[fileChanged] = true
		end

		for fileRemoved in sourcemapProcessor.filesRemoved do
			if
				not processedFiles[fileRemoved]
				and fs.exists(fileRemoved)
				and shouldFileBeTranspiled(monorepo, fileRemoved)
			then
				fs.remove(path.join(outputPath, path.relative(process.cwd(), fileRemoved)))
			end
			processedFiles[fileRemoved] = true
		end

		for fileAdded in sourcemapProcessor.filesAdded do
			if
				not processedFiles[fileAdded]
				and fs.exists(fileAdded)
				and shouldFileBeTranspiled(monorepo, fileAdded)
			then
				local outputFilepath = path.join(outputPath, path.relative(process.cwd(), fileAdded))
				local fileContents = fs.readFileToString(fileAdded)
				local dirs = path.dirname(outputFilepath)
				if not fs.exists(dirs) then
					fs.createDirectory(dirs, { makeParents = true })
				end
				fs.writeStringToFile(outputFilepath, transpile(state, fileAdded, fileContents))
			end
			processedFiles[fileAdded] = true
		end

		table.clear(sourcemapProcessor.filesChanged)
		table.clear(sourcemapProcessor.filesRemoved)
		table.clear(sourcemapProcessor.filesAdded)
		table.clear(processedFiles)
	end
end)

task.spawn(run, "rojo", { "serve" })

if args:has "open" then
	run("lute", { "ropen", placeId })
end
