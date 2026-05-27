local fs = require("@std/fs")
local path = require("@std/path")
local repositoryConfig = require("@lib/utils/repositoryConfig")
local richterm = require("@batteries/richterm")
local tableext = require("@std/tableext")
local toml = require("@batteries/toml")

export type ConfigMappings = { [keyof<typeof(repositoryConfig().wth.rojo.mappings)>]: { Mapping } }

export type Mapping = {
	name: string,
	className: string?,
}

export type PlaceConfiguration = {
	placeId: string?,
	dependencies: { string }?,
}

export type Place = {
	name: string,
	placeId: string?,
	dependencies: { string }?,

	dirName: string,
	sourcePath: path.Pathlike,
	outputPath: path.Pathlike,
	configPath: path.Pathlike,

	mappingSourceDirs: { [keyof<typeof(repositoryConfig().wth.rojo.mappings)>]: path.Pathlike? },
	mappingOutputDirs: { [keyof<typeof(repositoryConfig().wth.rojo.mappings)>]: path.Pathlike? },
}

local initialized = false
local allPlaces = {}
local dirToPlace = {}

local function initialize()
	if initialized then
		return
	end

	initialized = true

	local repository = repositoryConfig()
	local sourceDir = repository.wth.dirs.source
	local outputDir = repository.wth.dirs.output
	local rojoMappings = repository.wth.rojo.mappings

	for _, entry in fs.listDirectory(sourceDir) do
		if entry.type ~= "dir" then
			continue
		end

		local sourcePath = path.join(sourceDir, entry.name)
		local configPath = path.join(sourcePath, "place.toml")

		if not fs.exists(configPath) then
			continue
		end

		local config = toml.deserialize(fs.readFileToString(configPath)) :: PlaceConfiguration
		local outputPath = path.join(outputDir, entry.name)

		local place: Place = {
			name = entry.name,
			placeId = config.placeId,
			dependencies = config.dependencies or {},

			dirName = entry.name,
			sourcePath = sourcePath,
			outputPath = outputPath,
			configPath = configPath,

			mappingSourceDirs = {},
			mappingOutputDirs = {},
		}

		for key in rojoMappings :: { [keyof<typeof(rojoMappings)>]: { Mapping } } do
			local sourceMapping = path.join(sourcePath, key)
			if fs.exists(sourceMapping) then
				place.mappingSourceDirs[key] = sourceMapping
				place.mappingOutputDirs[key] = outputPath
			end
		end

		table.insert(allPlaces, place)
		dirToPlace[place.dirName] = place
	end
end

local function fromDir(dir: unknown): Place
	assert(initialized, "Places not yet fetched, call places.initialize() first")
	return dirToPlace[dir]
		or error(
			`Unknown place named {dir}. Valid places are: {table.concat(
				tableext.map(allPlaces, function(place: Place)
					return place.name
				end),
				", "
			)}`
		)
end

local function resolveDependencies(place: Place): { Place }
	local dependencies = {}
	if place.dependencies then
		for _, dependency in place.dependencies do
			table.insert(dependencies, fromDir(dependency))
		end
	end
	return dependencies
end

return table.freeze({
	allPlaces = allPlaces,
	dirToPlace = dirToPlace,

	initialize = initialize,
	fromDir = fromDir,
	resolveDependencies = resolveDependencies,
})
