local log = require("@libs/log")
local task = require("@std/task")
local cli = require("@libs/cli")
local copyInto = require("@libs/copyInto")
local emptyDir = require("@libs/emptyDir")
local rojo = require("@libs/rojo")
local run = require("@libs/run")
local sourcemapIndices = require("@libs/sourcemapIndices")
local useMonorepo = require("@libs/useMonorepo")
local usePlaceDependencies = require("@libs/usePlaceDependencies")
local useRepositoryConfig = require("@libs/useRepositoryConfig")
local fs = require("@std/fs")
local json = require("@std/json")
local types = require("./libs/types")
local crypto = require("@lute/crypto")
local path = require("@std/path")
local process = require("@std/process")
local tableext = require("@std/tableext")

type FileHash = { modified: number, size: number, hash: string }

local args = cli.parser({ description = "Launches and observes the given place for development" })
args:add("place", "positional", { help = "Name of place to build", required = true })
args:parse({ ... })

local repository = useRepositoryConfig()
local outputPath = repository.wth.paths.output
local outputProjectPath = repository.wth.paths.outputProject
local sourcemapPath = repository.wth.paths.sourcemap
local sourcemapProjectPath = repository.wth.paths.sourcemapProject

local monorepo = useMonorepo()
local member = monorepo[args:get("place")] or log.throw(`Unknown place named {args:get("place")}`)
local place = member.place or log.throw(`Member {member.dirName} is not a place (does it have a place field?)`)
local placeId = place.placeId or log.throw(`{place.title} is an abstract place (does it have a placeId?)`)

local dependencies = usePlaceDependencies(monorepo, member)
local rojoDependencies = table.clone(dependencies)
table.insert(rojoDependencies, 1, member)

-- This is going to sound really stupid but we use rojo's sourcemap for added/
-- removed files, and fs.watch for file changes
-- I know it is stupid but it's pretty darn reliable
local oldSourcemap: types.Sourcemap = {}
local filesAdded, filesChanged, filesRemoved = {}, {}, {}
local fileWatchers: { [string]: typeof(fs.watch("")) } = {}

local function processSourcemap()
	local newSourcemap = sourcemapIndices(json.deserialize(fs.readFileToString(sourcemapPath)) :: sourcemapIndices.Node)

	for absolutePath in newSourcemap do
		if not oldSourcemap[absolutePath] and not filesAdded[absolutePath] then
			filesAdded[absolutePath] = true

			local watcher = fs.watch(absolutePath)
			fileWatchers[absolutePath] = watcher
		end
	end

	for absolutePath, hash in oldSourcemap do
		if not newSourcemap[absolutePath] and not filesRemoved[absolutePath] then
			filesRemoved[absolutePath] = true

			local watcher = fileWatchers[absolutePath]
			if watcher then
				watcher:close()
				fileWatchers[absolutePath] = nil
			end
		end
	end

	oldSourcemap = newSourcemap
end

local function findMemberFromPath(filepath: path.Pathlike): types.MonorepoMember
	local firstPart = path.parse(filepath).parts[1]
	for _, member in ipairs(monorepo) do
		if member.dirName == firstPart then
			return member
		end
	end
	return error("unreachable")
end

do
	pcall(emptyDir, outputPath)
	for _, dependency in rojoDependencies do
		if dependency.place or (dependency.placeMixin and dependency.placeMixin.transpile) then
			copyInto(dependency.dirPath, dependency.outputDirPath)
		end
	end

	fs.writeStringToFile(outputProjectPath, json.serialize(rojo.projectFromMembers("output", rojoDependencies), true))
	fs.writeStringToFile(
		sourcemapProjectPath,
		json.serialize(rojo.projectFromMembers("source", rojoDependencies), true)
	)

	local sourcemapArgs = { "sourcemap", "--absolute", "--output", sourcemapPath, sourcemapProjectPath }
	run("rojo", sourcemapArgs)

	processSourcemap()

	table.insert(sourcemapArgs, 2, "--watch")
	task.spawn(run, "rojo", sourcemapArgs)

	local watcher = fs.watch(sourcemapPath)
	task.spawn(function()
		while task.wait(0.1) do
			for absolutePath, fileWatcher in fileWatchers do
				if fileWatcher:next() then
					filesChanged[absolutePath] = true
				end
			end

			if watcher:next() then
				processSourcemap()
			end

			for fileAdded in filesAdded do
				local filepath = path.relative(process.cwd(), fileAdded)
				local member = findMemberFromPath(filepath)

				if not member.placeMixin or member.placeMixin.transpile then
					fs.copy(fileAdded, path.join(outputPath, path.relative(process.cwd(), fileAdded)))
				end
			end

			for fileRemoved in filesRemoved do
				local filepath = path.relative(process.cwd(), fileRemoved)
				local member = findMemberFromPath(filepath)

				if not member.placeMixin or member.placeMixin.transpile then
					fs.remove(path.join(outputPath, path.relative(process.cwd(), fileRemoved)))
				end
			end

			table.clear(filesAdded)
			table.clear(filesChanged)
			table.clear(filesRemoved)
		end
	end)
end
