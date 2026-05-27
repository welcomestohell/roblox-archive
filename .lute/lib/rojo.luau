local deepClone = require("./deepClone")
local json = require("@std/json")
local path = require("@std/path")
local places = require("./places")
local pp = require("@batteries/pp")
local repositoryConfig = require("@lib/utils/repositoryConfig")

export type RojoMappings = { [keyof<typeof(repositoryConfig().wth.rojo.mappings)>]: { RojoMappingSegment } }

export type RojoMappingSegment = {
	name: string,
	className: string?,
}

export type RojoPath = string | { optional: string }

export type RojoNode = {
	["$className"]: string?,
	["$path"]: RojoPath?,
	[string]: RojoNode,
}

local function insertMapping(
	tree: RojoNode,
	segments: { RojoMappingSegment },
	sourceName: string?,
	sourcePath: path.Pathlike?
)
	local current = tree

	for _, segment in segments do
		if not current[segment.name] then
			current[segment.name] = {}
		end

		current = current[segment.name]

		if segment.className then
			current["$className"] = segment.className
		end
	end

	if sourceName and sourcePath then
		if not current[sourceName] then
			current[sourceName] = {}
		end

		current = current[sourceName]

		current["$path"] = {
			optional = path.format(sourcePath),
		}
	end
end

local function projectFromPlace(kind: "source" | "output", places: { places.Place }): json.Object
	local firstPlace = places[1] or error("Must specify atleast 1 place")

	local repository = repositoryConfig()
	local mappings = repository.wth.rojo.mappings :: RojoMappings
	local tree = if kind == "source" then repository.wth.rojo.sourceTree else repository.wth.rojo.outputTree :: RojoNode
	tree = deepClone(tree)

	for dir, segments in mappings do
		for _, place in places do
			local mappingDirs = if kind == "source" then place.mappingSourceDirs else place.mappingOutputDirs
			local dirPath = mappingDirs[dir]

			local sourceName, sourcePath
			if dirPath then
				sourceName, sourcePath = place.name, dirPath
			end

			insertMapping(tree, segments, sourceName, sourcePath)
		end
	end

	return {
		name = firstPlace.name,
		emitLegacyScripts = false,
		tree = tree,
	}
end

return table.freeze({
	projectFromPlace = projectFromPlace,
})
